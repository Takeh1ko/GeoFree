:: Исправленная версия GF_Windows.bat, open sours от пользователя Takeh1ko code - https://github.com/Takeh1ko/GeoFree/blob/master/GF_Windows.bat, увы у меня не работало на пк но при помощи AI и исправил ситуацию, и сейчас все работает как часики, спасибо Takeh1ko за sours!
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: add_hosts.bat
set "hosts_file=%SystemRoot%\System32\drivers\etc\hosts"
set "DEFAULT_IP=94.131.119.22"

set "HOSTS=chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com"

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause
    exit /b 1
)

:: Get IP
if not "%~1"=="" (
    set "IP=%~1"
) else (
    echo Default IP: %DEFAULT_IP%
    set /p "input_ip=Press Enter to confirm, or type custom IP: "
    if "!input_ip!"=="" (
        set "IP=%DEFAULT_IP%"
    ) else (
        set "IP=!input_ip!"
    )
)

echo [INFO] Using IP: %IP%

:: Backup
set "backup_file=%hosts_file%.backup.%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "backup_file=!backup_file: =0!"

copy "%hosts_file%" "!backup_file!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Backup: !backup_file!
) else (
    echo [ERROR] Backup failed
    pause
    exit /b 1
)

:: Temp files
set "temp_hosts=%TEMP%\hosts_temp_%RANDOM%.txt"
set "new_entries=%TEMP%\hosts_new_%RANDOM%.txt"
type nul > "!new_entries!"

:: Process hosts
set "changes=0"
for %%h in (%HOSTS%) do (
    set "exists=0"
    
    findstr /i /c:"%%h" "%hosts_file%" >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=1,2" %%a in ('findstr /i /c:"%%h" "%hosts_file%" 2^>nul') do (
            if "%%a"=="%IP%" if "%%b"=="%%h" (
                set "exists=1"
            )
        )
    )
    
    if !exists! equ 1 (
        echo [SKIP] %%h ^(already exists^)
    ) else (
        findstr /v /i /c:"%%h" "%hosts_file%" > "!temp_hosts!" 2>nul
        if exist "!temp_hosts!" (
            move /y "!temp_hosts!" "%hosts_file%" >nul 2>&1
        )
        
        echo %IP%	%%h>> "!new_entries!"
        echo [OK] Added: %%h
        set /a "changes+=1"
    )
)

:: Apply changes
if !changes! gtr 0 (
    echo.>> "%hosts_file%"
    type "!new_entries!" >> "%hosts_file%"
    echo [OK] Entries added to hosts
) else (
    echo [INFO] No new entries needed
)

:: Flush DNS
echo [INFO] Flushing DNS...
ipconfig /flushdns >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] DNS cache flushed
) else (
    echo [SKIP] DNS flush failed
)

:: Cleanup
if exist "!temp_hosts!" del /f /q "!temp_hosts!" >nul 2>&1
if exist "!new_entries!" del /f /q "!new_entries!" >nul 2>&1

echo [OK] Done!
pause
exit /b 0
