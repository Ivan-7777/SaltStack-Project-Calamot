#!/bin/bash
# ============================================================
# Script de verificación del Agente Zabbix
# ============================================================
# Comprueba que el agente Zabbix está funcionando y que
# puede comunicarse con el servidor.
#
# Uso: /usr/local/bin/zabbix_agent_verify.sh
# ============================================================

set -uo pipefail

# --- Variables de configuración (desde Salt/Pillar) ---
# Nota: estas variables se renderizan con Jinja al desplegar el archivo
ZABBIX_SERVER="{{ salt['pillar.get']('zabbix:server_ip', '192.168.0.12') }}"
ZABBIX_PORT="{{ salt['pillar.get']('zabbix:agent_port', '10050') }}"
AGENT_HOSTNAME="{{ salt['pillar.get']('zabbix:agent_hostname', salt['grains.get']('host', 'zabbix-agent')) }}"

# Colores para terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_ok()  { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail(){ echo -e "${RED}[FAIL]${NC} $1"; }
log_warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }

# ============================================================
echo "============================================================"
echo "  Verificación del Agente Zabbix"
echo "  Host: $AGENT_HOSTNAME"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

# --- 1. Verificar proceso del agente ---
echo "--- 1. Proceso del agente Zabbix ---"
if pgrep -x "zabbix_agentd" > /dev/null; then
    log_ok "El proceso zabbix_agentd está en ejecución"
    log_ok "Número de procesos: $(pgrep -c zabbix_agentd)"
else
    log_fail "El proceso zabbix_agentd NO está en ejecución"
    echo "  Intentando iniciar: systemctl start zabbix-agent"
    systemctl start zabbix-agent 2>/dev/null
fi
echo ""

# --- 2. Verificar puerto de escucha ---
echo "--- 2. Puerto de escucha ($ZABBIX_PORT) ---"
if ss -tlnp | grep -q ":${ZABBIX_PORT}"; then
    log_ok "El agente escucha en el puerto $ZABBIX_PORT"
else
    log_fail "El agente NO escucha en el puerto $ZABBIX_PORT"
fi
echo ""

# --- 3. Verificar conectividad con el servidor ---
echo "--- 3. Conectividad con el servidor ($ZABBIX_SERVER) ---"
if nc -z -w 3 "$ZABBIX_SERVER" 10051 2>/dev/null; then
    log_ok "Se puede alcanzar el servidor Zabbix en $ZABBIX_SERVER:10051"
else
    log_warn "No se puede alcanzar el servidor en $ZABBIX_SERVER:10051"
    echo "  (Puede ser normal si el agente usa modo pasivo)"
fi
echo ""

# --- 4. Verificar configuración ---
echo "--- 4. Configuración del agente ---"
CONF_FILE="/etc/zabbix/zabbix_agentd.conf"
if [[ -f "$CONF_FILE" ]]; then
    log_ok "Archivo de configuración encontrado"

    # Extraer valores importantes
    CONF_SERVER=$(grep -E "^Server=" "$CONF_FILE" | head -1 | cut -d= -f2)
    CONF_HOSTNAME=$(grep -E "^Hostname=" "$CONF_FILE" | head -1 | cut -d= -f2)

    if [[ "$CONF_SERVER" == "$ZABBIX_SERVER" ]]; then
        log_ok "Server configurado correctamente: $CONF_SERVER"
    else
        log_fail "Server incorrecto: $CONF_SERVER (esperado: $ZABBIX_SERVER)"
    fi

    if [[ "$CONF_HOSTNAME" == "$AGENT_HOSTNAME" ]]; then
        log_ok "Hostname configurado correctamente: $CONF_HOSTNAME"
    else
        log_warn "Hostname: '$CONF_HOSTNAME' (configurado: '$AGENT_HOSTNAME')"
    fi
else
    log_fail "Archivo de configuración NO encontrado: $CONF_FILE"
fi
echo ""

# --- 5. Verificar comprobaciones personalizadas ---
echo "--- 5. Comprobaciones personalizadas ---"
MONITORING_CONF="/etc/zabbix/zabbix_agentd.d/monitoring.conf"
if [[ -f "$MONITORING_CONF" ]]; then
    PARAM_COUNT=$(grep -c "UserParameter=" "$MONITORING_CONF" 2>/dev/null || echo "0")
    log_ok "$PARAM_COUNT UserParameter(s) configurados"
    echo "  Claves configuradas:"
    grep "UserParameter=" "$MONITORING_CONF" | sed 's/^/    /'
else
    log_warn "No se encontraron UserParameter personalizados"
fi
echo ""

# --- 6. Probar comprobaciones locales ---
echo "--- 6. Prueba de comprobaciones locales ---"

# Estado SSH
SSH_STATUS=$(systemctl is-active sshd 2>/dev/null || echo "inactive")
if [[ "$SSH_STATUS" == "active" ]]; then
    log_ok "Servicio SSH: activo"
else
    log_warn "Servicio SSH: $SSH_STATUS"
fi

# Carga de CPU
LOAD=$(cat /proc/loadavg | awk '{print $1}')
log_ok "Carga de CPU (1 min): $LOAD"

# Uso de memoria
MEM_INFO=$(free | grep Mem | awk '{printf "%.1f%% usado (%.0f MB / %.0f MB)", ($3/$2)*100, $3/1024, $2/1024}')
log_ok "Memoria: $MEM_INFO"

# Uso de disco raíz
DISK_INFO=$(df / | tail -1 | awk '{printf "%s usado en %s", $5, $6}')
log_ok "Disco raíz: $DISK_INFO"

# Uptime
UPTIME_SEC=$(cat /proc/uptime | awk '{printf "%d", $1}')
UPTIME_DAYS=$((UPTIME_SEC / 86400))
UPTIME_HOURS=$(( (UPTIME_SEC % 86400) / 3600 ))
log_ok "Tiempo activo: ${UPTIME_DAYS}d ${UPTIME_HOURS}h"
echo ""

# ============================================================
echo "============================================================"
echo "  Verificación completada"
echo "============================================================"
echo ""
echo "Si todo está correcto, el servidor Zabbix debería poder"
echo "recibir datos de este agente en unos minutos."
echo ""
echo "Para verificar desde el servidor:"
echo "  zabbix_get -s {{ salt['pillar.get']('zabbix:agent_hostname', salt['grains.get']('host', 'zabbix-agent')) }} -p {{ salt['pillar.get']('zabbix:agent_port', '10050') }} -k system.ping"
echo ""
