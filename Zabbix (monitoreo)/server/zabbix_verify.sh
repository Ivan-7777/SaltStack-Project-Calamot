#!/bin/bash
# ============================================================
# Script de verificación del Servidor Zabbix
# ============================================================
# Comprueba que el servidor Zabbix está funcionando
# correctamente y que los agentes conectan.
#
# Uso: /usr/local/bin/zabbix_verify.sh [--agents]
# ============================================================

set -uo pipefail

# --- Variables de configuración (desde Salt/Pillar) ---
# Nota: estas variables se renderizan con Jinja al desplegar el archivo
ZABBIX_SERVER="{{ salt['pillar.get']('zabbix:server_ip', '192.168.0.12') }}"
DB_HOST="{{ salt['pillar.get']('zabbix:db_host', '192.168.0.7') }}"
DB_PORT="{{ salt['pillar.get']('zabbix:db_port', '3306') }}"
DB_NAME="{{ salt['pillar.get']('zabbix:db_name', 'zabbix') }}"
DB_USER="{{ salt['pillar.get']('zabbix:db_user', 'zabbix') }}"
DB_PASS="{{ salt['pillar.get']('zabbix:db_pass', 'Z@bb1x_S3rv3r_2026!') }}"

# Colores para terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Funciones de ayuda ---
log_ok()  { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail(){ echo -e "${RED}[FAIL]${NC} $1"; }
log_warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }

# ============================================================
echo "============================================================"
echo "  Verificación del Servidor Zabbix"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

# --- 1. Verificar proceso del servidor ---
echo "--- 1. Proceso del servidor Zabbix ---"
if pgrep -x "zabbix_server" > /dev/null; then
    log_ok "El proceso zabbix_server está en ejecución"
    log_ok "Número de procesos: $(pgrep -c zabbix_server)"
else
    log_fail "El proceso zabbix_server NO está en ejecución"
    echo "  Intentando iniciar: systemctl start zabbix-server"
    systemctl start zabbix-server 2>/dev/null
fi
echo ""

# --- 2. Verificar puerto 10051 ---
echo "--- 2. Puerto de escucha (10051) ---"
if ss -tlnp | grep -q ':10051'; then
    log_ok "El servidor escucha en el puerto 10051"
else
    log_fail "El servidor NO escucha en el puerto 10051"
fi
echo ""

# --- 3. Verificar agente local (puerto 10050) ---
echo "--- 3. Agente local (puerto 10050) ---"
if ss -tlnp | grep -q ':10050'; then
    log_ok "El agente local escucha en el puerto 10050"
else
    log_fail "El agente local NO escucha en el puerto 10050"
fi
echo ""

# --- 4. Verificar Apache (frontend web) ---
echo "--- 4. Frontend web (Apache) ---"
if systemctl is-active --quiet apache2; then
    log_ok "Apache2 está activo"
    # Comprobar que el frontend responde
    HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost/zabbix/ 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "302" ]]; then
        log_ok "Frontend Zabbix responde (HTTP $HTTP_CODE)"
    else
        log_warn "Frontend no responde correctamente (HTTP $HTTP_CODE)"
    fi
else
    log_fail "Apache2 NO está activo"
fi
echo ""

# --- 5. Verificar conexión a MariaDB ---
echo "--- 5. Conexión a MariaDB ---"
if MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -e "USE $DB_NAME;" 2>/dev/null; then
    log_ok "Conexión a la BD '$DB_NAME' correcta en $DB_HOST:$DB_PORT"
else
    log_fail "No se puede conectar a la BD '$DB_NAME' en $DB_HOST:$DB_PORT"
fi
echo ""

# --- 6. Verificar hosts monitorizados ---
echo "--- 6. Hosts monitorizados ---"
HOST_COUNT=$(MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
    -u "$DB_USER" -N -e "SELECT COUNT(*) FROM hosts WHERE status=0;" "$DB_NAME" 2>/dev/null || echo "0")
if [[ "$HOST_COUNT" -gt 0 ]]; then
    log_ok "Hay $HOST_COUNT host(s) monitorizados"
    MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
        -u "$DB_USER" -e "SELECT host, status FROM hosts WHERE status=0;" "$DB_NAME" 2>/dev/null
