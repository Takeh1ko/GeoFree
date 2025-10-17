#!/bin/bash
# add_hosts.sh — добавляет/заменяет записи в /etc/hosts без дублирования
# Использование:
#   sudo ./add_hosts.sh            # использовать DEFAULT_IP (подтверждение через Enter)
#   sudo ./add_hosts.sh 1.2.3.4    # использовать IP из аргумента (без подтверждения)

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
  #
  netflix.com
  spotify.com
)

# Проверка прав
if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт должен быть запущен с правами root. Используйте sudo."
  exit 1
fi

# Валидация IPv4
is_valid_ip() {
  local ip=$1
  if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IFS='.' read -r a b c d <<< "$ip"
    for oct in $a $b $c $d; do
      if (( oct < 0 || oct > 255 )); then
        return 1
      fi
    done
    return 0
  fi
  return 1
}

# Получаем IP. аргумент или подтверждение DEFAULT_IP / ввод нового
if [ "${1:-}" != "" ]; then
  IP="$1"
else
  echo -n "Будет использован стандартный IP: $DEFAULT_IP
Нажмите Enter для подтверждения или введите свой IP и нажмите Enter: "
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

# Создать резервную копию
stamp=$(date +"%Y%m%d_%H%M%S")
cp "$hosts_file" "${hosts_file}.backup.${stamp}"
echo "Резервная копия: ${hosts_file}.backup.${stamp}"

# Файл-накопитель новых записей
tmp_new=$(mktemp)
trap 'rm -f "$tmp_new"' EXIT

for host in "${HOSTS[@]}"; do
  # если уже есть строка с тем же IP и этим хостом — пропустить
  if grep -E -q "^[[:space:]]*${IP}[[:space:]]+.*\b${host}\b" "$hosts_file"; then
    echo "Пропускаю ${host} — уже присутствует с IP ${IP}"
    continue
  fi

  # иначе — удаляем все некомментированные строки, содержащие этот хост (чтобы не дублировать)
  # и добавим новую строку с нужным IP в tmp_new
  awk -v h="$host" '{
    # оставляем комментированные строки как есть
    if ($0 ~ /^[[:space:]]*#/) { print; next }
    # если строка содержит слово h как отдельное слово — пропускаем (удаляем)
    if ($0 ~ ("\\<" h "\\>")) { next }
    print
  }' "$hosts_file" > "${hosts_file}.tmp.$$" && mv "${hosts_file}.tmp.$$" "$hosts_file"

  echo -e "${IP}\t${host}" >> "$tmp_new"
  echo "Запланирована новая запись: ${IP} ${host}"
done

# Добавляем все новые записи в конец hosts, если есть
if [ -s "$tmp_new" ]; then
  echo "" >> "$hosts_file"
  cat "$tmp_new" >> "$hosts_file"
  echo "Добавлены новые записи в $hosts_file"
else
  echo "Новых записей не требуется."
fi

exit 0
