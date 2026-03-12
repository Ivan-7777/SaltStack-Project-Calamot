# DHCP Salt State

Este estado de Salt configura un servidor **DHCP** en un sistema Linux utilizando `dnsmasq`. Está diseñado para ser totalmente **parametrizable mediante Pillars**, de manera que los rangos de IP, interfaces y opciones de red se puedan cambiar sin modificar los archivos de estado.  

En entornos donde existe una **DMZ**, las solicitudes de DHCP que lleguen a la DMZ pueden ser **reenviadas mediante el firewall como DHCP relay**, por lo que el servidor DHCP solo debe gestionar sus propias subredes (LAN/DMZ) y el firewall se encarga de redirigir las solicitudes externas.  

---

## Contenido del Estado

- **Instalación de `dnsmasq`**  
  Se asegura de que el paquete `dnsmasq` esté instalado.

- **Configuración de DHCP y DNS**  
  El archivo principal `/etc/dnsmasq.conf` se genera a partir de un **template Jinja** (`dhcp.conf.jinja`) que utiliza los datos definidos en el **pillar** `dhcp`.  
  Esto incluye:
  - Interfaces sobre las que el servidor dará IPs.
  - Rangos de direcciones IP (`range_start`, `range_end`).
  - Máscaras de red y tiempo de concesión (`lease_time`).
  - Opciones globales como gateway y servidores DNS.
  - Logging opcional.

- **Configuración de interfaces de red**  
  Se genera el archivo `/etc/network/interfaces` a partir de un template Jinja (`interfaces.jinja`) que puede usar la misma información de los pilares para configurar las IPs del propio servidor DHCP.

- **Habilitación del servicio**  
  El servicio `dnsmasq` se activa para iniciar automáticamente al arranque:
  ```bash
  systemctl enable dnsmasq.service

Reinicio del sistema
El estado puede reiniciar la máquina para aplicar cambios de interfaces:

reboot
Pilares Requeridos

Ejemplo de pillar para este estado:

dhcp:
  log: true
  server_ip: 192.168.0.50
  interfaces:
    lan:
      name: enp0s3
      range_start: 192.168.0.50
      range_end: 192.168.0.200
      netmask: 255.255.255.0
      lease_time: 24h
    dmz:
      name: enp0s9
      range_start: 10.2.0.50
      range_end: 10.2.255.200
      netmask: 255.255.0.0
      lease_time: 24h
  options:
    gateway:
      0: 192.168.0.1
      1: 10.2.0.1
    dns:
      0: 192.168.0.20

Nota: La IP del propio servidor DHCP se define en dhcp:server_ip y puede ser utilizada en el template interfaces.jinja para asignarla al host.

Archivos Generados

/etc/dnsmasq.conf → generado desde dhcp.conf.jinja según el pillar.

/etc/network/interfaces → generado desde interfaces.jinja usando la IP del servidor y datos de subred.

Características

Permite múltiples interfaces/subredes (LAN y DMZ).

Logging opcional activable mediante dhcp:log.

Integración con pilares para gateways, DNS y reservas estáticas si se desea.

Compatible con entornos donde la DMZ recibe DHCP a través del firewall como relay.
