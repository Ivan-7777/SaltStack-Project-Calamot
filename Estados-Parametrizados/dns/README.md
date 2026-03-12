# Estado Salt `dns`

Este estado de **Salt** despliega y configura un **servidor DNS Bind9** en una máquina Debian 13, aprovechando información centralizada del **pillar** para configurar automáticamente zonas, hosts y opciones de red.

---

## 📂 Estructura del estado


/srv/salt/dns/
├── init.sls # State principal
└── files/
├── named.conf.options.j2 # Opciones globales de Bind9
├── named.conf.local.j2 # Declaración de zonas
└── zones/
├── db.internal.j2 # Zona interna LAN/DMZ/VPN
└── db.web-server.j2 # Zona para web-server y hosts importantes


---

## ⚙️ Funcionamiento

El estado realiza las siguientes acciones:

1. **Instalación de Bind9**  
   - Instala el paquete `bind9` en la máquina objetivo.

2. **Creación del directorio de zonas**  
   - Crea `/etc/bind/zones` para almacenar todos los archivos de zona.

3. **Copiado de archivos de configuración**  
   - `named.conf.options.j2`: define opciones globales de Bind9 (recursión, listen-on, forwarders, DNSSEC).  
   - `named.conf.local.j2`: declara las zonas a gestionar (internas y del web-server).  
   - `/zones/*.j2`: archivos de zona que definen registros A, NS, MX y otros hosts importantes.

4. **Procesamiento de plantillas Jinja**  
   - Todos los archivos son plantillas **Jinja**, y sus valores se rellenan dinámicamente desde el **pillar**.  
   - Esto permite que Bind9 refleje automáticamente la configuración de **LAN, DMZ, VPN, web-server y PKI**.

5. **Servicio Bind9**  
   - Habilita y arranca el servicio `bind9`.  
   - Se recarga automáticamente si cambia cualquier archivo de configuración o zona.

---

## 🌐 Integración con el pillar

El estado aprovecha el **pillar central** para:

- `firewall` → IPs de LAN y DMZ para `listen-on` y configuración de registros NS internos.  
- `wireguard` → IP del túnel VPN para que los clientes VPN puedan resolver nombres.  
- `dhcp` → IPs de DNS que se usan como forwarders y registros de hosts fijos.  
- `web-server` → IPs y dominio del servidor web para generar registros A y MX.  
- `pkica` → información de la PKI (opcional) para certificados o registros internos.

> Ejemplo de integración:  
> - El registro `ns1` apunta a `firewall.lan.ip`.  
> - `www` y `mail` apuntan a la IP de `web-server`.  
> - `vpn` apunta a la IP del túnel WireGuard.  

---

## 📑 Archivos de configuración generados

1. **`/etc/bind/named.conf.options`**  
   Configura las opciones globales del servidor DNS: recursión, listen-on, forwarders y DNSSEC.

2. **`/etc/bind/named.conf.local`**  
   Declara las zonas internas (`internal.local`) y del web-server (`server.es`).

3. **Zonas**  
   - `/etc/bind/zones/db.internal` → registros para LAN, DMZ y VPN.  
   - `/etc/bind/zones/db.web-server` → registros para el dominio principal y servicios importantes.

Todos los archivos son **dinámicos** y se actualizan según el **pillar**.

---

## 🧩 Beneficios del estado

- **Automatización total**: no requiere modificar manualmente Bind9.  
- **Integración con red y servicios**: LAN, DMZ, VPN, DHCP y web-server sincronizados.  
- **Escalable**: añadir nuevas IPs o hosts solo requiere actualizar el pillar.  
- **Seguro**: escucha solo en interfaces definidas y forwarders configurables.

---

## 🚀 Cómo usarlo

1. Definir o actualizar el **pillar** con la información de red, DHCP, web-server y PKI.  
2. Aplicar el estado en la máquina objetivo:

```bash
salt '<minion>' state.apply dns

Comprobar que Bind9 está activo:

systemctl status bind9

Verificar que las zonas y registros se hayan generado correctamente en /etc/bind/zones.

⚠️ Notas

Las plantillas Jinja dependen de la estructura de tu pillar. Cambios en los nombres de claves o rutas pueden romper la generación automática.

Los rangos DHCP dinámicos no se reflejan automáticamente en Bind9; solo se configuran hosts fijos o subredes.

Puedes extender las plantillas para soportar DNSSEC o registros adicionales usando la información de pkica.
