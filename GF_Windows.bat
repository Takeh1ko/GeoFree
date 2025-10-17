@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

set "DEFAULT_IP=94.131.119.22"
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"

REM Colors for output
set "C_OK=[92m[OK][0m"
set "C_SKIP=[93m[SKIP][0m"
set "C_ERROR=[91m[ERROR][0m"
set "C_INFO=[94m[INFO][0m"

REM Check for administrator rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %C_ERROR% Administrator rights required
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM Get IP
if "%~1" neq "" (
    set "IP=%~1"
) else (
    echo.
    echo Default IP: %DEFAULT_IP%
    set /p "IP=Press Enter to confirm, or type your own IP: "
    if "!IP!" == "" set "IP=%DEFAULT_IP%"
)

echo.
echo %C_INFO% Using IP: !IP!
echo.

REM Check if hosts file exists
if not exist "%HOSTS_FILE%" (
    echo %C_ERROR% Hosts file not found: %HOSTS_FILE%
    pause
    exit /b 1
)

REM Create backup
set "TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"
set "BACKUP_FILE=%HOSTS_FILE%.backup.!TIMESTAMP!"

copy "%HOSTS_FILE%" "%BACKUP_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    echo %C_OK% Backup created: %BACKUP_FILE%
) else (
    echo %C_ERROR% Failed to create backup
    pause
    exit /b 1
)

echo.

REM Temporary file for new entries
set "TEMP_NEW=%TEMP%\hosts_new_%RANDOM%.txt"
set "ADDED=0"
set "SKIPPED=0"

REM Hosts list
set "HOSTS_LIST=chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com"

> "%TEMP_NEW%" echo.

REM Process each host
for %%H in (%HOSTS_LIST%) do (
    findstr /I /C:"!IP!" "%HOSTS_FILE%" | findstr /I /C:"%%H" >nul 2>&1
    if !errorlevel! equ 0 (
        echo %C_SKIP% %%H ^(already exists with !IP!^)
        set /a SKIPPED+=1
    ) else (
        echo %C_OK% Added: %%H
        >> "%TEMP_NEW%" echo !IP!	%%H
        set /a ADDED+=1
    )
)

REM Apply changes
if !ADDED! gtr 0 (
    type "%HOSTS_FILE%" > "%HOSTS_FILE%.tmp"
    echo. >> "%HOSTS_FILE%.tmp"
    echo # Added by hosts manager >> "%HOSTS_FILE%.tmp"
    type "%TEMP_NEW%" >> "%HOSTS_FILE%.tmp"
    move /y "%HOSTS_FILE%.tmp" "%HOSTS_FILE%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo.
        echo %C_OK% Entries added: !ADDED!
    ) else (
        echo %C_ERROR% Failed to write to hosts file
        del "%TEMP_NEW%" >nul 2>&1
        pause
        exit /b 1
    )
) else (
    echo.
    echo %C_INFO% No new entries required
)

if !SKIPPED! gtr 0 (
    echo %C_INFO% Existing entries skipped: !SKIPPED!
)

del "%TEMP_NEW%" >nul 2>&1

REM Flush Windows DNS cache
echo.
echo %C_INFO% Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
if %errorlevel% equ 0 (
    echo %C_OK% DNS cache flushed
) else (
    echo %C_SKIP% Failed to flush DNS cache
)

REM Final message
echo.
echo ====================================
echo %C_OK% Done!
echo ====================================
echo.
echo IP: !IP!
echo Backup file: %BACKUP_FILE%
echo.
echo IMPORTANT: Restart browsers and applications!
echo.
pause
exit /b 0
