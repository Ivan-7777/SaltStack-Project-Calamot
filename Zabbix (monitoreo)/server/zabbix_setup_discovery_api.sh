#!/bin/bash
# ============================================================
# Script de auto-configuración de Zabbix vía API
# ============================================================
# Este script utiliza la API de Zabbix para configurar
# automáticamente:
#   1. Reglas de descubrimiento de red (Discovery rules)
#   2. Acciones automáticas para hosts descubiertos
#   3. Plantillas de monitorización genéricas
#
# Uso: /usr/local/bin/zabbix_setup_discovery_api.sh
# ============================================================

set -uo pipefail

# --- Configuración ---
ZABBIX_URL="{{ salt['pillar.get']('zabbix:server_ip', '192.168.0.11') }}"
ZABBIX_USER="{{ salt['pillar.get']('zabbix:api_user', 'Admin') }}"
ZABBIX_PASS="{{ salt['pillar.get']('zabbix:api_pass', 'zabbix') }}"
ZABBIX_API="http://${ZABBIX_URL}/zabbix/api_jsonrpc.php"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Función para hacer llamadas a la API
api_call() {
    local method="$1"
    local params="$2"
    
    curl -sf -X POST \
        -H "Content-Type: application/json-rpc" \
        -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"$method\",
            \"params\": $params,
            \"id\": 1,
            \"auth\": \"$AUTH_TOKEN\"
        }" "$ZABBIX_API" 2>/dev/null
}

# ============================================================
echo "============================================================"
echo "  Configuración automática de Zabbix vía API"
echo "  Servidor: $ZABBIX_URL"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

# --- 1. Autenticación ---
log_info "Autenticando en la API de Zabbix..."

AUTH_RESPONSE=$(curl -sf -X POST \
    -H "Content-Type: application/json-rpc" \
    -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"user.login\",
        \"params\": {
            \"user\": \"$ZABBIX_USER\",
            \"password\": \"$ZABBIX_PASS\"
        },
        \"id\": 1
    }" "$ZABBIX_API" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$AUTH_RESPONSE" ]; then
    AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$AUTH_TOKEN" ]; then
        log_ok "Autenticación exitosa"
    else
        log_fail "No se pudo obtener token de autenticación"
        log_info "Respuesta: $AUTH_RESPONSE"
        exit 1
    fi
else
    log_fail "Error de conexión con la API de Zabbix"
    exit 1
fi

echo ""

# ============================================================
# --- 2. Crear grupo de hosts "Auto-Discovered" ---
# ============================================================
log_info "Verificando/creando grupo de hosts 'Auto-Discovered'..."

# Comprobar si ya existe
GROUP_CHECK=$(api_call "hostgroup.get" "{
    \"output\": \"extend\",
    \"filter\": {
        \"name\": \"Auto-Discovered Services\"
    }
}")

GROUP_ID=$(echo "$GROUP_CHECK" | grep -o '"groupid":"[0-9]*"' | cut -d'"' -f4)

if [ -z "$GROUP_ID" ]; then
    # Crear grupo
    CREATE_GROUP=$(api_call "hostgroup.create" "{
        \"name\": \"Auto-Discovered Services\"
    }")
    
    GROUP_ID=$(echo "$CREATE_GROUP" | grep -o '"groupids\":\[\"[0-9]*\"\]' | grep -o '[0-9]*')
    
    if [ -n "$GROUP_ID" ]; then
        log_ok "Grupo creado con ID: $GROUP_ID"
    else
        log_fail "Error al crear grupo"
    fi
else
    log_ok "Grupo ya existe con ID: $GROUP_ID"
fi

echo ""

# ============================================================
# --- 3. Crear plantilla "Template Auto-Discovered Services" ---
# ============================================================
log_info "Verificando/creando plantilla de monitorización..."

TEMPLATE_CHECK=$(api_call "template.get" "{
    \"output\": \"extend\",
    \"filter\": {
        \"host\": \"Template Auto-Discovered Services\"
    }
}")

TEMPLATE_ID=$(echo "$TEMPLATE_CHECK" | grep -o '"templateid":"[0-9]*"' | cut -d'"' -f4)

if [ -z "$TEMPLATE_ID" ]; then
    log_warn "La plantilla debe crearse manualmente en la interfaz web"
    log_info "Nombre: Template Auto-Discovered Services"
    log_info "Grupo: Templates"
    echo ""
fi

# ============================================================
# --- 4. Configurar reglas de descubrimiento de red ---
# ============================================================
log_info "Verificando reglas de descubrimiento de red..."

