# State: Firewall

Este estado gestiona las reglas de red (iptables/nftables/ufw) en cada minion para garantizar el principio de mínimo privilegio.

## Contenido
* **Políticas Globales:** Bloqueo de tráfico entrante por defecto.
* **Reglas Específicas:** Apertura de puertos para servicios (HTTP, SSH, BDD, Wireguard).
* **Persistencia:** Asegura que las reglas se mantengan tras un reinicio.

## Variables
Las reglas se definen dinámicamente consultando los `pillars` de cada nodo.
