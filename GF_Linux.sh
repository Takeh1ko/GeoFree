#!/bin/bash
# add_hosts.sh — добавляет/заменяет записи в /etc/hosts без дублирования
# Использование:
# sudo ./add_hosts.sh # использовать DEFAULT_IP (подтверждение через Enter)
# sudo ./add_hosts.sh 1.2.3.4 # использовать IP из аргумента (без подтверждения)
set -euo pipefail

hosts_file="/etc/hosts"
DEFAULT_IP="94.131.119.22"
HOSTS=(
    chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com
    cdn.oaistatic.com files.oaiusercontent.com cdn.auth0.com tcr9i.chat.openai.com
    webrtc.chatgpt.com gemini.google.com aistudio.google.com generativelanguage.googleapis.com
    alkalimakersuite-pa.clients6.google.com copilot.microsoft.com sydney.bing.com
    edgeservices.bing.com claude.ai aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com
    x.ai grok.com accounts.x.ai labs.google anthropic.com api.anthropic.com api.openai.com
)

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok() { echo -e "${GREEN}[OK]${NC} $1"; }
skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    error "Требуются права root. Используйте sudo."
    exit 1
fi

# Валидация IPv4
is_valid_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r a b c d <<< "$ip"
        for oct in $a $b $c $d; do
            (( oct < 0 || oct > 255 )) && return 1
        done
        return 0
    fi
    return 1
}

# Получение IP
if [ "${1:-}" != "" ]; then
    IP="$1"
else
    echo -n "Стандартный IP: $DEFAULT_IP. Enter — подтвердить, или введите свой: "
    read -r input_ip
    IP="${input_ip:-$DEFAULT_IP}"
fi

if ! is_valid_ip "$IP"; then
    error "Неверный IP: $IP"
    exit 1
fi

info "Используется IP: $IP"

# Резервная копия
stamp=$(date +"%Y%m%d_%H%M%S")
if cp "$hosts_file" "${hosts_file}.backup.${stamp}" 2>/dev/null; then
    ok "Резервная копия: ${hosts_file}.backup.${stamp}"
else
    error "Не удалось создать резервную копию"
    exit 1
fi

# Обработка хостов
tmp_new=$(mktemp)
trap 'rm -f "$tmp_new"' EXIT

for host in "${HOSTS[@]}"; do
    if grep -E -q "^[[:space:]]*${IP}[[:space:]]+.*\b${host}\b" "$hosts_file"; then
        skip "$host (уже есть с $IP)"
        continue
    fi
    awk -v h="$host" '{
        if ($0 ~ /^[[:space:]]*#/) { print; next }
        if ($0 ~ ("\\<" h "\\>")) { next }
        print
    }' "$hosts_file" > "${hosts_file}.tmp.$$" && mv "${hosts_file}.tmp.$$" "$hosts_file"
    echo -e "${IP}\t${host}" >> "$tmp_new"
    ok "Добавлен: $host"
done

# Применение изменений
if [ -s "$tmp_new" ]; then
    echo "" >> "$hosts_file"
    cat "$tmp_new" >> "$hosts_file"
    ok "Записи добавлены в $hosts_file"
else
    info "Новых записей не требуется"
fi

# Очистка DNS кеша
info "Очистка DNS кеша..."
dns_cleared=false

# systemd-resolved
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    if resolvectl flush-caches 2>/dev/null || systemd-resolve --flush-caches 2>/dev/null; then
        ok "systemd-resolved: кеш очищен"
        dns_cleared=true
    fi
fi

# nscd
if command -v nscd &>/dev/null && systemctl is-active --quiet nscd 2>/dev/null; then
    if nscd -i hosts 2>/dev/null; then
        ok "nscd: кеш очищен"
        dns_cleared=true
    fi
fi

# dnsmasq
if command -v dnsmasq &>/dev/null && (systemctl is-active --quiet dnsmasq 2>/dev/null || pgrep -x dnsmasq &>/dev/null); then
    if killall -HUP dnsmasq 2>/dev/null; then
        ok "dnsmasq: кеш очищен"
        dns_cleared=true
    fi
fi

$dns_cleared || skip "DNS кеш не найден или не требует очистки"

ok "Готово!"
exit 0