#!/usr/bin/env bash
set -euo pipefail

hosts_file="/etc/hosts"
DEFAULT_IP="94.131.119.22"

HOSTS=(
  chatgpt.com
  ab.chatgpt.com
  auth.openai.com
  auth0.openai.com
  platform.openai.com
  cdn.oaistatic.com
  files.oaiusercontent.com
  cdn.auth0.com
  tcr9i.chat.openai.com
  webrtc.chatgpt.com
  gemini.google.com
  aistudio.google.com
  generativelanguage.googleapis.com
  alkalimakersuite-pa.clients6.google.com
  copilot.microsoft.com
  sydney.bing.com
  edgeservices.bing.com
  claude.ai
  aitestkitchen.withgoogle.com
  aisandbox-pa.googleapis.com
  x.ai
  grok.com
  accounts.x.ai
  labs.google
  anthropic.com
  api.anthropic.com
  api.openai.com
  netflix.com
  spotify.com
)

# Проверка прав (нужен root)
if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт должен быть запущен с правами root. Используйте sudo."
  exit 1
fi

# Валидация IPv4
is_valid_ip() {
  local ip=$1
  # базовая проверка формата
  if [[ ! $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi
  IFS='.' read -r a b c d <<< "$ip"
  for oct in $a $b $c $d; do
    if (( oct < 0 || oct > 255 )); then
      return 1
    fi
  done
  return 0
}

# Получаем IP: аргумент или запрос
if [ "${1:-}" != "" ]; then
  IP="$1"
else
  printf "Будет использован стандартный IP: %s\nНажмите Enter для подтверждения или введите свой IP и нажмите Enter: " "$DEFAULT_IP"
  read -r input_ip
  if [ -n "$input_ip" ]; then
    IP="$input_ip"
  else
    IP="$DEFAULT_IP"
  fi
fi

if ! is_valid_ip "$IP"; then
  echo "Неверный IP: $IP"
  exit 1
fi

# временный файл для новых записей
tmp_new=$(mktemp)
trap 'rm -f "$tmp_new"' EXIT

# основной цикл — для каждого хоста
for host in "${HOSTS[@]}"; do
  # если уже есть строка с тем же IP и этим хостом — пропустить
  if grep -E -q "^[[:space:]]*${IP}[[:space:]]+.*[[:space:]]${host}([[:space:]]|$)" "$hosts_file" || grep -E -q "^[[:space:]]*${IP}[[:space:]]+${host}([[:space:]]|$)" "$hosts_file"; then
    echo "Пропускаю ${host} — уже присутствует с IP ${IP}"
    continue
  fi

  # иначе — удаляем все **некомментированные** строки, содержащие этот хост (чтобы не дублировать)
  # Используем awk: если строка начинается с # — сохраняем; иначе проверяем, есть ли среди полей точное совпадение хоста — если да, пропускаем
  awk -v h="$host" '
    {
      if ($0 ~ /^[[:space:]]*#/) { print; next }
      found = 0
      for (i = 1; i <= NF; i++) {
        if ($i == h) { found = 1; break }
      }
      if (found) { next }
      print
    }
  ' "$hosts_file" > "${hosts_file}.tmp.$$" && mv "${hosts_file}.tmp.$$" "$hosts_file"

  echo -e "${IP}\t${host}" >> "$tmp_new"
  echo "Запланирована новая запись: ${IP} ${host}"
done

# Добавляем новые записи
if [ -s "$tmp_new" ]; then
  printf "\n" >> "$hosts_file"
  cat "$tmp_new" >> "$hosts_file"
  echo "Добавлены новые записи в $hosts_file"
else
  echo "Новых записей не требуется."
fi

exit 0
