$ErrorActionPreference = 'Stop'
$envPath = Join-Path (Get-Location).Path '.env'
if (-not (Test-Path $envPath)) {
  Write-Host "ERROR: .env not found in $((Get-Location).Path)" -ForegroundColor Red
  Write-Host 'Run this script from your supoclip-main folder.'
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

Write-Host "`n=== SupoClip Buffer setup check ===" -ForegroundColor Cyan
$bufferKey = [string]$settings['BUFFER_API_KEY']
$mediaBase = ([string]$settings['SOCIAL_PUBLIC_MEDIA_BASE_URL']).TrimEnd('/')
$notifTo = [string]$settings['POST_PUBLISH_NOTIFICATION_EMAIL']
$smtpHost = [string]$settings['SMTP_HOST']
$smtpUser = [string]$settings['SMTP_USERNAME']
$smtpPass = [string]$settings['SMTP_PASSWORD']
$smtpFrom = [string]$settings['SMTP_FROM_EMAIL']

if ([string]::IsNullOrWhiteSpace($bufferKey) -or $bufferKey -match '^YOUR_|^<|^paste_your') {
  Write-Host '[FAIL] BUFFER_API_KEY is missing or still a placeholder.' -ForegroundColor Red
} else {
  Write-Host '[OK] Buffer API key is present in .env (value hidden).' -ForegroundColor Green
  try {
    $body = @{ query = 'query SupoClipBufferHealthCheck { account { id name organizations { id name } } }' } | ConvertTo-Json -Depth 8 -Compress
    $headers = @{ Authorization = "Bearer $bufferKey"; Accept = 'application/json' }
    $response = Invoke-RestMethod -Uri 'https://api.buffer.com' -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 25
    if ($response.errors -and $response.errors.Count -gt 0) {
      $codes = @($response.errors | ForEach-Object { if ($_.extensions.code) { [string]$_.extensions.code } else { 'GraphQL error' } }) -join ', '
      $msgs = @($response.errors | ForEach-Object { [string]$_.message }) -join '; '
      Write-Host "[FAIL] Buffer rejected the query: $codes" -ForegroundColor Red
      Write-Host "Details: $msgs"
    } elseif ($response.data.account.id) {
      $orgs = @($response.data.account.organizations).Count
      Write-Host "[OK] Buffer API authentication works. Organization count: $orgs" -ForegroundColor Green
    } else {
      Write-Host '[WARN] Buffer responded, but no account object was returned. Check API access and GraphQL response.' -ForegroundColor Yellow
      Write-Host ($response | ConvertTo-Json -Depth 5)
    }
  } catch {
    $status = $null
    try { $status = [int]$_.Exception.Response.StatusCode } catch {}
    if ($status -eq 401) {
      Write-Host '[FAIL] Buffer returned HTTP 401: API key is invalid/revoked or was copied incorrectly.' -ForegroundColor Red
    } elseif ($status -eq 403) {
      Write-Host '[FAIL] Buffer returned HTTP 403: key accepted by server but request/account access is forbidden, or the API returned a permissions error.' -ForegroundColor Red
    } elseif ($status) {
      Write-Host "[FAIL] Buffer API returned HTTP $status." -ForegroundColor Red
      Write-Host $_.Exception.Message
    } else {
      Write-Host '[FAIL] Could not complete Buffer API test (network, TLS, DNS, timeout, or response issue).' -ForegroundColor Red
      Write-Host $_.Exception.Message
    }
  }
}

if ([string]::IsNullOrWhiteSpace($mediaBase)) {
  Write-Host '[FAIL] SOCIAL_PUBLIC_MEDIA_BASE_URL is missing.' -ForegroundColor Red
} elseif ($mediaBase -notmatch '^https://') {
  Write-Host '[FAIL] SOCIAL_PUBLIC_MEDIA_BASE_URL must start with https://.' -ForegroundColor Red
} else {
  Write-Host "[OK] Public media base is HTTPS: $mediaBase" -ForegroundColor Green
  try {
    $r = Invoke-WebRequest -Uri $mediaBase -Method Get -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 5
    Write-Host "[INFO] Tunnel root responded HTTP $([int]$r.StatusCode). This only checks the hostname; the actual signed media URL must be tested with a real clip." -ForegroundColor Cyan
  } catch {
    $status = $null
    try { $status = [int]$_.Exception.Response.StatusCode } catch {}
    if ($status) {
      Write-Host "[WARN] Tunnel hostname responded HTTP $status. A root-page status alone doesn't prove the signed media route works; investigate if this is 403/502/530." -ForegroundColor Yellow
    } else {
      Write-Host '[FAIL] Could not reach public tunnel. Confirm cloudflared is still running and the URL has not changed.' -ForegroundColor Red
      Write-Host $_.Exception.Message
    }
  }
}

$bufferFiles = (Test-Path 'backend/src/services/buffer_service.py') -and (Test-Path 'frontend/src/components/buffer-batch-scheduler.tsx')
if ($bufferFiles) {
  Write-Host '[OK] Buffer integration source files are present in this project folder.' -ForegroundColor Green
} else {
  Write-Host '[WARN] Buffer integration source files not found. Extract the Buffer automation patch into this folder first.' -ForegroundColor Yellow
}

if ($notifTo -and $smtpHost -and $smtpFrom -and ((-not $smtpUser -and -not $smtpPass) -or ($smtpUser -and $smtpPass))) {
  Write-Host '[OK] Email settings look populated; this script did not send a test email.' -ForegroundColor Green
} else {
  Write-Host '[INFO] Email notifications are not fully configured yet. This won't stop a Buffer API key test, but the publish-confirmation email requires recipient + SMTP host/from and consistent username/password.' -ForegroundColor Yellow
}

Write-Host "`nDone. No API key or SMTP password was printed by this script." -ForegroundColor Cyan
