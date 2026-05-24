#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Полная установка сервера: 3dProxy + PBX Dashboard
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/garaed/PBX_dashboard/main/setup-all.sh)
# ─────────────────────────────────────────────────────────────────────────────
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${YELLOW}  ▸${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }

[ "$EUID" -eq 0 ] || err "Запустите от root"
command -v curl &>/dev/null || { apt-get install -y curl -qq; }

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Установка: 3dProxy + PBX Dashboard     ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── Шаг 1: 3dProxy ───────────────────────────────────────────────────────────
info "Шаг 1/2 — Устанавливаем 3dProxy..."
curl -sSL https://raw.githubusercontent.com/garaed/3dProxy/main/3proxy-install.sh | bash
ok "3dProxy установлен"

echo ""

# ── Шаг 2: PBX Dashboard ─────────────────────────────────────────────────────
info "Шаг 2/2 — Устанавливаем PBX Dashboard..."
bash <(curl -fsSL https://raw.githubusercontent.com/garaed/PBX_dashboard/main/setup.sh)
ok "PBX Dashboard установлен"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Всё готово!                            ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""
echo "  PBX Dashboard: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
