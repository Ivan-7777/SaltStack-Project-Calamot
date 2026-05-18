#!/bin/bash
set -u

WP_MINION=${WP_MINION:-}
WP_URL=${WP_URL:-}
errors=0
ok() { echo "[OK]   $*"; }
fail() { echo "[FAIL] $*"; errors=$((errors + 1)); }
warn() { echo "[WARN] $*"; }
run() { salt "$1" cmd.run "$2" python_shell=True --out=txt --timeout=60 2>/dev/null; }
pillar() {
    local key=$1
    salt "$WP_MINION" pillar.get "$key" --out=json --static 2>/dev/null | python3 -c '
import json, sys
minion = sys.argv[1]
try:
    data = json.load(sys.stdin).get(minion)
except Exception:
    data = None
if isinstance(data, (list, tuple)):
    print(" ".join(str(x) for x in data))
elif isinstance(data, dict):
    print(json.dumps(data, sort_keys=True))
elif data is not None:
    print(data)
' "$WP_MINION"
}

autodetect_wp_minion() {
    salt "*" pillar.get service_mapping --out=json --static 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
for minion, mapping in sorted(data.items()):
    if not isinstance(mapping, dict):
        continue
    states = mapping.get(minion) or []
    if any(state in ("webserver", "wordpress") for state in states):
        print(minion)
        break
'
}

pillar_json_value() {
    local minion=$1
    local key=$2
    salt "$minion" pillar.get "$key" --out=json --static 2>/dev/null | python3 -c '
import json, sys
minion = sys.argv[1]
try:
    data = json.load(sys.stdin).get(minion)
except Exception:
    data = None
if isinstance(data, dict):
    print(data.get("network", {}).get("address") or "")
elif data is not None:
    print(data)
' "$minion"
}

if [ -z "$WP_MINION" ]; then
    WP_MINION=$(autodetect_wp_minion)
fi
WP_MINION=${WP_MINION:-minion-02}

if [ -z "$WP_URL" ]; then
    wp_addr=$(pillar_json_value "$WP_MINION" web-server)
    WP_URL="http://${wp_addr:-192.168.0.10}/"
fi

echo "=== Pillar precheck ==="
web_pillar=$(pillar web-server)
wp_pillar=$(pillar wordpress)
mapping=$(pillar "service_mapping:$WP_MINION")
echo "WP_MINION=$WP_MINION"
echo "service_mapping:$WP_MINION"
echo "$mapping"
if [ -z "$(printf '%s%s' "$web_pillar" "$wp_pillar" | tr -d '[:space:]')" ]; then
    warn "web-server/wordpress pillar is missing for $WP_MINION; continuing with runtime checks."
fi
if [ -n "$(printf '%s' "$mapping" | tr -d '[:space:]')" ] && ! echo "$mapping" | grep -Eq 'wordpress|webserver'; then
    fail "$WP_MINION is not mapped to wordpress/webserver in service_mapping."
elif [ -z "$(printf '%s' "$mapping" | tr -d '[:space:]')" ]; then
    warn "service_mapping:$WP_MINION is empty; continuing with runtime checks."
fi

echo "=== Apache/PHP/WordPress status ==="
out=$(run "$WP_MINION" 'echo APACHE_STATUS=$(systemctl is-active apache2 2>/dev/null || true); echo MARIADB_STATUS=$(systemctl is-active mariadb 2>/dev/null || true); apache2ctl -M 2>/dev/null | grep php || true; apache2ctl -S 2>&1 | sed -n "1,40p"; test -f /var/www/user/server/html/wp-load.php && echo WP_LOAD_OK || echo WP_LOAD_MISSING')
echo "$out"
echo "$out" | grep -q 'APACHE_STATUS=active' && ok "apache active" || fail "apache inactive"
echo "$out" | grep -q 'php_module' && ok "Apache PHP module loaded" || fail "Apache PHP module missing"
echo "$out" | grep -q 'server.es.conf' && ok "WordPress vhost enabled" || fail "WordPress vhost not enabled"
echo "$out" | grep -q 'WP_LOAD_OK' && ok "WordPress files exist" || fail "WordPress files missing"

echo "=== HTTP check $WP_URL ==="
out=$(run "$WP_MINION" "rm -f /tmp/wp-test.html; if curl -s -L --max-time 10 -D /tmp/wp-headers.txt '$WP_URL' -o /tmp/wp-test.html; then cat /tmp/wp-headers.txt; head -40 /tmp/wp-test.html; else echo CURL_FAILED; fi")
echo "$out"
if echo "$out" | grep -q 'CURL_FAILED'; then
    fail "HTTP request failed"
else
    echo "$out" | grep -q 'Apache2 Debian Default Page' && fail "Apache default page is still served" || ok "Apache default page not served"
    echo "$out" | grep -qi 'WordPress\|Lab SaltStack\|wp-' && ok "WordPress content detected" || fail "WordPress content not detected"
    echo "$out" | grep -q '<?php' && fail "PHP is being served as text" || ok "PHP is executed"
fi

echo "=== RESULT ==="
[ "$errors" -eq 0 ] && echo "[OK] WordPress tests passed" || echo "[FAIL] $errors test(s) failed"
exit "$errors"
