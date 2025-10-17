@echo off
setlocal

:: --- Настройки ---
set "DEFAULT_IP=94.131.119.22"
set "HOSTS_TMP=%TEMP%\hosts_list_%RANDOM%.txt"
set "PS1=%TEMP%\add_hosts_%RANDOM%.ps1"

:: Список хостов (по одному на строку) — удобно править тут
> "%HOSTS_TMP%" (
  echo chatgpt.com
  echo ab.chatgpt.com
  echo auth.openai.com
  echo auth0.openai.com
  echo platform.openai.com
  echo cdn.oaistatic.com
  echo files.oaiusercontent.com
  echo cdn.auth0.com
  echo tcr9i.chat.openai.com
  echo webrtc.chatgpt.com
  echo gemini.google.com
  echo aistudio.google.com
  echo generativelanguage.googleapis.com
  echo alkalimakersuite-pa.clients6.google.com
  echo copilot.microsoft.com
  echo sydney.bing.com
  echo edgeservices.bing.com
  echo claude.ai
  echo aitestkitchen.withgoogle.com
  echo aisandbox-pa.googleapis.com
  echo x.ai
  echo grok.com
  echo accounts.x.ai
  echo labs.google
  echo anthropic.com
  echo api.anthropic.com
  echo api.openai.com
  echo netflix.com
  echo spotify.com
)

:: --- Проверка прав (elevation) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Требуются права администратора. Перезапуск с повышением...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '%*'"
  del /f /q "%HOSTS_TMP%" >nul 2>&1
  exit /b
)

:: --- Получаем IP ---
if "%~1" neq "" (
  set "IP=%~1"
) else (
  set /p "input_ip=Будет использован стандартный IP: %DEFAULT_IP%  Нажмите Enter для подтверждения или введите свой IP и нажмите Enter: "
  if defined input_ip ( set "IP=%input_ip%" ) else ( set "IP=%DEFAULT_IP%" )
)

:: --- Создаём временный PowerShell-скрипт ---
(
  echo Param([string]$IP,[string]$HostsFile)
  echo $hostsPath = Join-Path $env:WinDir "System32\drivers\etc\hosts"
  echo if (-not (Test-Path $hostsPath)) { Write-Host "hosts not found: $hostsPath"; exit 1 }
  echo
  echo # Validate IPv4
  echo $octets = $IP -split '\.'
  echo if ($octets.Length -ne 4 -or ($octets | Where-Object { -not ($_ -match ''^\d+$'') -or [int]$_ -lt 0 -or [int]$_ -gt 255 })) { Write-Host "Неверный IP: $IP"; exit 1 }
  echo
  echo $lines = Get-Content -Path $hostsPath -ErrorAction Stop
  echo $hosts = Get-Content -Path $HostsFile -ErrorAction Stop
  echo $newEntries = @()
  echo foreach ($host in $hosts) {
  echo   $h = $host.Trim()
  echo   if ($h -eq '') { continue }
  echo   $patternIPLine = '^\s*' + [regex]::Escape($IP) + '\s+.*\b' + [regex]::Escape($h) + '\b'
  echo   if ($lines -match $patternIPLine) { Write-Host "Пропускаю $h — уже присутствует с IP $IP"; continue }
  echo   $lines = $lines | Where-Object { $_ -match '^\s*#' -or ($_ -notmatch ('\b' + [regex]::Escape($h) + '\b')) }
  echo   $newEntries += ($IP + "`t" + $h)
  echo   Write-Host "Запланирована новая запись: $IP $h"
  echo }
  echo if ($newEntries.Count -gt 0) {
  echo   $lines += ''
  echo   $lines += $newEntries
  echo   $lines | Set-Content -Path $hostsPath -Encoding ASCII
  echo   Write-Host "Добавлены новые записи в $hostsPath"
  echo } else {
  echo   Write-Host "Новых записей не требуется."
  echo }
) > "%PS1%"

:: --- Запуск PowerShell-скрипта ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" "%IP%" "%HOSTS_TMP%"
set "RC=%ERRORLEVEL%"

:: --- Чистка временных файлов ---
del /f /q "%PS1%" >nul 2>&1
del /f /q "%HOSTS_TMP%" >nul 2>&1

endlocal
exit /b %RC%
