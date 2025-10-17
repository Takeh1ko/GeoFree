@echo off
setlocal EnableDelayedExpansion

set "DEFAULT_IP=94.131.119.22"
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if "%~1" neq "" (
    set "IP=%~1"
) else (
    echo.
    echo Default IP: %DEFAULT_IP%
    set /p "IP=Press Enter for default IP or type your IP: "
    if "!IP!" == "" set "IP=%DEFAULT_IP%"
)

echo.
echo Using IP: !IP!
echo.

if not exist "%HOSTS_FILE%" (
    echo ERROR: hosts file not found
    pause
    exit /b 1
)

set "TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"
set "BACKUP_FILE=%HOSTS_FILE%.backup.!TIMESTAMP!"

copy "%HOSTS_FILE%" "%BACKUP_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Backup created: %BACKUP_FILE%
) else (
    echo [ERROR] Failed to create backup
    pause
    exit /b 1
)

echo.
echo Checking and adding entries to hosts file...
echo.

set "TEMP_NEW=%TEMP%\hosts_new_%RANDOM%.txt"
set "ADDED=0"
set "SKIPPED=0"

set "HOSTS_LIST=chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com netflix.com spotify.com"

> "%TEMP_NEW%" echo.

for %%H in (%HOSTS_LIST%) do (
    findstr /C:"%%H" "%HOSTS_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SKIP] %%H - already exists
        set /a SKIPPED+=1
    ) else (
        echo [ADD] %%H
        >> "%TEMP_NEW%" echo !IP!	%%H
        set /a ADDED+=1
    )
)

if !ADDED! gtr 0 (
    type "%HOSTS_FILE%" > "%HOSTS_FILE%.tmp"
    echo. >> "%HOSTS_FILE%.tmp"
    echo # Added by hosts manager >> "%HOSTS_FILE%.tmp"
    type "%TEMP_NEW%" >> "%HOSTS_FILE%.tmp"
    
    move /y "%HOSTS_FILE%.tmp" "%HOSTS_FILE%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo.
        echo [OK] Added !ADDED! new entries
    ) else (
        echo [ERROR] Failed to write to hosts file
        del "%TEMP_NEW%" >nul 2>&1
        pause
        exit /b 1
    )
) else (
    echo.
    echo [INFO] No new entries needed, all hosts already exist
)

if !SKIPPED! gtr 0 (
    echo [INFO] Skipped !SKIPPED! existing entries
)

del "%TEMP_NEW%" >nul 2>&1

echo.
echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo [OK] DNS cache flushed
echo.

echo ====================================
echo Operation completed successfully!
echo ====================================
echo.
echo IP used: !IP!
echo Backup: %BACKUP_FILE%
echo.
echo IMPORTANT: Please restart your browsers and apps!
echo.

pause
exit /b 0