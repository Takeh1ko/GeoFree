# GeoFree — разблокировка AI-сервисов (ChatGPT, Claude, Gemini) без VPN

GeoFree — простой (даже для домохозяек) инструмент для обхода блокировки AI-сервисов через системный файл `hosts`.  
Быстрая разблокировка ChatGPT, Claude, Gemini и других AI-сервисов для пользователей из России и др. стран без использования VPN: автоматический бэкап, добавление записей без дубликатов. Поддерживается `Windows`, `Linux` и `macOS`.

---

## Как получить актуальный DNS адрес:
1. Введите команду `nslookup chatgpt.com dns.comss.one` (Linux/MacOS)
2. Скопируйте нижнее значение из поля Address (в примере ниже это значение — 80.74.29.235)
3. Укажите этот адрес при запуске скрипта

```
takehiko@takehiko:~$ nslookup chatgpt.com dns.comss.one
Server:		dns.comss.one
Address:	212.109.195.93#53

Non-authoritative answer:
Name:	chatgpt.com
Address: 80.74.29.235
```
---

### Что именно делает
- Создаёт резервную копию текущего файла hosts
- Удаляет старые некомментированные записи для целевых доменов (чтобы избежать дубликатов)
- Добавляет новые записи вида: `<IP> <домен>`
- Очищает DNS кеш после выполнения
- Не трогает закомментированные строки

По умолчанию используется стандартный IP (можно передать свой IP аргументом при запуске).

## 🔓 Поддерживаемые AI-сервисы

### Какие сервисы затрагиваются

- OpenAI / ChatGPT:
  - `chatgpt.com`, `ab.chatgpt.com`, `webrtc.chatgpt.com`, `tcr9i.chat.openai.com`
  - `auth.openai.com`, `platform.openai.com`, `api.openai.com`
  - `cdn.oaistatic.com`, `files.oaiusercontent.com`, `auth0.openai.com`, `cdn.auth0.com`

- Google AI (Gemini, AI Studio):
  - `gemini.google.com`, `aistudio.google.com`, `labs.google.com`
  - `generativelanguage.googleapis.com`, `aisandbox-pa.googleapis.com`
  - `alkalimakersuite-pa.clients6.google.com`, `aitestkitchen.withgoogle.com`

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
- Windows — в set "HOSTS_LIST=..."

---

## 🚀 Использование

Ниже — короткие рабочие инструкции. Во всех скриптах можно указать свой IP как первый аргумент (Если не знаете что это и зачем: смело жмите enter).

**Важно**: для изменения файла hosts нужны права администратора/root. Скрипты автоматически проверяют права и/или подсказывают, как перезапуститься с повышением.
После использования скрипта перезапустите браузер/приложение где используется сервисы ИИ.

---
### 🪟 Windows
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


---
### 🐧 Linux
Файл: `GF_Linux.sh`

```bash
chmod +x GF_Linux.sh
sudo ./GF_Linux.sh
```
```bash
# ИЛИ запуск с IP в аргументе 
sudo ./GF_Linux.sh 1.2.3.4
```
---
### 🍎 MacOS
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

Опционально:
Список доменов и поддоменов конкретных сервисов. Если хотите открыть доступ к конкретным сайтам, то найдите на сайте ниже нужный список и добавьте его в скрипт :)
https://raw.githubusercontent.com/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/hosts

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
- Метод с файлом hosts — это ручной принудительный резолвинг доменов.
- Некоторые приложения могут кешировать DNS или использовать собственные резолверы/DoH/прокси — в таких случаях записи в hosts могут не примениться
- При необходимости дополняйте список доменов в соответствующем скрипте перед запуском

