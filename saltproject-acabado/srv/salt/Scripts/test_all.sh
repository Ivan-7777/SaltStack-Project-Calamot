#!/bin/bash
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
errors=0

run_test() {
    local name=$1
    local script=$2
    echo
    echo "########################################################################"
    echo "### $name"
    echo "########################################################################"
    if "$script"; then
        echo "[OK] $name"
    else
        echo "[FAIL] $name"
        errors=$((errors + 1))
    fi
}

run_test "Selected services" "$DIR/test_selected_services.py"
run_test "Firewall and DNS" "$DIR/test_firewall_dns.sh"
run_test "DHCP" "$DIR/test_dhcp.sh"
run_test "WordPress" "$DIR/test_wordpress.sh"
run_test "Zabbix" "$DIR/test_zabbix.sh"
run_test "Restic" "$DIR/test_restic.sh"
run_test "WireGuard" "$DIR/test_wireguard.sh"

echo
echo "########################################################################"
if [ "$errors" -eq 0 ]; then
    echo "[OK] all test suites passed"
else
    echo "[FAIL] $errors test suite(s) failed"
fi
exit "$errors"
