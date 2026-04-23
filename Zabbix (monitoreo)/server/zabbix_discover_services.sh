{% raw %}#!/bin/bash
# ============================================================
# Script de descubrimiento automático de servicios de red
# ============================================================
# Escanea la red local en busca de servicios activos y genera
# un archivo JSON con el formato que Zabbix usa para
# descubrimiento automático (Low-Level Discovery).
#
# Servicios detectados:
#   - HTTP/HTTPS (Web servers)
#   - MySQL/MariaDB (Bases de datos)
#   - PostgreSQL (Bases de datos)
#   - SSH (Acceso remoto)
#   - SFTP/FTP (Transferencia de archivos)
#   - SMTP (Correo)
#   - DNS (Resolución de nombres)
#   - Redis (Cache/BBDD)
#   - MongoDB (Base de datos NoSQL)
#
# Uso: /usr/local/bin/zabbix_discover_services.sh [RED]
# Ejemplo: /usr/local/bin/zabbix_discover_services.sh 192.168.0.0/24
# ============================================================

set -uo pipefail

# --- Configuración ---
# Red a escanear (se puede pasar como argumento o usar default)
NETWORK="${1:-192.168.0.0/24}"

# Timeout para cada comprobación (segundos)
TIMEOUT=2

# Puerto por defecto para cada servicio
declare -A SERVICE_PORTS=(
    ["HTTP"]="80"
    ["HTTPS"]="443"
    ["MySQL"]="3306"
    ["PostgreSQL"]="5432"
    ["SSH"]="22"
    ["SFTP"]="22"
    ["FTP"]="21"
    ["SMTP"]="25"
    ["DNS"]="53"
    ["Redis"]="6379"
    ["MongoDB"]="27017"
)

# Colores para terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funciones auxiliares ---
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Comprobar si un puerto está abierto en un host
check_port() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    
    (echo > /dev/tcp/$host/$port) 2>/dev/null &
    local pid=$!
    sleep "$timeout"
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        return 1  # Timeout = puerto cerrado
    else
        wait "$pid" 2>/dev/null
        return 0  # Éxito = puerto abierto
    fi
}

# Detectar versión/banner de un servicio (si responde)
detect_service_banner() {
    local host="$1"
    local port="$2"
    local service="$3"
    local banner=""
    
    case "$service" in
        "HTTP"|"HTTPS")
            banner=$(curl -sf -m 2 "http${service/#HTTP/s}://$host:$port/" 2>/dev/null | head -1 | tr -d '\0-\37' | cut -c1-100 || echo "unknown")
            ;;
        "MySQL"|"PostgreSQL"|"MongoDB")
            # Solo comprobamos que el puerto responda
            banner="running"
            ;;
        "SSH")
            banner=$(timeout 2 bash -c "echo '' | nc -w 1 $host $port 2>/dev/null" | head -1 || echo "ssh")
            ;;
        *)
            banner="detected"
            ;;
    esac
    
    echo "$banner"
}

# ============================================================
# Main
# ============================================================
echo "============================================================"
echo "  Descubrimiento automático de servicios de red"
echo "  Red: $NETWORK"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

log_info "Iniciando escaneo de la red $NETWORK..."
echo ""

# Extraer rango de IPs de la red (simplificado para /24)
NETWORK_PREFIX=$(echo "$NETWORK" | cut -d'/' -f1 | rev | cut -d'.' -f2- | rev)

if [[ -z "$NETWORK_PREFIX" ]]; then
    log_fail "No se pudo extraer el prefijo de red"
    exit 1
fi

log_info "Escaneando rango: ${NETWORK_PREFIX}.1 - ${NETWORK_PREFIX}.254"
echo ""

# Array para almacenar servicios descubiertos
declare -a DISCOVERED_SERVICES=()

