#!/bin/bash

source /root/.restic_env

HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Ejecutar backup
restic backup /etc /home /var/www
RESULT=$?

if [ $RESULT -eq 0 ]; then
    STATUS="success"
else
    STATUS="fail"
fi

# Enviar a BDD
mysql -u saltlogger -pPASSWORD -h 192.168.0.10 -D salt_logs -e "
INSERT INTO machine_backups (hostname, backup_path, status, execution_time)
VALUES ('$HOSTNAME', 'restic_repo', '$STATUS', '$DATE');
"
