# Estado: Firewall

Este estado transforma una máquina en un enrutador y cortafuegos avanzado para proteger la red.

## ¿Qué hace este estado?

1.  **Configuración de Red**: Configura las interfaces de red (WAN, LAN, DMZ, etc.) mediante plantillas, asegurando que cada segmento de red tenga la IP y máscara correctas.
2.  **Seguridad (nftables)**: Instala y configura `nftables`, un sistema de filtrado de paquetes moderno. Aplica reglas de firewall dinámicas (NAT, redirección de puertos, bloqueo de accesos no autorizados) basadas en los Pilares.
3.  **Enrutamiento**: Habilita el reenvío de paquetes IP (`IP forwarding`) a nivel de kernel, permitiendo que el tráfico fluya entre las diferentes redes de forma controlada.
4.  **Relay DHCP**: Instala y configura un agente de retransmisión DHCP (`isc-dhcp-relay`). Esto permite que los clientes en redes separadas puedan obtener su dirección IP desde el servidor DHCP central.

## Advertencia
*   La modificación de interfaces de red puede interrumpir la conexión SSH momentáneamente. Se recomienda aplicar estos cambios con precaución o teniendo acceso alternativo a la consola.