# Obtener la red desde Pillar
DISCOVERY_NETWORK="{{ salt['pillar.get']('zabbix:discovery_network', '192.168.0.0/24') }}"

log_info "Red configurada para descubrimiento: $DISCOVERY_NETWORK"
echo ""

# ============================================================
# --- 5. Crear acción de auto-registration ---
# ============================================================
log_info "Configurando acción de auto-registro..."

ACTION_CHECK=$(api_call "action.get" "{
    \"output\": \"extend\",
    \"filter\": {
        \"name\": \"Auto-register discovered hosts\"
    }
}")

ACTION_ID=$(echo "$ACTION_CHECK" | grep -o '"actionid":"[0-9]*"' | cut -d'"' -f4)

if [ -z "$ACTION_ID" ]; then
    # Crear acción de auto-registro
    CREATE_ACTION=$(api_call "action.create" "{
        \"name\": \"Auto-register discovered hosts\",
        \"eventsource\": 0,
        \"status\": 0,
        \"esc_period\": \"0\",
        \"def_shortdata\": \"Auto-registered: {HOST.NAME}\",
        \"def_longdata\": \"Host {HOST.NAME} was automatically discovered and registered.\",
        \"filter\": {
            \"evaltype\": 0,
            \"conditions\": [
                {
                    \"conditiontype\": 23,
                    \"operator\": 0,
                    \"value\": \"zabbix-agent\"
                }
            ]
        },
        \"operations\": [
            {
                \"operationtype\": 1,
                \"opmessage\": {
                    \"default_msg\": 1,
                    \"mediatypeid\": \"0\",
                    \"subject\": \"Auto-registered: {HOST.NAME}\",
                    \"message\": \"Host automatically discovered and registered.\"
                },
                \"opmessage_grp\": []
            },
            {
                \"operationtype\": 4,
                \"opcommand\": {
                    \"type\": \"-1\",
                    \"scriptid\": \"0\"
                }
            },
            {
                \"operationtype\": 6,
                \"opgroup\": {
                    \"groupid\": \"$GROUP_ID\"
                }
            },
            {
                \"operationtype\": 7,
                \"optemplate\": {
                    \"templateid\": \"$TEMPLATE_ID\"
                }
            }
        ]
    }")
    
    if [ $? -eq 0 ] && [ -n "$CREATE_ACTION" ]; then
        log_ok "Acción de auto-registro creada"
    else
        log_warn "No se pudo crear la acción automáticamente"
        log_info "Deberá configurarse manualmente en: Configuration → Actions → Event source: Auto-registration"
    fi
else
    log_ok "Acción de auto-registro ya configurada (ID: $ACTION_ID)"
fi

echo ""

# ============================================================
# --- 6. Mostrar configuración necesaria para Discovery ---
# ============================================================
echo "============================================================"
echo "  Configuración manual requerida"
echo "============================================================"
echo ""
log_info "Para habilitar el descubrimiento automático completo,"
log_info "siga estos pasos en la interfaz web:"
echo ""
echo "  1. Configuration → Discovery → Local network"
echo "     - IP range: $DISCOVERY_NETWORK"
echo "     - Delay: 1h (o menor según necesidad)"
echo "     - Checks: Añadir las siguientes comprobaciones:"
echo "       * SSH server (port 22)"
echo "       * HTTP server (port 80)"
echo "       * HTTPS server (port 443)"
echo "       * MySQL server (port 3306)"
echo "       * FTP server (port 21)"
echo "       * SMTP server (port 25)"
echo "       * DNS server (port 53)"
echo "       * Zabbix agent (port 10050)"
echo ""
echo "  2. Configuration → Actions → Event source: Discovery"
echo "     - Create action con las siguientes operaciones:"
echo "       * Add host"
echo "       * Add to group: Auto-Discovered Services"
echo "       * Link to template: Template OS-Linux by Zabbix agent"
echo ""
echo "  3. Configuration → Actions → Event source: Auto-registration"
echo "     - Create action con filtro: Host metadata contains 'zabbix-agent'"
echo "     - Operaciones:"
echo "       * Add host"
echo "       * Add to group: Auto-Discovered Services"
echo "       * Link to template: Template Auto-Discovered Services"
echo ""

# ============================================================
# --- 7. Resumen ---
# ============================================================
echo "============================================================"
echo "  Resumen de configuración"
echo "============================================================"
echo ""
echo "  Grupo de hosts: Auto-Discovered Services (ID: $GROUP_ID)"
echo "  Red de descubrimiento: $DISCOVERY_NETWORK"
echo "  URL del servidor: http://${ZABBIX_URL}/zabbix/"
echo ""
log_ok "Configuración API completada"
echo ""
echo "============================================================"
