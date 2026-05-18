#!/bin/bash
set -u

RESTIC_SERVER=${RESTIC_SERVER:-minion-08}
DB_MINION=${DB_MINION:-minion-02}
RESTIC_PASSWORD=${RESTIC_PASSWORD:-R3st1c_Backup_2026!}
RUN_BACKUP=${RUN_BACKUP:-0}
errors=0
ok() { echo "[OK]   $*"; }
fail() { echo "[FAIL] $*"; errors=$((errors + 1)); }
run() { salt "$1" cmd.run cmd="$2" python_shell=True --out=txt --timeout=120 2>/dev/null; }

echo "=== Restic server ==="
out=$(run "$RESTIC_SERVER" "systemctl is-active restic-rest-server 2>/dev/null || true; ss -tlnp | grep ':8000' || true; test -f /backups/restic/config && echo REPO_OK || echo REPO_MISSING")
echo "$out"
echo "$out" | grep -q active && ok "restic-rest-server active" || fail "restic-rest-server inactive"
echo "$out" | grep -q REPO_OK && ok "restic repository exists" || fail "restic repository missing"

if [ "$RUN_BACKUP" = "1" ]; then
    echo "=== Running backup scripts on clients ==="
    for minion in minion-02 minion-04 minion-05; do
        out=$(run "$minion" "test -x /usr/local/bin/restic_backup.sh && /usr/local/bin/restic_backup.sh; tail -40 /var/log/restic_backup.log 2>/dev/null || true")
        echo "$out"
        echo "$out" | grep -q 'Backup completado exitosamente' && ok "$minion backup completed" || fail "$minion backup failed"
    done
fi

echo "=== Restic snapshots ==="
out=$(run "$RESTIC_SERVER" "RESTIC_PASSWORD='$RESTIC_PASSWORD' HOME=/root XDG_CACHE_HOME=/root/.cache restic -r /backups/restic snapshots 2>&1 || true")
echo "$out"
echo "$out" | grep -qE '^[^:]*: +[0-9a-f]{8} |[[:space:]]ID[[:space:]]+Time' && ok "snapshot command works" || fail "snapshot command failed"

echo "=== Backup DB log ==="
run "$DB_MINION" "mysql -u saltlogger -p'S@ltL0gg3r_2026!' -h 127.0.0.1 salt_logs -e \"SELECT hostname,backup_path,status,execution_time FROM machine_backups ORDER BY id DESC LIMIT 10;\" 2>/dev/null || true"

echo "=== RESULT ==="
[ "$errors" -eq 0 ] && echo "[OK] Restic tests passed" || echo "[FAIL] $errors test(s) failed"
exit "$errors"
