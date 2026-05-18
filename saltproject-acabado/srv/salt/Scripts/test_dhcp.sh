#!/bin/bash
set -u

DHCP_MINION=${DHCP_MINION:-minion-04}
FW_MINION=${FW_MINION:-minion-05}
errors=0
ok() { echo "[OK]   $*"; }
fail() { echo "[FAIL] $*"; errors=$((errors + 1)); }
run() { salt "$1" cmd.run "$2" python_shell=True --out=txt --timeout=30 2>/dev/null; }

echo "=== DHCP server dnsmasq ==="
out=$(run "$DHCP_MINION" "systemctl is-active dnsmasq 2>/dev/null || true; ss -lunp | grep ':67' || true; sed -n '1,160p' /etc/dnsmasq.conf 2>/dev/null || true")
echo "$out"
echo "$out" | grep -q active && ok "dnsmasq active" || fail "dnsmasq inactive"
echo "$out" | grep -q '192.168.1.50' && ok "DMZ range configured" || fail "DMZ DHCP range missing"

echo "=== DHCP relay on firewall ==="
out=$(run "$FW_MINION" "systemctl is-active isc-dhcp-relay 2>/dev/null || true; cat /etc/default/isc-dhcp-relay 2>/dev/null || true; ss -lunp | grep ':67' || true")
echo "$out"
echo "$out" | grep -q active && ok "relay active" || fail "relay inactive"
echo "$out" | grep -q 'enp0s8 enp0s9' && ok "relay listens LAN and DMZ" || fail "relay interfaces wrong"

echo "=== DHCP recent logs ==="
run "$DHCP_MINION" "journalctl -u dnsmasq --no-pager -n 80 || true"
run "$FW_MINION" "journalctl -u isc-dhcp-relay --no-pager -n 80 || true"

echo "=== RESULT ==="
[ "$errors" -eq 0 ] && echo "[OK] DHCP tests passed" || echo "[FAIL] $errors test(s) failed"
exit "$errors"
