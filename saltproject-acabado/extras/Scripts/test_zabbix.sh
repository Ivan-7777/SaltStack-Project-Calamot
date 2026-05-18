#!/bin/bash
set -u

ZBX_MINION=${ZBX_MINION:-minion-08}
DB_MINION=${DB_MINION:-minion-02}
ZBX_URL=${ZBX_URL:-http://192.168.0.151/zabbix/}
errors=0
ok() { echo "[OK]   $*"; }
fail() { echo "[FAIL] $*"; errors=$((errors + 1)); }
run() { salt "$1" cmd.run "$2" python_shell=True --out=txt --timeout=60 2>/dev/null; }

echo "=== Zabbix services/web ==="
out=$(run "$ZBX_MINION" "systemctl is-active zabbix-server apache2 zabbix-agent 2>/dev/null || true; ss -tlnp | grep -E ':(80|10050|10051)\\b' || true; curl -s -L -D- '$ZBX_URL' -o /tmp/zbx-test.html; grep -Eio '<title>[^<]*|Configuration file error|DB type|Sign in|Zabbix' /tmp/zbx-test.html | head -20")
echo "$out"
echo "$out" | grep -q 'Configuration file error\|DB type' && fail "Zabbix frontend config error" || ok "No frontend DB config error"
echo "$out" | grep -q 'HTTP/1.1 200\|HTTP/1.0 200' && ok "Zabbix web returns 200" || fail "Zabbix web did not return 200"

echo "=== Registered hosts ==="
out=$(run "$DB_MINION" "mysql -u zabbix -p'Z@bb1x_2026!' -h 127.0.0.1 zabbix -e \"SELECT h.host,i.ip,i.available,i.error FROM hosts h LEFT JOIN interface i ON h.hostid=i.hostid WHERE h.host LIKE 'minion-%' ORDER BY h.host;\" 2>/dev/null || true")
echo "$out"
for host in minion-02 minion-04 minion-05 minion-08; do
    echo "$out" | grep -q "$host" && ok "$host registered" || fail "$host not registered"
done

echo "=== Agent polling from Zabbix server ==="
for ip in 192.168.0.10 192.168.0.20 192.168.0.1 192.168.0.151; do
    out=$(run "$ZBX_MINION" "zabbix_get -s $ip -p 10050 -k agent.ping 2>&1 || true")
    echo "$ip -> $out"
    echo "$out" | grep -q '1' && ok "$ip agent.ping" || fail "$ip agent.ping failed"
done

echo "=== RESULT ==="
[ "$errors" -eq 0 ] && echo "[OK] Zabbix tests passed" || echo "[FAIL] $errors test(s) failed"
exit "$errors"
