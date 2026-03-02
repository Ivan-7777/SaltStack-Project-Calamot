# 📘 Sistema de Formulario Web para Generación Automática de Pillars (SaltStack)

## 📌 Objetivo del proyecto

Este sistema permite que un cliente (o técnico) introduzca información desde un **formulario web** y que dicha información se traduzca automáticamente en **Pillars de SaltStack**, listos para ser consumidos por distintos **minions** (firewall, VPN, servidores, etc.).

La idea principal es:
- Que **la única parte manual** sea introducir los datos del cliente y de los servicios.
- Que **todo lo demás sea automático**, reproducible y escalable.
- Que los **estados de Salt no contengan lógica de cliente**, sino que dependan **100% de Pillars**.

---

## 🧱 Arquitectura general


Cliente (Web)
│
▼
Formulario HTML
│
▼
recibir.php
│
├── Validación de datos
├── Construcción del Pillar en memoria
├── Escritura de un único SLS por empresa
│
▼
/srv/pillar/customers/<empresa>.sls
│
▼
Salt Master
│
▼
Minions (firewall, vpn, web, etc.)


---

## 📂 Estructura de archivos

### Web (Servidor Apache/Nginx)


/var/www/html/
├── index.html # Formulario principal
└── recibir.php # Procesa el formulario y genera el Pillar


### Salt (Master)


/srv/pillar/
├── top.sls
└── customers/
└── empresa.sls # Pillar generado automáticamente


---

## 🧩 Filosofía de diseño

### 1️⃣ Un solo Pillar por empresa

- Todos los datos introducidos en el formulario se guardan en **un único archivo SLS**.
- El nombre del archivo **es el nombre de la empresa**.
- Ejemplo:
  ```bash
  /srv/pillar/customers/acme.sls

Esto permite:

Compartir datos entre servicios (ej: WireGuard ↔ Firewall).

Evitar duplicidad.

Facilitar la escalabilidad.

2️⃣ Selección de servicios desde el formulario

El formulario comienza con una selección de servicios:

WireGuard

Firewall

(futuro: Nginx, DNS, DHCP, etc.)

Solo los servicios seleccionados:

Aparecen como secciones en el formulario.

Se escriben dentro del Pillar final.

🧾 Estructura del Pillar generado

Ejemplo real de Pillar generado por el sistema:

wireguard:
  port: 45450
  address: 10.50.0.1/24
  static_lan_ip: 192.168.0.10
  wan_interface: enp0s3

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

⚠️ Regla clave:
El formulario define la estructura, el estado solo la consume.

🖥️ El formulario (index.html)
Qué ve el cliente

Campo obligatorio: Nombre de la empresa

Selección de servicios mediante checkboxes

Secciones dinámicas que aparecen según el servicio elegido

Campos específicos según servicio:

WireGuard: puerto, IP de red VPN, IP LAN del servidor, interfaz WAN

Firewall: IP, máscara, gateway e interfaz para WAN, LAN y DMZ

Ejemplos y placeholders para guiar al usuario

Qué NO hace el formulario

No crea reglas de firewall complejas

No ejecuta Salt

No tiene lógica de negocio

👉 Solo recoge datos.

⚙️ Procesamiento (recibir.php)
Responsabilidades

Validar el nombre de empresa

Crear la estructura base del Pillar

Añadir secciones solo si el servicio fue seleccionado

Guardar el Pillar como:

/srv/pillar/customers/<empresa>.sls
Puntos clave

No se usa ningún nombre hardcodeado (cliente, customer, etc.)

El nombre del archivo es exactamente el introducido

Se controla permisos (0644) para que Salt pueda leerlo

El formato YAML es limpio y compatible con Jinja

🔗 Relación con los estados de Salt
Estados simples y limpios

Los estados:

No contienen if para clientes

No contienen lógica de selección de servicios

Solo leen valores del Pillar

Ejemplo real para WireGuard:

[Interface]
Address = {{ pillar['wireguard']['address'] }}
ListenPort = {{ pillar['wireguard']['port'] }}

Si el Pillar no existe → el estado no se aplica (por top.sls).

🔗 Asociación de Pillars a Minions

Para que cada minion reciba solo los datos que necesita del Pillar generado por el formulario, se utiliza el archivo top.sls de SaltStack.

📂 Ubicación del top.sls
/srv/pillar/top.sls
🔹 Sintaxis básica
base:
  'firewall-minion':
    - customers.empresa.firewall

  'vpn-minion':
    - customers.empresa.wireguard

  'web-minion':
    - customers.empresa.nginx
Explicación

firewall-minion

Recibirá únicamente los datos bajo firewall del Pillar customers/empresa.sls.

Puede también leer algunos datos de otros servicios si es necesario, como puertos de WireGuard para NAT.

vpn-minion

Recibe solo wireguard.

Ejecuta los estados de VPN.

web-minion

Recibe solo nginx (o futuros servicios).

🔹 Ejemplo concreto

Supongamos que el Pillar acme.sls contiene:

wireguard:
  port: 51820
  address: 10.66.66.1/24
  static_lan_ip: 192.168.0.10
  wan_interface: enp0s3

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

top.sls para asignarlo:

base:
  'firewall-minion':
    - customers.acme.firewall

  'vpn-minion':
    - customers.acme.wireguard
🔹 Notas importantes

El nombre acme debe coincidir con el nombre de empresa ingresado en el formulario.

Cada minion solo aplica los estados que le corresponden, evitando interferencias.

Puedes usar wildcards o nodegroups para aplicar el mismo Pillar a varios minions si es necesario.
