# Estado: WireGuard VPN

Este estado configura una red privada virtual (VPN) moderna y rápida basada en el protocolo WireGuard.

## ¿Qué hace este estado?

1.  **Instalación**: Instala las herramientas de WireGuard en el sistema.
2.  **Seguridad Criptográfica**: Genera automáticamente el par de claves (pública y privada) necesarias para el cifrado de la comunicación.
3.  **Configuración de Túnel**: Crea la interfaz virtual `wg0` con su direccionamiento privado y parámetros de red.
4.  **Acceso a Internet**: Configura reglas de `nftables` (Masquerade) para permitir que los clientes conectados a la VPN puedan navegar a través del servidor.
5.  **Herramientas para Usuarios**: Incluye un script (`wireguard-cliente.sh`) que facilita la creación de configuraciones para nuevos clientes (móviles, portátiles, etc.).

## Beneficios
*   Conexión segura desde cualquier lugar del mundo a la red interna.
*   Bajo consumo de recursos y alta velocidad de conexión.
*   Simplicidad en la gestión de clientes.
