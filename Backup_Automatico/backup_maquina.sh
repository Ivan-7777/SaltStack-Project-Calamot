#!/bin/bash
# backup_machine.sh
HOST=$(hostname)
DATE=$(date +%F_%H-%M)
DEST="/backups/${HOST}_${DATE}.tar.gz"

# Crear carpeta de backups si no existe
mkdir -p /backups

# Generar backup
tar -czf $DEST /etc /home /var/www

# Comprobar resultado
if [ $? -eq 0 ]; then
  STATUS="SUCCESS"
else
  STATUS="FAIL"
fi

# Guardar registro en la BDD central
mysql -h IP_BDD -u saltlogger -pPASSWORD_SEGURA -D salt_logs -e \
"INSERT INTO machine_backups(hostname, backup_path, status)
 VALUES ('$HOST', '$DEST', '$STATUS');"
