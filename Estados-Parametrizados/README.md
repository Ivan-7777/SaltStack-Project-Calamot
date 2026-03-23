# Uso de Pilares en el Proyecto Salt

## 📌 ¿Qué es un pilar en Salt?

Un **pilar** (pillar) es un conjunto de datos específicos de configuración que se envían **desde el Master a los Minions** de forma segura. Se usa para:

- Parametrizar estados (`.sls`) sin modificar el código del estado.
- Mantener información sensible como contraseñas, claves, IPs o certificados.
- Facilitar la reutilización de estados entre distintos clientes o entornos.

Los pilares se evalúan **en el master** y se entregan a los minions que lo necesiten.

---

## 🗂 Estructura de los pilares en este proyecto

Actualmente los pilares se organizan así:


/srv/pillar/
├─ top.sls
└─ customers/
└─ empresa/
├─ webserver.sls
├─ firewall.sls
├─ dhcp.sls
├─ pkica.sls
└─ wireguard.sls


### 1. `top.sls`

El archivo **top.sls** indica **qué pilares se aplican a qué minions**. Por ejemplo:

```yaml
base:
  'minion':
    - customers.empresa.webserver
    - customers.empresa.firewall
    - customers.empresa.dhcp
    - customers.empresa.pkica
    - customers.empresa.wireguard

Esto significa que los minions con ID que empiece por GRA recibirán todos los pilares de la empresa.

2. Pilares individuales

Cada SLS contiene los datos específicos de un servicio. Esto permite mantener los pilares limpios y modulares.

Ejemplos:

webserver.sls

web-server:
  domain: hosting.local
  network:
    address: 192.168.0.20
    mask: 24
  webroot: /var/www/html
  ssh:
    port: 22
    permit_root_login: yes

firewall.sls

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

dhcp.sls

dhcp:
  server_ip: 192.168.0.50
  log: true
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

pkica.sls

pkica:
  base_dir: /etc/pki/ca
  ca:
    country: ES
    state: Madrid
    locality: Madrid
    organization: MiOrg
    organizational_unit: IT
    common_name: mi-ca
    days_valid: 3650
    key_size: 4096
    digest: sha256
  files:
    index: /etc/pki/ca/index.txt
    serial: /etc/pki/ca/serial
    serial_start: 1000
    openssl_config: /etc/pki/ca/openssl.cnf
    private_key: /etc/pki/ca/private/ca.key.pem
    root_cert: /etc/pki/ca/certs/ca.cert.pem

wireguard.sls

wireguard:
  address: 192.168.0.1/24
  listen_port: 51820
  private_key_file: /etc/wireguard/keys/server_private.key
  public_key_file: /etc/wireguard/keys/server_public.key
⚙️ Cómo usar los pilares en los estados

Dentro de los estados .sls puedes acceder a los datos del pilar usando Jinja:

# Crear directorio webroot según pillar
crear_webroot:
  file.directory:
    - name: {{ pillar['web-server']['webroot'] }}
    - user: www-data
    - group: www-data
    - mode: 755
    - makedirs: True

📝 Recomendaciones
No mezclar pilares: Cada SLS debe contener solo los datos necesarios para ese servicio.
Referenciar pilares en los estados: Evita acceder directamente a otros pilares en un Jinja, mejor pasar los datos requeridos desde el minion o el pilar padre.
Actualizar cache de pillar cuando modifiques un pilar:
salt '*' saltutil.refresh_pillar
Usar top.sls correctamente: Asegúrate de que los minions tengan asignados los pilares correspondientes.
Verificación: Puedes inspeccionar lo que recibe un minion con:
salt 'minion_id' pillar.items

Con esta estructura modular, se facilita:

Reutilización de estados
Configuración segura de secretos
Facilidad de mantenimiento y escalabilidad
