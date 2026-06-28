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
echo [1/3] Creating backup...
copy /y "%hosts_file%" "%hosts_file%.bak.%RANDOM%" >nul
echo       Backup saved.

echo.
echo [2/3] Updating entries with IP %IP%...
set "PS_CMD=powershell -NoProfile -ExecutionPolicy Bypass -Command \"$hosts='%hosts_file%'; $ip='%IP%'; $doms='%DOMAINS%'.Split(' '); $txt=Get-Content $hosts; $out=@(); $found=@{}; foreach($l in $txt){ $replaced=$false; foreach($d in $doms){ if($l -match '^(?i)\s*[^#\s]+\s+.*\b'+[regex]::Escape($d)+'(?:\b|$)'){ if(!$replaced){ $l=$l -replace '^\s*[^#\s]+',$ip; $replaced=$true; }; $found[$d]=$true; } }; $out+=$l }; $add=$false; foreach($d in $doms){ if(!$found[$d]){ if(!$add){ $out+=''; $out+='# --- AI HOSTS FIX START ---'; $add=$true }; $out+=\"$ip $d\"; } }; if($add){ $out+='# --- AI HOSTS FIX END ---' }; $utf8NoBom = New-Object System.Text.UTF8Encoding $false; [IO.File]::WriteAllLines($hosts, $out, $utf8NoBom)\""
%PS_CMD%

echo.
echo [3/3] Flushing DNS cache...
ipconfig /flushdns >nul

echo.
echo ==============================================
echo  SUCCESS! ALL HOSTS UPDATED.
echo ==============================================
pause
