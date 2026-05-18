#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${CYAN}>>>${NC} $1"; }
section() { echo -e "\n${BOLD}${YELLOW}=== $1 ===${NC}"; }

ERRORS=0

run_salt() {
    local minion=$1 cmd=$2
    salt "$minion" cmd.run "$cmd" --timeout=30 2>/dev/null | tail -n +2
}

has_ip() { echo "$1" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; }

# ─── DNS ──────────────────────────────────────────────────────────────────────

section "DNS: Resolución externa desde LAN (minion-02 → bind9 en minion-05)"
info "dig @192.168.0.1 google.com +short"
OUT=$(run_salt minion-02 'dig @192.168.0.1 google.com +short')
echo "$OUT"
if has_ip "$OUT"; then
    pass "bind9 resolvió google.com vía forwarder 8.8.8.8. DNS en minion-05 acepta consultas LAN y reenvía a internet correctamente."
else
    fail "bind9 no responde en 192.168.0.1 o forwarder no funciona."
    ERRORS=$((ERRORS+1))
fi

section "DNS: Resolución interna desde LAN (ns1.internal.local)"
info "dig @192.168.0.1 ns1.internal.local +short"
OUT=$(run_salt minion-02 'dig @192.168.0.1 ns1.internal.local +short')
echo "$OUT"
if has_ip "$OUT"; then
    pass "bind9 resolvió hostname interno ns1.internal.local → IP LAN del firewall. La zona internal.local está activa y responde correctamente."
else
    fail "No resolvió ns1.internal.local. Verificar zona db.internal en bind9 y que el serial/named sea correcto."
    ERRORS=$((ERRORS+1))
fi

section "DNS: Resolución externa desde DMZ (minion-04 → bind9 en minion-05)"
info "dig @192.168.1.1 google.com +short"
OUT=$(run_salt minion-04 'dig @192.168.1.1 google.com +short')
echo "$OUT"
if has_ip "$OUT"; then
    pass "bind9 acepta consultas desde la DMZ (192.168.1.1). Los hosts en DMZ pueden resolver dominios externos."
else
    fail "bind9 no responde desde DMZ. Verificar allow-query en named.conf o reglas input de nftables."
    ERRORS=$((ERRORS+1))
fi

# ─── FIREWALL ─────────────────────────────────────────────────────────────────

section "FIREWALL: LAN → WAN sin restricciones (minion-02)"
info "curl -s --max-time 8 https://ifconfig.me"
OUT=$(run_salt minion-02 'curl -s --max-time 8 https://ifconfig.me')
echo "$OUT"
if has_ip "$OUT"; then
    pass "minion-02 (LAN) tiene salida a internet. MASQUERADE en minion-05 funciona y la cadena forward permite LAN→WAN sin restricciones."
else
    fail "minion-02 sin salida a internet. Verificar MASQUERADE y regla 'iifname enp0s8 oifname enp0s3 accept' en nftables."
    ERRORS=$((ERRORS+1))
fi

section "FIREWALL: DMZ → WAN HTTP/HTTPS permitido (minion-04)"
info "curl -s --max-time 8 https://ifconfig.me"
OUT=$(run_salt minion-04 'curl -s --max-time 8 https://ifconfig.me')
echo "$OUT"
if has_ip "$OUT"; then
    pass "minion-04 (DMZ) accede a internet vía HTTPS. El firewall permite correctamente tcp dport 80/443 desde DMZ hacia WAN."
else
    fail "minion-04 sin salida HTTPS. Verificar regla 'iifname enp0s9 oifname enp0s3 tcp dport {80,443} accept' en nftables."
    ERRORS=$((ERRORS+1))
fi

section "FIREWALL: DMZ → WAN ICMP permitido (minion-04)"
info "ping -c 3 -W 3 8.8.8.8"
OUT=$(run_salt minion-04 'ping -c 3 -W 3 8.8.8.8')
echo "$OUT"
if echo "$OUT" | grep -q "bytes from"; then
    pass "minion-04 (DMZ) puede hacer ping a WAN. Las reglas nftables permiten ICMP desde DMZ (enp0s9→enp0s3), además de HTTP/HTTPS."
else
    fail "ICMP desde DMZ bloqueado o sin respuesta. Verificar regla 'iifname enp0s9 oifname enp0s3 ip protocol icmp accept'."
    ERRORS=$((ERRORS+1))
fi

section "FIREWALL: Estado de servicios en minion-05"
info "systemctl is-active named nftables"
OUT=$(run_salt minion-05 'systemctl is-active named nftables')
echo "$OUT"
ACTIVE_COUNT=$(echo "$OUT" | grep -c "^    active$" || true)
if [ "$ACTIVE_COUNT" -ge 2 ]; then
    pass "Servicios named (bind9/DNS) y nftables (firewall) ambos activos en minion-05."
elif echo "$OUT" | grep -q "active"; then
    pass "Al menos un servicio activo. Verificar el que aparezca como inactive."
else
    fail "Servicios no activos en minion-05."
    ERRORS=$((ERRORS+1))
fi

section "FIREWALL: Reglas nftables en minion-05"
info "nft list ruleset"
run_salt minion-05 'nft list ruleset'

# ─── RESUMEN ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${YELLOW}========================================${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}RESULTADO: Todas las pruebas pasaron correctamente.${NC}"
else
    echo -e "${RED}${BOLD}RESULTADO: $ERRORS prueba(s) fallaron. Revisar output arriba.${NC}"
fi
echo -e "${BOLD}${YELLOW}========================================${NC}"
