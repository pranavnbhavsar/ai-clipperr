$ErrorActionPreference = 'Stop'
$envPath = Join-Path (Get-Location).Path '.env'
if (-not (Test-Path -LiteralPath $envPath)) {
  Write-Host "FAIL: .env not found. Run this script from your supoclip-main folder." -ForegroundColor Red
  exit 1
}

$settings = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
  $trimmed = $line.Trim()
  if (-not $trimmed -or $trimmed.StartsWith('#') -or $trimmed -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { continue }
  $name = $matches[1]
  $value = $matches[2].Trim()
  if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
    $value = $value.Substring(1, $value.Length - 2)
  }
  $settings[$name] = $value
}

$script:Failures = 0
function Result([string]$name, [bool]$ok, [string]$detail) {
  if ($ok) { Write-Host "[OK]   $name - $detail" -ForegroundColor Green }
  else { Write-Host "[FAIL] $name - $detail" -ForegroundColor Red; $script:Failures++ }
}
function Warn([string]$name, [string]$detail) { Write-Host "[WARN] $name - $detail" -ForegroundColor Yellow }
function HasValue([string]$name) {
  $v = [string]$settings[$name]
  return (-not [string]::IsNullOrWhiteSpace($v)) -and ($v -notmatch '^(YOUR_|<|paste_your|change_me)')
}
function HttpStatus($err) {
  try { return [int]$err.Exception.Response.StatusCode } catch { }
  try { return [int]$err.Exception.Response.StatusCode.value__ } catch { }
  return 0
}
function Check-Get([string]$name, [string]$uri, [hashtable]$headers, [string]$description) {
  try {
    $r = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -TimeoutSec 20
    Result $name $true $description
    return $r
  } catch {
    $status = HttpStatus $_
    if ($status) { Result $name $false "HTTP $status. Check the key, provider access, or API restrictions." }
    else { Result $name $false "Network/TLS/DNS/timeout issue. $($_.Exception.Message)" }
    return $null
  }
}

Write-Host "`n=== SupoClip configuration and API smoke test ===" -ForegroundColor Cyan
Write-Host "Project folder: $((Get-Location).Path)"
Write-Host 'Secrets are not printed. This script does not publish a post or send an email.' -ForegroundColor Cyan

# Docker/service health endpoints
foreach ($item in @(
  @{Name='Backend health'; Uri='http://localhost:8000/health'},
  @{Name='Database health'; Uri='http://localhost:8000/health/db'},
  @{Name='Redis health'; Uri='http://localhost:8000/health/redis'},
  @{Name='Worker health'; Uri='http://localhost:8000/health/worker'},
  @{Name='Frontend'; Uri='http://localhost:3107'}
)) {
  try {
    $r = Invoke-WebRequest -Uri $item.Uri -UseBasicParsing -TimeoutSec 12
    Result $item.Name ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) "HTTP $($r.StatusCode)"
  } catch {
    $status = HttpStatus $_
    if ($status) { Result $item.Name $false "HTTP $status" }
    else { Result $item.Name $false 'Cannot connect. Check docker compose ps and logs.' }
  }
}

# Confirm source patch files exist in the current folder
$patchFiles = (Test-Path 'backend/src/services/buffer_service.py') -and (Test-Path 'frontend/src/components/buffer-batch-scheduler.tsx') -and (Test-Path 'backend/src/services/post_publish_notification.py')
if ($patchFiles) { Result 'Buffer integration files' $true 'Source files found in this folder' }
else { Result 'Buffer integration files' $false 'Patch files missing; extract the Buffer patch into this project folder first' }

# Buffer GraphQL account check
if (HasValue 'BUFFER_API_KEY') {
  try {
    $body = @{ query = 'query SupoClipSmokeTest { account { organizations { id } } }' } | ConvertTo-Json -Depth 6 -Compress
    $headers = @{ Authorization = "Bearer $([string]$settings['BUFFER_API_KEY'])"; Accept = 'application/json' }
    $r = Invoke-RestMethod -Uri 'https://api.buffer.com' -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 25
    if ($r.errors -and $r.errors.Count -gt 0) {
      $msgs = @($r.errors | ForEach-Object { [string]$_.message }) -join '; '
      Result 'Buffer API key' $false "GraphQL rejected request: $msgs"
    } elseif ($null -ne $r.data.account) {
      $orgCount = @($r.data.account.organizations).Count
      Result 'Buffer API key' $true "Authenticated; organization objects returned: $orgCount"
    } else { Result 'Buffer API key' $false 'No account returned. Check the current Buffer API key and API response.' }
  } catch {
    $status = HttpStatus $_
    if ($status) { Result 'Buffer API key' $false "HTTP $status. Key may be invalid/revoked, or access was denied." }
    else { Result 'Buffer API key' $false "Network/TLS/timeout issue. $($_.Exception.Message)" }
  }
} else { Warn 'Buffer API key' 'BUFFER_API_KEY is blank or still a placeholder' }

# OpenAI models endpoint
if (HasValue 'OPENAI_API_KEY') {
  $null = Check-Get 'OpenAI API key' 'https://api.openai.com/v1/models' @{ Authorization = "Bearer $([string]$settings['OPENAI_API_KEY'])" } 'Models endpoint authenticated'
} else { Warn 'OpenAI API key' 'OPENAI_API_KEY is not configured' }

# OpenRouter models endpoint
if (HasValue 'OPENROUTER_API_KEY') {
  $null = Check-Get 'OpenRouter API key' 'https://openrouter.ai/api/v1/models' @{ Authorization = "Bearer $([string]$settings['OPENROUTER_API_KEY'])"; 'HTTP-Referer'='http://localhost:3107'; 'X-Title'='SupoClip smoke test' } 'Models endpoint authenticated'
} else { Warn 'OpenRouter API key' 'OPENROUTER_API_KEY is not configured' }

