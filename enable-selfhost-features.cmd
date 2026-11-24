@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\enable-selfhost-features.ps1"
if errorlevel 1 (
  echo.
  echo The self-host feature setup did not finish successfully.
  pause
  exit /b 1
)
echo.
pause
