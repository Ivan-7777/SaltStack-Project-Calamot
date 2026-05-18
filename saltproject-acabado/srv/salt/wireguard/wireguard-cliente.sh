#!/bin/bash
# wg-client-setup.sh - Setup WireGuard cliente con configuración avanzada

set -e

echo "╔════════════════════════════════════════════════════╗"
echo "║       WireGuard Cliente + Configuración Avanzada   ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# ====== INPUTS DEL USUARIO ======
read -p "🌐 IP pública del servidor: " SERVER_PUBLIC_IP
read -p "🔌 Puerto WireGuard (default 51820): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-51820}
read -p "📍 IP VPN del cliente (ej: 10.66.66.5): " CLIENT_VPN_IP
read -p "💾 Ruta al archivo de clave pública del servidor: " SERVER_KEY_FILE

# ====== VALIDAR ARCHIVO DE CLAVE PÚBLICA ======
while true; do
    if [[ ! -f "$SERVER_KEY_FILE" ]]; then
        echo "❌ Archivo no encontrado: $SERVER_KEY_FILE"
        read -p "Intentar otra ruta? (s/n): " retry
        [[ "$retry" != "s" ]] && exit 1
        read -p "Ruta al archivo de clave pública del servidor: " SERVER_KEY_FILE
        continue
    fi

    # Leer y limpiar la clave
    SERVER_PUBLIC_KEY=$(cat "$SERVER_KEY_FILE" | tr -d '[:space:]')

    # Validar formato base64 de WireGuard (44 caracteres terminando en =)
    if [[ ! "$SERVER_PUBLIC_KEY" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
        echo "⚠️  Advertencia: Formato de clave podría ser incorrecto"
        echo "   Contenido: ${SERVER_PUBLIC_KEY:0:20}..."
        read -p "¿Continuar así? (s/n): " confirm
        [[ "$confirm" != "s" ]] && continue
    fi

    echo "✅ Clave pública cargada correctamente"
    break
done

# ====== REDES QUE IRÁN POR LA VPN ======
echo ""
echo "=== Redes que se redirigirán por el túnel ==="
echo "  La red principal será: $CLIENT_VPN_IP/24"
read -p "¿Agregar redes adicionales? (ej: 192.168.0.0/24): " ADDITIONAL_NETWORKS
# Si el usuario deja vacío, usar solo la subred VPN
if [[ -z "$ADDITIONAL_NETWORKS" ]]; then
    ALLOWED_IPS="${CLIENT_VPN_IP%.*}.0/24"
else
    # Combinar red VPN con redes adicionales
    ALLOWED_IPS="$ADDITIONAL_NETWORKS,$(echo $CLIENT_VPN_IP | sed 's/\.[0-9]*$/\.0\/24/')"
fi

echo "  Redes configuradas: $ALLOWED_IPS"

# ====== GENERAR CLAVES DEL CLIENTE ======
echo ""
echo "🔑 Generando claves criptográficas para el cliente..."
CLIENT_PRIVATE=$(wg genkey)
CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)

echo "   • Clave privada generada ✓"
echo "   • Clave pública generada: ${CLIENT_PUBLIC}"
echo ""

# ====== DETERMINAR INTERFAZ FÍSICA ======
PHYSICAL_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "📡 Interfaz física detectada: $PHYSICAL_IFACE"
echo ""

# ====== CREAR wg0.conf DEL CLIENTE ======
WG_CONF="/etc/wireguard/wg0.conf"
echo "📝 Creando $WG_CONF..."

# Obtener la subnet correcta basada en la IP proporcionada
SUBNET=$(echo $CLIENT_VPN_IP | sed 's/\.[0-9]*$/.0\/24/')

cat > "$WG_CONF" << EOF
[Interface]
Address = ${CLIENT_VPN_IP}/24
PrivateKey = ${CLIENT_PRIVATE}
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_PUBLIC_IP}:${SERVER_PORT}
AllowedIPs = ${ALLOWED_IPS}
PersistentKeepalive = 25
EOF

chmod 600 "$WG_CONF"
echo "✅ Configuración de cliente creada correctamente"

# ====== GENERAR SCRIPT PARA EL SERVIDOR ======
SERVER_SCRIPT="/tmp/add_peer_to_server.sh"
echo ""
echo "📝 Generando script para el servidor..."

# Determinar las redes que el servidor debe enrutar hacia este cliente
SERVER_ALLOWED_IPS="${CLIENT_VPN_IP}/32"

cat > "$SERVER_SCRIPT" << EOF
#!/bin/bash
# ⚠️  EJECUTAR EN EL SERVIDOR ⚠️
# Este script añade el nuevo peer automáticamente

set -e

CLIENT_PUBLIC_KEY="${CLIENT_PUBLIC}"
CLIENT_VPN_IP="${CLIENT_VPN_IP}"
SERVER_SUBNET="${SERVER_SUBNET:-$(echo $CLIENT_VPN_IP | sed 's/\.[0-9]*$/.0\/24/')}"
WG_CONF="/etc/wireguard/wg0.conf"

