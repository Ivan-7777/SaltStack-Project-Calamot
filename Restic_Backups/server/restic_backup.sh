#!/bin/bash
# ============================================================
# Script de Mantenimiento del Servidor Restic
# Se ejecuta en el servidor de backups (MINIONBACKUP) para
# mantenimiento del repositorio: prune, check y logging a BD
# ============================================================

# Se carga la variable RESTIC_REPOSITORY y RESTIC_PASSWORD
# desde el archivo de entorno. Se usa "|| true" para que el
# script no falle si algo va mal en el source.
source /root/.restic_env || true

LOGFILE="/var/log/restic_maintenance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# Conexión a MySQL/MariaDB (variables renderizadas por Salt/Jinja)
MYSQL_USER="{{ pillar['mysql']['user'] }}"
MYSQL_PASS="{{ pillar['mysql']['password'] }}"
MYSQL_HOST="{{ pillar['mysql']['host'] }}"
MYSQL_DB="{{ pillar['mysql']['database'] }}"

# Función de logging por consola y archivo
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

log "=== Iniciando mantenimiento de Restic ==="

# --- 1. Verificación de integridad del repositorio ---
log "Ejecutando verificación del repositorio..."
CHECK_STATUS="success"
if ! restic check --repo "${RESTIC_REPOSITORY:-/backups/restic}" >> "$LOGFILE" 2>&1; then
    CHECK_STATUS="fail"
    log "ERROR: ¡La verificación del repositorio FALLÓ!"
else
    log "Verificación del repositorio: OK"
fi

# --- 2. Purga de snapshots antiguos ---
# Política: conservar los últimos 7 diarios y 4 semanales
log "Ejecutando purge de snapshots antiguos..."
PRUNE_STATUS="success"
if ! restic forget --keep-daily 7 --keep-weekly 4 --prune \
    --repo "${RESTIC_REPOSITORY:-/backups/restic}" >> "$LOGFILE" 2>&1; then
    PRUNE_STATUS="fail"
    log "ERROR: ¡La operación de purge FALLÓ!"
else
    log "Purge: OK"
fi

# --- 3. Registrar resultados en MariaDB ---
# Se usa un archivo de configuración temporal para evitar
# que la contraseña aparezca en el listado de procesos (ps)
log "Registrando resultados en la base de datos..."
MYSQL_CNF=$(mktemp /tmp/.restic_mysql.XXXXXX)
cat > "$MYSQL_CNF" <<EOF
[client]
user=${MYSQL_USER}
password=${MYSQL_PASS}
host=${MYSQL_HOST}
database=${MYSQL_DB}
EOF
chmod 600 "$MYSQL_CNF"

QUERY="INSERT INTO machine_backups (hostname, backup_path, status, execution_time) VALUES ('${HOSTNAME}-maintenance', '${RESTIC_REPOSITORY:-/backups/restic}', '${CHECK_STATUS}', '${DATE}');"

if mysql --defaults-extra-file="$MYSQL_CNF" -e "$QUERY" 2>&1 | tee -a "$LOGFILE"; then
    log "Registro en base de datos: OK"
else
    log "ERROR: ¡No se pudo registrar en la base de datos!"
fi

# Limpiar archivo temporal de credenciales
rm -f "$MYSQL_CNF"

log "=== Mantenimiento de Restic completado ==="
echo "" >> "$LOGFILE"

exit 0
