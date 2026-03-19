#!/bin/bash

# --- Colores ---
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}--- Generador Simple de Cliente WireGuard ---${NC}"

# 1. Comprobación de herramientas
if ! command -v wg &> /dev/null; then
    echo "Error: wireguard-tools no instalado."
    exit 1
fi

# 2. Recolección de datos
read -p "Introduce la IP Pública/Dominio del Servidor: " SERVER_ENDPOINT

# NUEVO: seleccionar puerto
read -p "Introduce el puerto del servidor (por defecto 51820): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-51820}

# Buscamos la clave pública del servidor
while true; do
    read -p "Archivo con la PUBLIC KEY del servidor: " SERVER_PUBKEY_FILE
    if [ -f "$SERVER_PUBKEY_FILE" ]; then
        SERVER_PUBKEY=$(cat "$SERVER_PUBKEY_FILE")
        break
    else
        echo "Archivo no encontrado."
    fi
done

read -p "IP para el nuevo cliente (ej: 10.66.66.5): " CLIENT_IP

# (Opcional pero correcto) Puerto local del cliente
read -p "Puerto local del cliente (por defecto 51820): " CLIENT_PORT
CLIENT_PORT=${CLIENT_PORT:-51820}

# 3. Generar claves
echo "Generando claves..."
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

# 4. Crear archivo .conf para el CLIENTE
CLIENT_FILENAME="wg0.conf"
ALLOWED_IPS="10.66.66.0/24, 192.168.0.0/24"

cat > "$CLIENT_FILENAME" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $CLIENT_IP/32
ListenPort = $CLIENT_PORT

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_ENDPOINT:$SERVER_PORT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# 5. Crear script simple para el SERVIDOR
SERVER_SCRIPT="cliente.sh"

cat > "$SERVER_SCRIPT" <<EOF
#!/bin/bash
# Script para ejecutar en el SERVIDOR VPN

WG_CONF="/etc/wireguard/wg0.conf"

if [ ! -f "\$WG_CONF" ]; then
    echo "Error: No encuentro \$WG_CONF"
    exit 1
fi

cat >> "\$WG_CONF" <<EOL

[Peer]
# Cliente IP: $CLIENT_IP
PublicKey = $PUBLIC_KEY
AllowedIPs = $CLIENT_IP/32
EOL

echo "Se ha añadido el cliente $CLIENT_IP a \$WG_CONF correctamente."
echo "Recuerda reiniciar la interfaz (wg-quick down wg0 && wg-quick up wg0) para aplicar cambios."
EOF

chmod +x "$SERVER_SCRIPT"

# 6. Finalización
echo ""
echo -e "${GREEN}Listo.${NC}"
echo "1. Archivo cliente generado: $CLIENT_FILENAME"
echo "2. Script para el servidor generado: $SERVER_SCRIPT"