# Gemini model listing, use header to avoid putting key in URL/logs
if (HasValue 'GOOGLE_API_KEY') {
  $null = Check-Get 'Google Gemini API key' 'https://generativelanguage.googleapis.com/v1beta/models' @{ 'x-goog-api-key' = [string]$settings['GOOGLE_API_KEY'] } 'Models endpoint authenticated'
} else { Warn 'Google Gemini API key' 'GOOGLE_API_KEY is not configured' }

# AssemblyAI list existing transcripts (read-only)
if (HasValue 'ASSEMBLY_AI_API_KEY') {
  $null = Check-Get 'AssemblyAI API key' 'https://api.assemblyai.com/v2/transcript?limit=1' @{ Authorization = [string]$settings['ASSEMBLY_AI_API_KEY'] } 'Transcript-list endpoint authenticated'
} else { Warn 'AssemblyAI API key' 'ASSEMBLY_AI_API_KEY is not configured; required only if TRANSCRIPTION_PROVIDER=assemblyai' }

# Ollama on Windows and model availability
$ollama = $null
try {
  $ollama = Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 10
  $modelNames = @($ollama.models | ForEach-Object { [string]$_.name })
  Result 'Ollama on Windows' $true ("Server reachable; models installed: " + ($modelNames -join ', '))
} catch { Result 'Ollama on Windows' $false 'Cannot reach http://localhost:11434/api/tags. Start Ollama if local models are intended.' }

# Test Ollama reachability from inside backend container using Python's standard library
try {
  $py = "import urllib.request; r=urllib.request.urlopen('http://host.docker.internal:11434/api/tags',timeout=5); print(r.status)"
  $out = & docker compose exec -T backend python -c $py 2>&1
  if ($LASTEXITCODE -eq 0 -and (($out -join ' ') -match '200')) { Result 'Ollama reachable from backend container' $true 'Docker can reach Windows Ollama endpoint' }
  else { Warn 'Ollama reachable from backend container' 'Backend could not reach host.docker.internal:11434. Needed only if LLM uses local Ollama. Check OLLAMA_BASE_URL and Ollama network access.' }
} catch { Warn 'Ollama reachable from backend container' 'Could not run the container connectivity check. This is required only if using Ollama as the selected LLM.' }

# LLM configured provider summary
$llm = [string]$settings['LLM']
if ($llm -match '^([^:]+):') {
  $provider = $matches[1]
  Write-Host "[INFO] Selected LLM provider in .env: $provider (setting: $llm)" -ForegroundColor Cyan
  if ($provider -eq 'ollama' -and $modelNames -and -not ($modelNames -contains ($llm -replace '^ollama:', ''))) {
    Warn 'Selected Ollama model' 'The model name in LLM did not exactly match a model name from Ollama /api/tags. Check spelling/tag.'
  }
} else { Warn 'Selected LLM provider' 'LLM is blank or has an unexpected format' }

# Public media URL reachability (root check only, not proof a tokenized MP4 can be fetched)
$mediaBase = ([string]$settings['SOCIAL_PUBLIC_MEDIA_BASE_URL']).TrimEnd('/')
if (-not $mediaBase) { Warn 'Public media URL' 'SOCIAL_PUBLIC_MEDIA_BASE_URL is blank; Buffer video publishing requires public HTTPS media access' }
elseif ($mediaBase -notmatch '^https://') { Result 'Public media URL' $false 'Must start with https://' }
else {
  try {
    $r = Invoke-WebRequest -Uri $mediaBase -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 5
    Result 'Public media URL' ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) "Tunnel hostname responded HTTP $($r.StatusCode); a real media token URL still needs testing"
  } catch {
    $status = HttpStatus $_
    if ($status) { Warn 'Public media URL' "Root returned HTTP $status. A root response alone does not validate the per-post media URL." }
    else { Result 'Public media URL' $false 'Cannot reach the tunnel. Verify cloudflared is running and the URL has not changed.' }
  }
}

# SMTP TCP only; doesn't authenticate or send mail
$smtpHost = [string]$settings['SMTP_HOST']
$smtpPort = 0
[void][int]::TryParse([string]$settings['SMTP_PORT'], [ref]$smtpPort)
if ($smtpHost -and $smtpPort -gt 0) {
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $async = $tcp.BeginConnect($smtpHost, $smtpPort, $null, $null)
    $ok = $async.AsyncWaitHandle.WaitOne(5000, $false) -and $tcp.Connected
    if ($tcp) { $tcp.Close() }
    Result 'SMTP server network access' $ok (if ($ok) { "$smtpHost`:$smtpPort reachable (network only; SMTP credentials not tested)" } else { "$smtpHost`:$smtpPort not reachable" })
  } catch { Result 'SMTP server network access' $false "Could not connect to $smtpHost`:$smtpPort" }
} else { Warn 'SMTP configuration' 'SMTP_HOST/SMTP_PORT not configured yet. Use the app Send test email button after configuring SMTP.' }

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($script:Failures -eq 0) { Write-Host 'No hard failures detected by these smoke checks.' -ForegroundColor Green }
else { Write-Host "$script:Failures check(s) failed. Review the [FAIL] lines above." -ForegroundColor Red }
Write-Host 'Limits: API list checks verify authentication, not model generation/credits. SMTP check verifies TCP only. The tunnel root check does not prove Buffer can fetch a real video. No post was published and no email was sent.' -ForegroundColor Cyan
Write-Host 'Next: run docker compose logs --tail=100 backend worker if anything fails, and use the UI Send test email + one private/test Buffer post for end-to-end validation.' -ForegroundColor Cyan
