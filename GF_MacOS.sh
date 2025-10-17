#!/usr/bin/env bash
# add_hosts_macos.sh — добавляет/заменяет записи в /etc/hosts без дублирования (macOS)
# Использование:
# sudo ./add_hosts_macos.sh # использовать DEFAULT_IP (подтверждение через Enter)
# sudo ./add_hosts_macos.sh 1.2.3.4 # использовать IP из аргумента (без подтверждения)
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
    if [[ ! $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 1
    fi
    IFS='.' read -r a b c d <<< "$ip"
    for oct in $a $b $c $d; do
        (( oct < 0 || oct > 255 )) && return 1
    done
    return 0
}

# Получение IP
if [ "${1:-}" != "" ]; then
    IP="$1"
else
    printf "Стандартный IP: %s. Enter — подтвердить, или введите свой: " "$DEFAULT_IP"
    read -r input_ip
    IP="${input_ip:-$DEFAULT_IP}"
fi

if ! is_valid_ip "$IP"; then
    error "Неверный IP: $IP"
    exit 1
fi

info "Используется IP: $IP"

# Проверка существования файла
if [ ! -f "$hosts_file" ]; then
    error "Файл hosts не найден: $hosts_file"
    exit 1
fi

# Резервная копия
stamp=$(date +"%Y%m%d_%H%M%S")
backup_file="${hosts_file}.backup.${stamp}"
if cp -p "$hosts_file" "$backup_file" 2>/dev/null; then
    ok "Резервная копия: $backup_file"
else
    error "Не удалось создать резервную копию"
    exit 1
fi

# Обработка хостов
tmp_new=$(mktemp)
trap 'rm -f "$tmp_new"' EXIT

for host in "${HOSTS[@]}"; do
    if grep -E -q "^[[:space:]]*${IP}[[:space:]]+.*[[:space:]]${host}([[:space:]]|$)" "$hosts_file" || \
       grep -E -q "^[[:space:]]*${IP}[[:space:]]+${host}([[:space:]]|$)" "$hosts_file"; then
        skip "$host (уже есть с $IP)"
        continue
    fi
    
    awk -v h="$host" '{
        if ($0 ~ /^[[:space:]]*#/) { print; next }
        found = 0
        for (i = 1; i <= NF; i++) {
            if ($i == h) { found = 1; break }
        }
        if (found) { next }
        print
    }' "$hosts_file" > "${hosts_file}.tmp.$$" && mv "${hosts_file}.tmp.$$" "$hosts_file"
    
    echo -e "${IP}\t${host}" >> "$tmp_new"
    ok "Добавлен: $host"
done

# Применение изменений
if [ -s "$tmp_new" ]; then
    printf "\n" >> "$hosts_file"
    cat "$tmp_new" >> "$hosts_file"
    ok "Записи добавлены в $hosts_file"
else
    info "Новых записей не требуется"
fi

# Очистка DNS кеша macOS
info "Очистка DNS кеша macOS..."
dns_cleared=false

# Определяем версию macOS и очищаем кеш соответствующей командой
macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
major_version=$(echo "$macos_version" | cut -d. -f1)

if [ "$major_version" = "unknown" ]; then
    skip "Не удалось определить версию macOS"
elif [ "$major_version" -ge 12 ]; then
    # macOS 12 (Monterey) и выше
    if dscacheutil -flushcache 2>/dev/null && killall -HUP mDNSResponder 2>/dev/null; then
        ok "DNS кеш очищен (macOS $macos_version)"
        dns_cleared=true
    fi
elif [ "$major_version" -ge 11 ]; then
    # macOS 11 (Big Sur)
    if dscacheutil -flushcache 2>/dev/null && killall -HUP mDNSResponder 2>/dev/null; then
        ok "DNS кеш очищен (macOS $macos_version)"
        dns_cleared=true
    fi
elif [ "$major_version" -ge 10 ]; then
    # macOS 10.10 - 10.15
    if dscacheutil -flushcache 2>/dev/null && killall -HUP mDNSResponder 2>/dev/null; then
        ok "DNS кеш очищен (macOS $macos_version)"
        dns_cleared=true
    fi
else
    skip "Неподдерживаемая версия macOS: $macos_version"
fi

$dns_cleared || skip "DNS кеш не удалось очистить"

ok "Готово!"
exit 0