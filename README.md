# GeoFree — доступ к AI-сервисам через `hosts` (без VPN)

**GeoFree** — лёгкий инструмент для резолвинга доменов через системный `hosts`.  
Помогает получить доступ к геозаблокированным AI-сервисам (ChatGPT, Claude, Gemini и другим) **без использования VPN**: автоматический бэкап `hosts`, добавление записей без дубликатов.  Поддерживается `Windows`, `Linux` и `macOS`.


### Что именно делает
- Создаёт резервную копию текущего файла hosts
- Удаляет старые некомментированные записи для целевых доменов (чтобы избежать дубликатов)
- Добавляет новые записи вида: `<IP> <домен>`
- Очищает DNS кеш после выполнения
- Не трогает закомментированные строки

По умолчанию используется стандартный IP (можно передать свой IP аргументом при запуске).

### Какие сервисы затрагиваются

- OpenAI / ChatGPT:
  - `chatgpt.com`, `ab.chatgpt.com`, `webrtc.chatgpt.com`, `tcr9i.chat.openai.com`
  - `auth.openai.com`, `platform.openai.com`, `api.openai.com`
  - `cdn.oaistatic.com`, `files.oaiusercontent.com`, `auth0.openai.com`, `cdn.auth0.com`

- Google AI (Gemini, AI Studio):
  - `gemini.google.com`, `aistudio.google.com`, `labs.google`
  - `generativelanguage.googleapis.com`, `aisandbox-pa.googleapis.com`
  - `alkalimakersuite-pa.clients6.google.com`

- Microsoft Copilot / Bing:
  - `copilot.microsoft.com`, `sydney.bing.com`, `edgeservices.bing.com`

- Anthropic (Claude):
  - `claude.ai`, `anthropic.com`, `api.anthropic.com`

- xAI (Grok):
  - `x.ai`, `grok.com`, `accounts.x.ai`

- Стриминг:
  - `netflix.com`, `spotify.com`

Нужно больше? Добавьте свои домены:
- Linux/macOS — в массив `HOSTS` в `GF_Linux.sh` или `GF_MacOS.sh`
- Windows — как строки `echo <домен>` в блоке формирования `%HOSTS_TMP%` в `GF_Windows.bat`

---

## Установка и использование

Ниже — самые короткие рабочие инструкции. Во всех скриптах можно указать свой IP как первый аргумент. Если не указать — скрипт предложит подтвердить стандартный IP.

Важно: для изменения файла hosts нужны права администратора/root. Скрипты автоматически проверяют права и/или подсказывают, как перезапуститься с повышением.

### Windows
Файл: `GF_Windows.bat`

Вариант 1 — Проводник:
1. Скачайте репозиторий (`Code` → `Download ZIP`) или клонируйте его
2. Кликните правой кнопкой по `GF_Windows.bat` → «Запуск от имени администратора»
3. При необходимости введите свой IP. Если IP не указывать, будет предложено использовать `94.131.119.22`

Вариант 2 — Командная строка (администратор):
```bat
REM С дефолтным IP (будет предложено подтвердить):
GF_Windows.bat

REM С указанием своего IP (без подтверждения):
GF_Windows.bat 1.2.3.4
```

После внесения изменений перезапустите приложения.

### Linux
Файл: `GF_Linux.sh`

```bash
chmod +x GF_Linux.sh
sudo ./GF_Linux.sh
```
```bash
# ИЛИ запуск с IP в аргументе 
sudo ./GF_Linux.sh 1.2.3.4
```



### MacOS
Файл: `GF_MacOS.sh`

```bash
chmod +x GF_MacOS.sh
sudo ./GF_MacOS.sh
```
```bash
# ИЛИ запуск с IP в аргументе
sudo ./GF_MacOS.sh 1.2.3.4
```



---

## Проверка и сброс DNS

После изменения hosts полезно проверить резолвинг и при необходимости сбросить DNS-кэш.

### Проверка
```bash
# Универсально (Linux/macOS):
getent hosts chatgpt.com || host chatgpt.com || dig +short chatgpt.com

# Windows:
nslookup chatgpt.com
```



---

## Откат изменений

Каждый скрипт создаёт резервную копию исходного `hosts` с таймстемпом. Чтобы откатиться:

- Windows:
  1. Откройте `%WinDir%\System32\drivers\etc` и найдите файл вида `hosts.backup.YYYYMMDD_HHMMSS`
  2. Замените текущий `hosts` этой копией (нужны права администратора)

- Linux/macOS:
  1. Найдите резервную копию рядом с `/etc/hosts` — `hosts.backup.YYYYMMDD_HHMMSS`
  2. Восстановите её:
     ```bash
     sudo cp /etc/hosts.backup.YYYYMMDD_HHMMSS /etc/hosts
     ```

---

## Примечания и ограничения
- Метод с файлом hosts — это ручной принудительный резолвинг доменов. Он прост и прозрачен, но не универсален
- Некоторые приложения могут кешировать DNS или использовать собственные резолверы/DoH/прокси — в таких случаях записи в hosts могут не примениться
- При необходимости дополняйте список доменов в соответствующем скрипте перед запуском