# Escanear cada IP
for i in $(seq 1 254); do
    HOST_IP="${NETWORK_PREFIX}.${i}"
    
    # Ping rápido para ver si el host está vivo
    if ping -c 1 -W 1 "$HOST_IP" >/dev/null 2>&1; then
        log_ok "Host activo: $HOST_IP"
        
        # Comprobar cada servicio
        for SERVICE_NAME in "${!SERVICE_PORTS[@]}"; do
            PORT="${SERVICE_PORTS[$SERVICE_NAME]}"
            
            if check_port "$HOST_IP" "$PORT" "$TIMEOUT"; then
                log_ok "  ✓ $SERVICE_NAME detectado en $HOST_IP:$PORT"
                
                # Detectar banner/información adicional
                BANNER=$(detect_service_banner "$HOST_IP" "$PORT" "$SERVICE_NAME")
                
                # Añadir al array de descubiertos
                # Usamos variables raw para evitar que Jinja interprete {# como comentario
                DISCOVERED_SERVICES+=("{% raw %}{\"{#SERVICE_IP}\":\"$HOST_IP\",\"{#SERVICE_PORT}\":\"$PORT\",\"{#SERVICE_TYPE}\":\"$SERVICE_NAME\",\"{#SERVICE_BANNER}\":\"$BANNER\"}{% endraw %}")
            fi
        done
    fi
done

echo ""
log_info "Escaneo completado. Total servicios encontrados: ${#DISCOVERED_SERVICES[@]}"
echo ""

# ============================================================
# Generar JSON para Zabbix Low-Level Discovery
# ============================================================
echo "Generando JSON para Zabbix LLD (Low-Level Discovery)..."
echo ""

# Crear archivo JSON
JSON_FILE="/tmp/zabbix_discovery_$(date +%Y%m%d_%H%M%S).json"

{
    echo "{"
    echo "  \"data\": ["
    
    for idx in "${!DISCOVERED_SERVICES[@]}"; do
        if [ $idx -lt $((${#DISCOVERED_SERVICES[@]} - 1)) ]; then
            echo "    ${DISCOVERED_SERVICES[$idx]},"
        else
            echo "    ${DISCOVERED_SERVICES[$idx]}"
        fi
    done
    
    echo "  ]"
    echo "}"
} > "$JSON_FILE"

log_ok "JSON guardado en: $JSON_FILE"
echo ""

# Mostrar resumen
echo "============================================================"
echo "  Resumen de descubrimiento"
echo "============================================================"
echo ""

# Contar por tipo
declare -A SERVICE_COUNTS
for service_json in "${DISCOVERED_SERVICES[@]}"; do
    SVC_TYPE=$(echo "$service_json" | grep -o '"{#SERVICE_TYPE}":"[^"]*"' | cut -d'"' -f4)
    SERVICE_COUNTS["$SVC_TYPE"]=$(( ${SERVICE_COUNTS["$SVC_TYPE"]:-0} + 1 ))
done

echo "Servicios encontrados por tipo:"
for svc_type in "${!SERVICE_COUNTS[@]}"; do
    echo "  - $svc_type: ${SERVICE_COUNTS[$svc_type]}"
done

echo ""
echo "Total: ${#DISCOVERED_SERVICES[@]} servicios en ${#SERVICE_COUNTS[@]} categorías"
echo ""

# ============================================================
# Generar SQL para insertar hosts en Zabbix (opcional)
# ============================================================
echo "============================================================"
echo "  Generar configuración para Zabbix"
echo "============================================================"
echo ""

SQL_FILE="/tmp/zabbix_auto_hosts_$(date +%Y%m%d_%H%M%S).sql"

{
    echo "-- Script SQL para crear hosts descubiertos automáticamente"
    echo "-- Generado: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "-- Total hosts: ${#DISCOVERED_SERVICES[@]}"
    echo ""
    echo "USE zabbix;"
    echo ""
    
    # Agrupar por IP para evitar duplicados
    declare -A UNIQUE_HOSTS
    for service_json in "${DISCOVERED_SERVICES[@]}"; do
        IP=$(echo "$service_json" | grep -o '"{#SERVICE_IP}":"[^"]*"' | cut -d'"' -f4)
        UNIQUE_HOSTS["$IP"]=1
    done
    
    for HOST_IP in "${!UNIQUE_HOSTS[@]}"; do
        HOSTNAME="auto_${HOST_IP//\./_}"
        echo "-- Host: $HOST_IP"
        echo "INSERT INTO hosts (host, name, status) VALUES ('$HOSTNAME', '$HOSTNAME', 0) ON DUPLICATE KEY UPDATE host=host;"
        echo ""
    done
} > "$SQL_FILE"

log_ok "SQL guardado en: $SQL_FILE"
echo ""

# ============================================================
# Mostrar JSON completo
# ============================================================
echo "============================================================"
echo "  JSON completo (para importar en Zabbix)"
echo "============================================================"
echo ""
cat "$JSON_FILE"
echo ""
echo "============================================================"
echo "  Descubrimiento completado"
echo "============================================================"
{% endraw %}
