# Estado: DHCP

Este estado configura un servidor DHCP utilizando `dnsmasq` para la asignación automática de direcciones IP en la red.

## ¿Qué hace este estado?

1.  **Instalación**: Instala el paquete `dnsmasq`, que es un servidor ligero para servicios de red.
2.  **Configuración Dinámica**: Genera el archivo de configuración `/etc/dnsmasq.conf` basado en una plantilla que utiliza los datos definidos en el sistema de Pilares (Pillar). Esto permite cambiar rangos de IP, puertas de enlace y servidores DNS de forma centralizada.
3.  **Gestión del Servicio**: Asegura que el servicio `dnsmasq` esté habilitado para iniciarse automáticamente y se reinicie solo cuando haya cambios en la configuración.

## Notas importantes
*   La configuración se aplica de forma segura sin interrumpir la conectividad a menos que sea necesario.
*   Es fundamental que los parámetros de red estén correctamente definidos en los Pilares del cliente.