echo "╔═══════════════════════════════════════════╗"
echo "║         Añadir Peer al Servidor          ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Verificar si el peer ya existe
if grep -q "^PublicKey = \$CLIENT_PUBLIC_KEY\$" "\$WG_CONF" 2>/dev/null; then
    echo "⚠️  Este peer ya está registrado"
    exit 1
fi

# Añadir peer al final del archivo de configuración
cat >> "\$WG_CONF" << PEER_BLOCK

[Peer]
PublicKey = \$CLIENT_PUBLIC_KEY
AllowedIPs = \${CLIENT_VPN_IP}/32
PEER_BLOCK

echo "✅ Peer añadido a \$WG_CONF"

# ✅ VERIFICAR FORWARDING IP
if [[ \$(cat /proc/sys/net/ipv4/ip_forward) -eq 0 ]]; then
    echo "⚠️  Activando IP Forwarding..."
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# ✅ CONFIGURAR NAT SI ES NECESARIO
INTERFACE="\$(ip route | grep default | awk '{print \$5}' | head -n1)"
echo "🔄 Configurar reglas firewall (opcional)..."

iptables -C FORWARD -i wg0 -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i wg0 -j ACCEPT

iptables -C FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

iptables -t nat -C POSTROUTING -s \$SERVER_SUBNET -o \$INTERFACE -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s \$SERVER_SUBNET -o \$INTERFACE -j MASQUERADE

# Recargar WireGuard SIN DETENER el servicio
echo "🔄 Aplicando cambios sin downtime..."
wg syncconf wg0 <(wg-quick strip wg0)

echo ""
echo "✅ ¡Listo! El peer ha sido añadido."
echo ""
echo "ℹ️  Información:"
echo "   • IP Cliente en VPN: \$CLIENT_VPN_IP"
echo "   • Key Pública: \${CLIENT_PUBLIC_KEY:0:20}..."
echo ""
EOF

chmod +x "$SERVER_SCRIPT"
echo "✅ Script del servidor generado: $SERVER_SCRIPT"

# ====== GUARDAR CLAVES DEL CLIENTE LOCALMENTE ======
KEY_BACKUP="/etc/wireguard/client_keys.backup.txt"
cat > "$KEY_BACKUP" << EOF
# Backup de claves del cliente - $(date)
PRIVATE_KEY: ${CLIENT_PRIVATE}
PUBLIC_KEY: ${CLIENT_PUBLIC}
VPN_IP: ${CLIENT_VPN_IP}
EOF

chmod 600 "$KEY_BACKUP"
echo "🔐 Copia de seguridad guardada en: $KEY_BACKUP"

# ====== INSTRUCCIONES Y RESUMEN ======
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                     SETUP COMPLETADO                      ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  📋 INFORMACIÓN DE CONEXIÓN                              ║"
echo "║     • Servidor:      ${SERVER_PUBLIC_IP}:${SERVER_PORT}"
echo "║     • Tu IP VPN:     ${CLIENT_VPN_IP}"
echo "║     • Subnet:        $(echo $CLIENT_VPN_IP | sed 's/\.[0-9]*$/.0\/24/')                "
echo "║     • Clave pub:     ${CLIENT_PUBLIC:0:30}..."
echo "║                                                          ║"
echo "║  📝 REDES REDIRIGIDAS:                                   ║"
echo "║     • ${ALLOWED_IPS}"
echo "║                                                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  ▶️  SIGUIENTES PASOS:                                   ║"
echo "║                                                          ║"
echo "║  1. Copiar script al servidor:                          ║"
echo "║     scp $SERVER_SCRIPT root@${SERVER_PUBLIC_IP}:/tmp/  ║"
echo "║                                                          ║"
echo "║  2. Ejecutar en servidor:                               ║"
echo "║     ssh root@${SERVER_PUBLIC_IP} bash /tmp/add_peer_to_server.sh"
echo "║                                                          ║"
echo "║  3. Levantar túnel en este cliente:                     ║"
echo "║     sudo wg-quick up wg0                                ║"
echo "║                                                          ║"
echo "║  4. Verificar conexión:                                 ║"
echo "║     sudo wg show                                        ║"
echo "║     ping -c 3 $(echo $CLIENT_VPN_IP | sed 's/\.[0-9]*$/\.1/')               "
echo "║                                                          ║"
echo "║  🔧 Si hay problemas de routing, ejecutar:              ║"
echo "║     sudo ip route del $(echo $CLIENT_VPN_IP | sed 's/\.[0-9]*$/\.0\/24/') dev wg0 2>/dev/null; \\"
echo "║     sudo ip route add ${SERVER_PUBLIC_IP}/32 dev ${PHYSICAL_IFACE}"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
