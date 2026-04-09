#!/bin/bash

# Carga variables de entorno seguras (repositorio y contraseña)
# Este archivo es generado por Salt y protegido (chmod 600)
source /root/.restic_env

# Obtiene el nombre de la máquina (minion)
HOSTNAME=$(hostname)

# Guarda la fecha actual para el registro en BDD
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Ejecuta el backup con Restic sobre directorios críticos
# Se pueden modificar dinámicamente desde pillar
restic backup /etc /home /var/www

# Guarda el código de salida del comando anterior
# 0 = éxito, cualquier otro valor = error
RESULT=$?

# Evalúa si el backup ha sido exitoso
if [ $RESULT -eq 0 ]; then
    STATUS="success"
else
    STATUS="fail"
fi

# Inserta el resultado del backup en la base de datos central
# Se utiliza el usuario saltlogger con permisos limitados
mysql -u saltlogger -pPASSWORD -h 192.168.0.10 -D salt_logs -e "
INSERT INTO machine_backups (hostname, backup_path, status, execution_time)
VALUES ('$HOSTNAME', 'restic_repo', '$STATUS', '$DATE');
"