else
    log_warn "No hay hosts monitorizados todavía"
fi
echo ""

# --- 7. Verificar triggers activos ---
echo "--- 7. Triggers activos ---"
TRIGGER_COUNT=$(MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
    -u "$DB_USER" -N -e "SELECT COUNT(*) FROM triggers WHERE status=0;" "$DB_NAME" 2>/dev/null || echo "0")
if [[ "$TRIGGER_COUNT" -gt 0 ]]; then
    log_ok "Hay $TRIGGER_COUNT trigger(s) configurados"
else
    log_warn "No hay triggers configurados"
fi
echo ""

# --- 8. Verificar últimos datos recibidos ---
echo "--- 8. Últimos datos recibidos ---"
LATEST=$(MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
    -u "$DB_USER" -N -e "SELECT FROM_UNIXTIME(MAX(clock)) FROM history LIMIT 1;" "$DB_NAME" 2>/dev/null || echo "N/A")
if [[ "$LATEST" != "N/A" && -n "$LATEST" ]]; then
    log_ok "Último dato recibido: $LATEST"
else
    log_warn "No se han recibido datos todavía"
fi
echo ""

# --- 9. Comprobar agentes conectados (si se pasa --agents) ---
if [[ "${1:-}" == "--agents" ]]; then
    echo "--- 9. Estado de agentes conectados ---"
    MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
        -u "$DB_USER" \
        -e "SELECT h.host AS Agente,
                   CASE WHEN h.available=1 THEN 'Disponible'
                        WHEN h.available=2 THEN 'No disponible'
                        ELSE 'Desconocido' END AS Estado,
                   FROM_UNIXTIME(h.lastaccess) AS Ultimo_Acceso
            FROM hosts h
            WHERE h.status=0
            ORDER BY h.host;" "$DB_NAME" 2>/dev/null
    echo ""
fi

# --- 10. Verificar configuración de descubrimiento automático ---
echo "--- 10. Descubrimiento automático de servicios ---"
if [[ -f "/usr/local/bin/zabbix_discover_services.sh" ]]; then
    log_ok "Script de descubrimiento automático instalado"
    
    # Comprobar configuración de auto-discovery
    if [[ -f "/etc/zabbix/zabbix_agentd.d/auto_discovery.conf" ]]; then
        log_ok "Configuración de descubrimiento automático presente"
        
        # Contar UserParameters configurados
        PARAM_COUNT=$(grep -c "^UserParameter=" /etc/zabbix/zabbix_agentd.d/auto_discovery.conf 2>/dev/null || echo "0")
        log_ok "UserParameters de descubrimiento: $PARAM_COUNT"
    else
        log_warn "Configuración de descubrimiento automático no encontrada"
    fi
else
    log_warn "Script de descubrimiento automático no instalado"
fi
echo ""

# --- 11. Verificar servicios descubiertos automáticamente ---
echo "--- 11. Servicios descubiertos automáticamente ---"
AUTO_HOST_COUNT=$(MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
    -u "$DB_USER" -N -e "SELECT COUNT(*) FROM hosts WHERE host LIKE 'auto_%' AND status=0;" "$DB_NAME" 2>/dev/null || echo "0")

if [[ "$AUTO_HOST_COUNT" -gt 0 ]]; then
    log_ok "Hay $AUTO_HOST_COUNT host(s) descubiertos automáticamente"
    MYSQL_PWD="$DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" \
        -u "$DB_USER" -e "SELECT host, name FROM hosts WHERE host LIKE 'auto_%' AND status=0;" "$DB_NAME" 2>/dev/null
else
    log_warn "No hay hosts descubiertos automáticamente todavía"
    log_info "Ejecute: /usr/local/bin/zabbix_discover_services.sh para escanear la red"
fi
echo ""

# ============================================================
echo "============================================================"
echo "  Verificación completada"
echo "============================================================"
echo ""
echo "Para acceder a la interfaz web:"
echo "  http://{{ salt['pillar.get']('zabbix:server_ip', '192.168.0.12') }}/zabbix/"
echo "  Usuario por defecto: Admin"
echo "  Contraseña por defecto: zabbix"
echo ""
