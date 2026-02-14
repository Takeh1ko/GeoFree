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
set "IP=94.131.119.22"
set "temp_file=%TEMP%\hosts_clean.tmp"

:: Список доменов для очистки и добавления
set "DOMAINS=chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com"

echo.
echo [1/4] Creating backup...
copy /y "%hosts_file%" "%hosts_file%.bak.%RANDOM%" >nul
echo       Backup saved.

echo.
echo [2/4] Cleaning old entries...
:: Копируем hosts во временный файл, ИСКЛЮЧАЯ (findstr /v) строки с нашими доменами
:: Это удалит старые, возможно нерабочие IP
type "%hosts_file%" > "%temp_file%"
for %%D in (%DOMAINS%) do (
    type "%temp_file%" | findstr /v /i "%%D" > "%temp_file%.2"
    move /y "%temp_file%.2" "%temp_file%" >nul
)

echo.
echo [3/4] Writing new IP (%IP%)...
:: Добавляем новые записи в чистый файл
echo. >> "%temp_file%"
echo # --- AI HOSTS FIX START --- >> "%temp_file%"
for %%D in (%DOMAINS%) do (
    echo %IP% %%D >> "%temp_file%"
)
echo # --- AI HOSTS FIX END --- >> "%temp_file%"

:: Заменяем оригинальный файл
copy /y "%temp_file%" "%hosts_file%" >nul
del "%temp_file%"

echo.
echo [4/4] Flushing DNS cache...
ipconfig /flushdns >nul

echo.
echo ==============================================
echo  SUCCESS! ALL HOSTS UPDATED.
echo ==============================================
pause
