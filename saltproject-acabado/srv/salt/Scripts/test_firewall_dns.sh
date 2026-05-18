#!/bin/bash
set -u

LAN_MINION=${LAN_MINION:-minion-02}
DMZ_MINION=${DMZ_MINION:-minion-04}
FW_MINION=${FW_MINION:-minion-05}
LAN_DNS=${LAN_DNS:-192.168.0.1}
DMZ_DNS=${DMZ_DNS:-192.168.1.1}

errors=0
ok() { echo "[OK]   $*"; }
fail() { echo "[FAIL] $*"; errors=$((errors + 1)); }
run() { salt "$1" cmd.run "$2" python_shell=True --out=txt --timeout=30 2>/dev/null; }
has_ip() { grep -Eq '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; }

echo "=== DNS LAN -> firewall ==="
out=$(run "$LAN_MINION" "dig @$LAN_DNS google.com +short 2>/dev/null || true")
echo "$out"
echo "$out" | has_ip && ok "LAN resolves external DNS" || fail "LAN DNS failed"

echo "=== DNS DMZ -> firewall ==="
out=$(run "$DMZ_MINION" "dig @$DMZ_DNS google.com +short 2>/dev/null || true")
echo "$out"
echo "$out" | has_ip && ok "DMZ resolves external DNS" || fail "DMZ DNS failed"

echo "=== Firewall services ==="
out=$(run "$FW_MINION" "systemctl is-active nftables named 2>/dev/null || true")
echo "$out"
echo "$out" | grep -q active && ok "firewall/DNS services visible" || fail "firewall/DNS services not active"

echo "=== LAN internet ==="
out=$(run "$LAN_MINION" "ping -c 2 -W 3 8.8.8.8 >/dev/null && echo OK || echo FAIL")
echo "$out"
echo "$out" | grep -q OK && ok "LAN can ping internet" || fail "LAN internet ping failed"

echo "=== LAN -> DMZ ping ==="
out=$(run "$LAN_MINION" "ping -c 2 -W 3 192.168.1.10 >/dev/null && echo OK || echo FAIL")
echo "$out"
echo "$out" | grep -q OK && ok "LAN can ping DMZ" || fail "LAN to DMZ ping failed"

echo "=== DMZ -> LAN should be restricted ==="
out=$(run "$DMZ_MINION" "ping -c 2 -W 3 192.168.0.10 >/dev/null && echo UNEXPECTED_OK || echo BLOCKED")
echo "$out"
echo "$out" | grep -q BLOCKED && ok "DMZ cannot initiate ping to LAN" || fail "DMZ reached LAN unexpectedly"

echo "=== nftables summary ==="
run "$FW_MINION" "nft list ruleset | sed -n '1,220p'"

echo "=== RESULT ==="
[ "$errors" -eq 0 ] && echo "[OK] firewall/DNS tests passed" || echo "[FAIL] $errors test(s) failed"
exit "$errors"
