#!/bin/bash
set -euo pipefail

ask() {
    local prompt=$1
    local default=${2:-}
    local value
    if [ -n "$default" ]; then
        read -r -p "$prompt [$default]: " value
        printf '%s' "${value:-$default}"
    else
        read -r -p "$prompt: " value
        printf '%s' "$value"
    fi
}

ask_secret() {
    local prompt=$1
    local value
    read -r -s -p "$prompt: " value
    echo >&2
    printf '%s' "$value"
}

CLIENT_HOST=$(ask "IP del cliente SSH" "${CLIENT_HOST:-10.1.105.6}")
CLIENT_USER=$(ask "Usuario con privilegios en el cliente" "${CLIENT_USER:-root}")
CLIENT_PASS=${CLIENT_PASS:-}
if [ -z "$CLIENT_PASS" ]; then
    CLIENT_PASS=$(ask_secret "Contrasena SSH del cliente")
fi
CLIENT_VPN_IP=$(ask "IP VPN del cliente sin CIDR" "${CLIENT_VPN_IP:-10.66.66.2}")
SERVER_ENDPOINT_IP=$(ask "IP publica/WAN del servidor WireGuard" "${SERVER_ENDPOINT_IP:-10.1.105.151}")
SERVER_VPN_IP=$(ask "IP VPN del servidor WireGuard" "${SERVER_VPN_IP:-10.66.66.1}")
WG_PORT=$(ask "Puerto WireGuard" "${WG_PORT:-51820}")
WG_MINION=$(ask "Minion Salt del servidor WireGuard" "${WG_MINION:-minion-08}")
ALLOWED_IPS=$(ask "AllowedIPs del cliente" "${ALLOWED_IPS:-10.66.66.0/24,192.168.0.0/24}")
WEB_HOST_IP=$(ask "IP WordPress para /etc/hosts del cliente" "${WEB_HOST_IP:-192.168.0.10}")
WEB_HOST_NAME=$(ask "Nombre WordPress para /etc/hosts del cliente" "${WEB_HOST_NAME:-server.es}")

SSH_BASE=(sshpass -p "$CLIENT_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$CLIENT_USER@$CLIENT_HOST")

remote_client() {
    "${SSH_BASE[@]}" "$@"
}

salt_cmd() {
    salt --timeout=30 "$WG_MINION" cmd.run cmd="$1" python_shell=True --out=txt
}

echo "=== Obteniendo clave publica del servidor ==="
if ! salt --timeout=30 "$WG_MINION" test.ping --out=txt | grep -q 'True'; then
    echo "El minion $WG_MINION no responde a Salt. Comprueba salt '$WG_MINION' test.ping." >&2
    exit 1
fi
SERVER_PUB_OUTPUT=$(salt_cmd "cat /etc/wireguard/keys/server_public.key 2>/dev/null || wg show wg0 public-key 2>/dev/null || true")
SERVER_PUB=$(printf '%s\n' "$SERVER_PUB_OUTPUT" | awk -F': ' 'NF>1{print $2} /^[A-Za-z0-9+\/]{43}=/{print $1}' | tail -1 | tr -d " \r")
if [ -z "$SERVER_PUB" ]; then
    echo "No se pudo obtener la clave publica del servidor WireGuard en $WG_MINION" >&2
    echo "Salida recibida:" >&2
    printf '%s\n' "$SERVER_PUB_OUTPUT" >&2
    echo "Aplica primero el estado wireguard en el minion servidor." >&2
    exit 1
fi
echo "Server pubkey: $SERVER_PUB"

echo "=== Instalando wireguard-tools en cliente ==="
remote_client "DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard-tools -qq"

echo "=== Generando claves en cliente ==="
remote_client "umask 077; mkdir -p /etc/wireguard; wg genkey | tee /etc/wireguard/wg_client.key | wg pubkey > /etc/wireguard/wg_client.pub"
CLIENT_PUB=$(remote_client "cat /etc/wireguard/wg_client.pub" | tail -1 | tr -d " \r")
echo "Client pubkey: $CLIENT_PUB"

echo "=== Bajando tunel anterior si existe ==="
remote_client "wg-quick down wg0 2>/dev/null || true"

echo "=== Creando config cliente ==="
remote_client "cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = ${CLIENT_VPN_IP}/24
PrivateKey = \$(cat /etc/wireguard/wg_client.key)

[Peer]
PublicKey = ${SERVER_PUB}
Endpoint = ${SERVER_ENDPOINT_IP}:${WG_PORT}
AllowedIPs = ${ALLOWED_IPS}
PersistentKeepalive = 25
WGEOF
chmod 600 /etc/wireguard/wg0.conf"

echo "=== Configurando resolucion local del WordPress en cliente ==="
remote_client "if [ -n '${WEB_HOST_IP}' ] && [ -n '${WEB_HOST_NAME}' ]; then sed -i '/[[:space:]]${WEB_HOST_NAME}$/d' /etc/hosts; printf '%s %s\n' '${WEB_HOST_IP}' '${WEB_HOST_NAME}' >> /etc/hosts; fi"

echo "=== Registrando peer en servidor ==="
salt_cmd "wg set wg0 peer $CLIENT_PUB allowed-ips ${CLIENT_VPN_IP}/32"
salt_cmd "wg show wg0" >/dev/null

echo "=== Levantando tunel en cliente ==="
remote_client "wg-quick up wg0"

echo "=== Verificando ==="
sleep 2
remote_client "wg show"
echo ""
if remote_client "ping -c 3 -W 2 $SERVER_VPN_IP"; then
    echo "TUNEL OK"
else
    echo "TUNEL FALLO"
    echo "Comprueba que el estado wireguard/firewall permite UDP $WG_PORT hasta $SERVER_ENDPOINT_IP y forwarding entre wg0 y LAN."
    exit 1
fi
