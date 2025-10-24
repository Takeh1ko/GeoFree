@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: add_hosts.bat — добавляет/заменяет записи в hosts без дублирования
:: Использование:
:: add_hosts.bat                    (использовать DEFAULT_IP с подтверждением)
:: add_hosts.bat 1.2.3.4            (использовать IP из аргумента)

set "hosts_file=%SystemRoot%\System32\drivers\etc\hosts"
set "DEFAULT_IP=94.131.119.22"

:: Список хостов
set "HOSTS=chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com

:: Проверка прав администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Требуются права администратора. Запустите от имени администратора.
    pause
    exit /b 1
)

:: Получение IP
if not "%~1"=="" (
    set "IP=%~1"
) else (
    echo Стандартный IP: %DEFAULT_IP%
    set /p "input_ip=Enter — подтвердить, или введите свой IP: "
    if "!input_ip!"=="" (
        set "IP=%DEFAULT_IP%"
    ) else (
        set "IP=!input_ip!"
    )
)

echo [INFO] Используется IP: %IP%

:: Создание резервной копии
for /f "tokens=1-6 delims=/: " %%a in ("%date% %time%") do (
    set "stamp=%%c%%b%%a_%%d%%e%%f"
)
set "stamp=!stamp: =0!"
set "backup_file=%hosts_file%.backup.!stamp!"

copy "%hosts_file%" "!backup_file!" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Резервная копия: !backup_file!
) else (
    echo [ERROR] Не удалось создать резервную копию
    pause
    exit /b 1
)

:: Создание временных файлов
set "temp_hosts=%TEMP%\hosts_temp_%RANDOM%.txt"
set "new_entries=%TEMP%\hosts_new_%RANDOM%.txt"
type nul > "%new_entries%"

:: Обработка каждого хоста
set "changes=0"
for %%h in (%HOSTS%) do (
    set "host=%%h"
    set "exists=0"
    
    :: Проверка, есть ли уже запись с нужным IP и хостом
    for /f "tokens=1,2" %%a in ('findstr /i "%%h" "%hosts_file%" 2^>nul') do (
        if "%%a"=="%IP%" if "%%b"=="%%h" (
            set "exists=1"
        )
    )
    
    if !exists! equ 1 (
        echo [SKIP] %%h ^(уже есть с %IP%^)
    ) else (
        :: Удаляем старые записи этого хоста
        findstr /v /i "%%h" "%hosts_file%" > "%temp_hosts%" 2>nul
        if exist "%temp_hosts%" (
            copy /y "%temp_hosts%" "%hosts_file%" >nul 2>&1
        )
        
        :: Добавляем в список новых записей
        echo %IP%	%%h>> "%new_entries%"
        echo [OK] Добавлен: %%h
        set /a "changes+=1"
    )
)

:: Применение изменений
if %changes% gtr 0 (
    echo.>> "%hosts_file%"
    type "%new_entries%" >> "%hosts_file%"
    echo [OK] Записи добавлены в hosts
) else (
    echo [INFO] Новых записей не требуется
)

:: Очистка DNS кеша
echo [INFO] Очистка DNS кеша...
ipconfig /flushdns >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] DNS кеш очищен
) else (
    echo [SKIP] Не удалось очистить DNS кеш
)

:: Очистка временных файлов
if exist "%temp_hosts%" del /f /q "%temp_hosts%" >nul 2>&1
if exist "%new_entries%" del /f /q "%new_entries%" >nul 2>&1

echo [OK] Готово!
pause
exit /b 0
