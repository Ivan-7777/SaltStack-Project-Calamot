#!/bin/bash
# ============================================================
# Script de Backup del Cliente Restic
# Se ejecuta en las máquinas cliente (PRUEBA) para enviar
# backups al repositorio central Restic mediante REST API.
# Los resultados se registran en la base de datos MariaDB central.
# ============================================================

# NO usar set -e para poder manejar errores manualmente y
# asegurar que siempre se haga el logging del resultado.
set -uo pipefail

# Se cargan RESTIC_REPOSITORY y RESTIC_PASSWORD
source /root/.restic_env || true

# --- Configuración ---
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="/var/log/restic_backup.log"

# Conexión a MySQL/MariaDB (variables renderizadas por Salt/Jinja)
MYSQL_USER="{{ pillar['restic']['mysql']['user'] }}"
MYSQL_PASS="{{ pillar['restic']['mysql']['password'] }}"
MYSQL_HOST="{{ pillar['restic']['mysql']['host'] }}"
MYSQL_DB="{{ pillar['restic']['mysql']['database'] }}"

# Rutas de backup (renderizadas por Jinja desde pillar).
# Acepta tanto lista YAML como cadena separada por comas para ser resistente
# a formularios antiguos.
{% set raw_backup_paths = salt['pillar.get']('restic:backup_paths', ['/etc']) %}
{% if raw_backup_paths is string %}
BACKUP_PATHS="{{ raw_backup_paths }}"
{% else %}
BACKUP_PATHS="{% for path in raw_backup_paths %}{{ path }}{% if not loop.last %},{% endif %}{% endfor %}"
{% endif %}

RESULT=0
STATUS="success"

# Función de logging por consola y archivo
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Función para registrar el resultado en la base de datos
# Se usa archivo de configuración temporal para evitar que la
# contraseña aparezca en el listado de procesos (ps)
log_to_db() {
    log "Registrando resultado en la base de datos..."

    # Crear archivo temporal de credenciales MySQL
    MYSQL_CNF=$(mktemp /tmp/.restic_mysql.XXXXXX)
    cat > "$MYSQL_CNF" <<EOF
[client]
user=${MYSQL_USER}
password=${MYSQL_PASS}
host=${MYSQL_HOST}
database=${MYSQL_DB}
EOF
    chmod 600 "$MYSQL_CNF"

    QUERY="INSERT INTO machine_backups (hostname, backup_path, status, execution_time) VALUES ('${HOSTNAME}', '${RESTIC_REPOSITORY}', '${STATUS}', '${DATE}');"

    if mysql --defaults-extra-file="$MYSQL_CNF" -e "$QUERY" >> "$LOGFILE" 2>&1; then
        log "Registro en base de datos: OK"
    else
        log "ADVERTENCIA: No se pudo registrar en la base de datos"
    fi

    # Limpiar archivo temporal de credenciales
    rm -f "$MYSQL_CNF"
}

log "=== Iniciando backup de Restic ==="
log "Hostname: ${HOSTNAME}"
log "Repositorio: ${RESTIC_REPOSITORY}"

# --- 1. Validar conectividad al servidor REST ---
# Extraer el host y puerto del repositorio REST para comprobar conexión
# El servidor REST devuelve 405 para GET, pero eso confirma que está vivo
REST_SERVER=$(echo "${RESTIC_REPOSITORY}" | sed -n 's|rest:http://\([^/]*\).*|\1|p')
if [ -n "$REST_SERVER" ]; then
    log "Comprobando conectividad al servidor REST: ${REST_SERVER}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://${REST_SERVER}/" 2>/dev/null)
    if [ "$HTTP_CODE" != "405" ] && [ "$HTTP_CODE" != "200" ]; then
        log "ERROR: No se puede conectar al servidor REST ${REST_SERVER} (código HTTP: ${HTTP_CODE})"
        STATUS="fail"
        RESULT=1
        log_to_db
        exit 1
    fi
    log "Conectividad al servidor REST: OK (HTTP ${HTTP_CODE})"
else
    log "ADVERTENCIA: No se detectó un servidor REST en la URL del repositorio"
fi

# --- 2. Validar que los directorios existen antes de hacer backup ---
VALID_PATHS=()
VALID_COUNT=0
IFS=',' read -r -a BACKUP_PATH_ARRAY <<< "${BACKUP_PATHS}"
for raw_dir in "${BACKUP_PATH_ARRAY[@]}"; do
    dir="$(echo "$raw_dir" | xargs)"
    if [ -d "$dir" ]; then
        VALID_PATHS+=("${dir}")
        VALID_COUNT=$((VALID_COUNT + 1))
        log "Directorio válido para backup: ${dir}"
    else
        log "ADVERTENCIA: El directorio $dir no existe, se omite del backup"
    fi
done

if [ "$VALID_COUNT" -eq 0 ]; then
    log "ERROR: No hay directorios válidos para hacer backup"
    STATUS="fail"
    RESULT=1
    log_to_db
    exit 1
fi

# --- 3. Ejecutar backup con Restic ---
log "Ejecutando: restic backup ${VALID_PATHS[*]}"
restic backup "${VALID_PATHS[@]}" >> "$LOGFILE" 2>&1
RESULT=$?

if [ $RESULT -eq 0 ]; then
    STATUS="success"
    log "Backup completado exitosamente"
else
    STATUS="fail"
    log "ERROR: El backup falló con código de salida ${RESULT}"
fi

# --- 4. Registrar resultado en MariaDB ---
log_to_db

log "=== Backup de Restic completado (estado: ${STATUS}) ==="
echo "" >> "$LOGFILE"

exit ${RESULT}
