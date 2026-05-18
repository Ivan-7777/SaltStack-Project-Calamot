#!/bin/bash
set -u

WG_MINION=${WG_MINION:-minion-08}
errors=0
ok() { echo "[OK]   $*"; }
fail() { echo "[FAIL] $*"; errors=$((errors + 1)); }
run() { salt "$1" cmd.run "$2" python_shell=True --out=txt --timeout=60 2>/dev/null; }

echo "=== WireGuard server ==="
out=$(run "$WG_MINION" "systemctl is-active wg-quick@wg0 2>/dev/null || true; wg show 2>/dev/null || true; ip addr show wg0 2>/dev/null || true; ss -lunp | grep 51820 || true")
echo "$out"
echo "$out" | grep -q active && ok "wg-quick@wg0 active" || fail "wg-quick@wg0 inactive"
echo "$out" | grep -q 'interface: wg0' && ok "wg0 exists" || fail "wg0 missing"

echo "=== WireGuard config ==="
run "$WG_MINION" "sed -n '1,220p' /etc/wireguard/wg0.conf 2>/dev/null || true"

echo "=== RESULT ==="
[ "$errors" -eq 0 ] && echo "[OK] WireGuard tests passed" || echo "[FAIL] $errors test(s) failed"
exit "$errors"
