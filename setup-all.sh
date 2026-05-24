#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info() { echo -e "${YELLOW}  ▸${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }

[ "$EUID" -eq 0 ] || err "Запустите от root"
command -v curl &>/dev/null || apt-get install -y curl -qq

echo -e "${NC}"
echo -e "  ${CYAN}Server Setup — 3dProxy + PBX Dashboard${NC}"
echo ""

read -rp "  Сколько SOCKS5 прокси создать? " PROXY_COUNT
[[ "$PROXY_COUNT" =~ ^[0-9]+$ ]] && [ "$PROXY_COUNT" -ge 1 ] || err "Введите число >= 1"
echo ""

# ── Шаг 1: 3dProxy ───────────────────────────────────────────────────────────
info "Шаг 1/2 — Устанавливаем 3dProxy (${PROXY_COUNT} шт)..."

TMP_3PROXY=$(mktemp /tmp/3proxy-XXXXXX.sh)
curl -fsSL https://raw.githubusercontent.com/garaed/3dProxy/refs/heads/main/3proxy_install \
    -o "$TMP_3PROXY"
chmod +x "$TMP_3PROXY"
echo "$PROXY_COUNT" | bash "$TMP_3PROXY"
rm -f "$TMP_3PROXY"

ok "3dProxy установлен"
echo ""

# ── Шаг 2: PBX Dashboard ─────────────────────────────────────────────────────
info "Шаг 2/2 — Устанавливаем PBX Dashboard..."
bash <(curl -fsSL https://raw.githubusercontent.com/garaed/PBX_dashboard/main/setup.sh)
ok "PBX Dashboard установлен"
echo ""

# ── Итог ─────────────────────────────────────────────────────────────────────
SERVER_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || \
            curl -s --max-time 5 https://api.ipify.org 2>/dev/null || \
            hostname -I | awk '{print $1}')
CFG="/etc/3proxy/3proxy.cfg"

echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   Установка завершена!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  📊 PBX Dashboard:${NC}"
echo -e "  http://${SERVER_IP}:8080"
echo ""
echo -e "${CYAN}  🔒 Прокси (${PROXY_COUNT} шт):${NC}"

if [ ! -f "$CFG" ]; then
    echo -e "  ${RED}Конфиг не найден: $CFG${NC}"
else
    declare -A CREDS
    while IFS= read -r line; do
        [[ "$line" =~ ^users ]] || continue
        for entry in ${line#users }; do
            login=$(cut -d: -f1 <<< "$entry")
            pass=$(cut  -d: -f3 <<< "$entry")
            CREDS["$login"]="$pass"
        done
    done < "$CFG"

    COUNT=0; current_user=""
    while IFS= read -r line; do
        line="${line%%#*}"; line="${line//[$'\t' ]/ }"
        line="${line## }"; line="${line%% }"
        if [[ "$line" =~ ^allow[[:space:]]+([^[:space:]]+) ]]; then
            current_user="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^socks[[:space:]]+-p([0-9]+) ]] && [ -n "$current_user" ]; then
            port="${BASH_REMATCH[1]}"
            pass="${CREDS[$current_user]:-???}"
            echo -e "  ${YELLOW}socks5://${current_user}:${pass}@${SERVER_IP}:${port}${NC}"
            ((COUNT++)) || true; current_user=""
        fi
    done < "$CFG"

    echo ""
    echo -e "  Создано прокси: ${GREEN}${COUNT}${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
echo ""
