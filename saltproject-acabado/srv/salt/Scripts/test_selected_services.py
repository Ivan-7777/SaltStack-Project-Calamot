#!/usr/bin/env python3
"""Check only the services selected by the generated Salt pillar.

Run from the Salt master:
  /srv/salt/Scripts/test_selected_services.py
"""

import json
import subprocess
import sys

MINIONS = ["minion-02", "minion-04", "minion-05", "minion-08"]

STATE_SERVICES = {
    "BDD": ["mariadb"],
    "dhcp": ["dnsmasq"],
    "dns": ["named"],
    "firewall": ["nftables"],
    "proxy": ["nginx"],
    "wordpress": ["apache2"],
    "webserver": ["apache2"],
    "wireguard": ["wg-quick@wg0", "nftables"],
    "zabbix.server": ["zabbix-server", "apache2"],
    "zabbix.agent": ["zabbix-agent"],
    "restic.server": ["restic-rest-server"],
}

SPECIAL_CHECKS = {
    "restic.client": [
        ("restic binary", "command -v restic >/dev/null"),
        ("restic backup script", "test -x /usr/local/bin/restic_backup.sh"),
        ("restic cron", "crontab -l 2>/dev/null | grep -q restic_backup.sh"),
    ],
    "pkica": [
        ("PKI CA directory", "test -d /etc/pki/ca"),
        ("PKI CA certificate", "test -f /etc/pki/ca/certs/ca.cert.pem"),
    ],
}


def run(args, check=False):
    proc = subprocess.run(args, text=True, capture_output=True)
    if check and proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip())
    return proc


def salt_json(target, fun, arg):
    proc = run(["salt", target, fun, arg, "--out=json", "--static"], check=True)
    return json.loads(proc.stdout[proc.stdout.find("{"):])


def salt_cmd(minion, cmd):
    proc = run(["salt", minion, "cmd.run", cmd, "python_shell=True", "--out=json", "--static"])
    try:
        data = json.loads(proc.stdout[proc.stdout.find("{"):])
        return proc.returncode, str(data.get(minion, "")).strip()
    except Exception:
        return proc.returncode, (proc.stdout + proc.stderr).strip()


def ok(msg):
    print(f"[OK]   {msg}")


def fail(msg):
    print(f"[FAIL] {msg}")


def info(msg):
    print(f"\n=== {msg} ===")


def selected_services(minion, enabled):
    mapping = salt_json(minion, "pillar.get", f"service_mapping:{minion}").get(minion) or []
    services = []
    checks = []
    for state in mapping:
        for service in STATE_SERVICES.get(state, []):
            if service not in services:
                services.append(service)
        checks.extend(SPECIAL_CHECKS.get(state, []))

    if "firewall" in mapping and (enabled.get("dhcp") or enabled.get("proxy")):
        if "isc-dhcp-relay" not in services:
            services.append("isc-dhcp-relay")

    return mapping, services, checks


def main():
    failures = 0
    enabled = salt_json(MINIONS[0], "pillar.get", "enabled_services").get(MINIONS[0]) or {}

    for minion in MINIONS:
        mapping, services, checks = selected_services(minion, enabled)
        info(f"{minion} states={mapping or 'none'}")

        if not mapping:
            ok("No selected states for this minion")
            continue

        for service in services:
            _, out = salt_cmd(minion, f"systemctl is-active {service} 2>/dev/null || true")
            if out == "active":
                ok(f"{minion}: {service} active")
            else:
                failures += 1
                fail(f"{minion}: {service} is {out or 'unknown'}")

        for label, cmd in checks:
            ret, out = salt_cmd(minion, f"{cmd}; echo RET=$?")
            if "RET=0" in out:
                ok(f"{minion}: {label}")
            else:
                failures += 1
                fail(f"{minion}: {label} failed")

    print("\n=== RESULT ===")
    if failures:
        print(f"[FAIL] {failures} check(s) failed")
        return 1
    print("[OK] all selected service checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
