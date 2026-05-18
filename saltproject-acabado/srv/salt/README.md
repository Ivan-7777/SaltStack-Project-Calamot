# Estados de Salt Stack - Proyecto SaltStack

Este directorio contiene los estados de Salt utilizados para gestionar y automatizar la infraestructura del proyecto. Cada subdirectorio representa un servicio o configuración específica.

## Resumen de Estados

| Estado | Descripción |
| :--- | :--- |
| **[BDD](./BDD)** | Servidor de base de datos MariaDB. Configura DBs para Zabbix, Logs y WordPress. |
| **[dhcp](./dhcp)** | Servidor DHCP dinámico mediante dnsmasq. |
| **[dns](./dns)** | Servidor de nombres Bind9 para resolución interna. |
| **[firewall](./firewall)** | Router y cortafuegos con nftables y DHCP relay. |
| **[pkica](./pkica)** | Autoridad de Certificación interna para gestión de certificados SSL. |
| **[proxy](./proxy)** | Proxy inverso con Nginx para asegurar servicios internos. |
| **[webserver](./webserver)** | Configuración base del sistema y servidor web Apache/PHP. |
| **[wireguard](./wireguard)** | VPN segura para acceso remoto a la infraestructura. |
| **[wordpress](./wordpress)** | Instalación automatizada de WordPress mediante WP-CLI. |

## Cómo usar estos estados

Estos estados están diseñados para ser aplicados de forma modular. Se recomienda revisar el archivo `top.sls` en este mismo directorio para ver cómo se asignan estos estados a los diferentes nodos (minions) de la red.

Para aplicar todos los estados asignados a una máquina:
```bash
salt 'nombre-del-minion' state.apply
```

Para aplicar un estado específico:
```bash
salt 'nombre-del-minion' state.apply nombre-del-estado
```

---
*Documentación generada para facilitar la comprensión de la infraestructura automatizada.*
