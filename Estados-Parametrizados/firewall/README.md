# Firewall Salt State

Este estado de **SaltStack** configura un firewall completo con **nftables**, **interfaces de red**, **sysctl**, y un **relay DHCP** para la DMZ/LAN. Está diseñado para ser **parametrizable mediante pillars**, lo que permite cambiar IPs, interfaces o servidores DHCP sin modificar el estado.

---

## Estructura del estado

### `firewall/init.sls`

1. **Interfaces de red**  
   - Gestionadas mediante Jinja (`interfaces.jinja`).  
   - Configura LAN, DMZ y WAN según los valores definidos en el pillar `firewall`.  
   - Permite que las IPs y máscaras sean parametrizadas para cualquier entorno.

2. **Firewall con nftables**  
   - Fichero `/etc/nftables.conf` generado desde Jinja (`nftables.conf.jinja`).  
   - Reglas de filtrado de tráfico completamente parametrizables mediante pillar.  
   - Incluye la activación del servicio y su habilitación para el arranque.

3. **Sysctl**  
   - Configuración de parámetros del kernel en `/etc/sysctl.conf`.

4. **ISC DHCP Relay**  
   - Instala el paquete `isc-dhcp-relay`.  
   - Configura el fichero `/etc/default/isc-dhcp-relay` desde `isc-dhcp-relay.jinja`.  
   - Parametrización:  
     - `INTERFACES` se obtiene automáticamente de `firewall.lan.interface` y `firewall.dmz.interface`.  
     - `SERVERS` se obtiene de `dhcp.server_ip`.  
   - Reinicia y habilita el servicio.

5. **Reinicio final**  
   - Se realiza un `reboot` para aplicar completamente los cambios de red.

---

## Ejemplo de pillar

```yaml
firewall:
  wan:
    ip: 10.1.105.200
    mask: 24
    gateway: 10.1.105.1
    interface: enp0s3
  lan:
    ip: 192.168.0.1
    mask: 24
    interface: enp0s8
  dmz:
    ip: 10.2.0.1
    mask: 16
    interface: enp0s9

dhcp:
  server_ip: 192.168.0.50



Todas las configuraciones del estado (interfaces, SERVERS del relay, opciones DHCP) se obtienen de los pillars.

Para modificar IPs, rangos o interfaces solo es necesario actualizar el pillar, no el estado.

Archivos Jinja

interfaces.jinja → genera /etc/network/interfaces basado en las secciones firewall y dhcp del pillar.

nftables.conf.jinja → define las reglas de firewall usando los datos del pillar.

isc-dhcp-relay.jinja → genera el fichero de configuración del relay según interfaces LAN/DMZ y el servidor DHCP.

Uso

Definir los valores en el pillar firewall y dhcp.

Ejecutar el estado sobre el minion correspondiente:

salt <minion> state.apply firewall

El minion aplicará los cambios, configurará nftables, interfaces, DHCP relay y reiniciará si es necesario.

Notas

Parametrización completa: todos los datos de red y DHCP se leen desde el pillar, lo que permite desplegar la misma configuración en entornos diferentes sin tocar el código del estado.

Reinicio final: se realiza para garantizar que las nuevas interfaces y reglas de red se apliquen correctamente.
