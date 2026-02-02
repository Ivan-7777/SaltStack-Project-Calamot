#Script para el cliente Wireguard.
#Hay que instalar wireguard en el cliente previamente para proceder con este script
#Genera los archivos de configuración necesarios y al final un script para el servidor VPN para añadir a la configuración el nuevo cliente.
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

# 3. Generar claves
echo "Generando claves..."
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

# 4. Crear archivo .conf para el CLIENTE
CLIENT_FILENAME="wg0.conf"
# Permitimos tráfico a la VPN (10.66.66.x) y a la LAN (192.168.0.x)
ALLOWED_IPS="10.66.66.0/24, 192.168.0.0/24"

cat > "$CLIENT_FILENAME" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $CLIENT_IP/32
ListenPort = 51820
[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_ENDPOINT:51820
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# 5. Crear script simple para el SERVIDOR
SERVER_SCRIPT="cliente.sh"

# Este bloque crea el script que correrás en el servidor.
# Solo añade texto al final del archivo wg0.conf
cat > "$SERVER_SCRIPT" <<EOF
#!/bin/bash
# Script para ejecutar en el SERVIDOR VPN

WG_CONF="/etc/wireguard/wg0.conf"

if [ ! -f "\$WG_CONF" ]; then
    echo "Error: No encuentro \$WG_CONF"
    exit 1
fi

# Añadimos el bloque Peer al final del archivo
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
