@echo off
setlocal enabledelayedexpansion

:: --- 1. АВТО-ЗАПУСК ОТ ИМЕНИ АДМИНИСТРАТОРА ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting Admin rights...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:: --- 2. НАСТРОЙКИ ---
set "hosts_file=%SystemRoot%\System32\drivers\etc\hosts"
set "IP=85.137.95.246"

:: Список доменов для очистки и добавления
set "DOMAINS=elevenlabs.io chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com"

echo.
echo [1/4] Creating backup...
copy /y "%hosts_file%" "%hosts_file%.bak.%RANDOM%" >nul
echo       Backup saved.

echo.
echo [2/4] Preparing update script...
attrib -r "%hosts_file%" >nul 2>&1
set "ps_script=%TEMP%\gf_update_hosts.ps1"

> "%ps_script%" echo param^([string]$HostsPath, [string]$IP, [string]$DomainList^)
>> "%ps_script%" echo $doms = $DomainList.Split^(' '^)
>> "%ps_script%" echo $txt = @^(^)
>> "%ps_script%" echo if ^(Test-Path $HostsPath^) { $txt = Get-Content $HostsPath }
>> "%ps_script%" echo $out = @^(^)
>> "%ps_script%" echo $found = @{}
>> "%ps_script%" echo foreach ^($line in $txt^) {
>> "%ps_script%" echo     $replaced = $false
>> "%ps_script%" echo     foreach ^($d in $doms^) {
>> "%ps_script%" echo         $pattern = '^\s*[^#\s]+\s+' + [regex]::Escape^($d^) + '\s*$'
>> "%ps_script%" echo         if ^($line -match $pattern^) {
>> "%ps_script%" echo             if ^(-not $replaced^) {
>> "%ps_script%" echo                 $line = $line -replace '^\s*[^\s]+', $IP
>> "%ps_script%" echo                 $replaced = $true
>> "%ps_script%" echo             }
>> "%ps_script%" echo             $found[$d] = $true
>> "%ps_script%" echo         }
>> "%ps_script%" echo     }
>> "%ps_script%" echo     $out += $line
>> "%ps_script%" echo }
>> "%ps_script%" echo $newEntries = @^(^)
>> "%ps_script%" echo foreach ^($d in $doms^) {
>> "%ps_script%" echo     if ^(-not $found[$d]^) {
>> "%ps_script%" echo         $newEntries += "$IP $d"
>> "%ps_script%" echo     }
>> "%ps_script%" echo }
>> "%ps_script%" echo if ^($newEntries.Count -gt 0^) {
>> "%ps_script%" echo     $out += ''
>> "%ps_script%" echo     $out += '# --- AI HOSTS FIX START ---'
>> "%ps_script%" echo     $out += $newEntries
>> "%ps_script%" echo     $out += '# --- AI HOSTS FIX END ---'
>> "%ps_script%" echo }
>> "%ps_script%" echo $enc = New-Object System.Text.UTF8Encoding $false
>> "%ps_script%" echo [IO.File]::WriteAllLines^($HostsPath, [string[]]$out, $enc^)

echo.
echo [3/4] Updating entries with IP %IP%...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps_script%" -HostsPath "%hosts_file%" -IP "%IP%" -DomainList "%DOMAINS%"
del "%ps_script%" >nul 2>&1

echo.
echo [4/4] Flushing DNS cache...
ipconfig /flushdns >nul

echo.
echo ==============================================
echo  SUCCESS! ALL HOSTS UPDATED.
echo ==============================================
pause
