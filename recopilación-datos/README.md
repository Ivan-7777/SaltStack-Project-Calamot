# Gestión de Pillars Modulares en SaltStack

## 📌 Descripción

Este proyecto implementa un sistema de generación dinámica de **Pillars en SaltStack** a partir de un formulario web.  
La principal mejora consiste en **dividir los pilares en múltiples archivos `.sls`**, en lugar de usar un único fichero monolítico.

---

# 🧱 Estructura del sistema

Cada empresa tiene su propio directorio:


/srv/pillar/customers/empresa/
├── wireguard.sls
├── firewall.sls
├── dhcp.sls
├── web-server.sls
├── pkica.sls
├── dns.sls
└── top.sls


---

# ⚙️ ¿Cómo funciona?

## 1. Formulario web

El usuario selecciona los servicios:
- WireGuard
- Firewall
- DHCP
- Web Server
- PKI CA
- DNS

Y rellena sus configuraciones.

---

## 2. Procesamiento (`recibir.php`)

El backend:

1. Crea el directorio de la empresa  
2. Detecta los servicios seleccionados  
3. Genera **un fichero `.sls` por servicio**  
4. Genera un `top.sls` con los módulos necesarios  

---

## 3. Generación de pilares

Cada archivo `.sls` contiene únicamente su bloque:

### Ejemplo `wireguard.sls`
```yaml
wireguard:
  port: 51830
  address: 10.66.66.1/24
  static_lan_ip: 192.168.0.10/24
  wan_interface: enp0s3
Ejemplo firewall.sls
firewall:
  wan:
    ip: 10.1.105.200
    mask: 24
    gateway: 10.1.105.1
4. top.sls

Se genera automáticamente:

base:
  '*':
    - customers.empresa.wireguard
    - customers.empresa.firewall
    - customers.empresa.dhcp

Este archivo indica a Salt qué pilares debe cargar.

🧠 ¿Por qué separar los pilares?
❌ Problema del enfoque monolítico

Antes:

pillar.sls (gigante)

Problemas:

⏳ Renderizado lento (Jinja + YAML)
🔥 Mayor consumo de CPU en el master
🧩 Difícil mantenimiento
🐛 Más propenso a errores
🔄 Cada cambio recompila TODO
✅ Ventajas del enfoque modular
1. ⚡ Rendimiento

Salt compila múltiples archivos pequeños más rápido que uno grande.

2. 🧩 Modularidad

Cada servicio es independiente:

puedes modificar dns sin tocar firewall
menor riesgo de romper otras partes
3. 🔍 Debug sencillo

Errores localizados:

fallo en firewall.sls → no afecta al resto
4. 📈 Escalabilidad

Permite crecer sin degradar rendimiento:

múltiples empresas
múltiples servicios
múltiples minions
5. 🔄 Flexibilidad

Puedes cargar solo lo necesario:

por minion
por rol
por entorno
⚠️ Consideraciones importantes
1. Namespace correcto

Cada fichero debe tener su clave raíz:

wireguard:
firewall:
dhcp:

❌ Incorrecto:

port: 51830
2. top.sls global

Salt NO carga automáticamente los top.sls dentro de subdirectorios.

Debes asegurarte de que tu /srv/pillar/top.sls principal incluye los módulos:

base:
  '*':
    - customers.empresa.wireguard
3. Consistencia de nombres

Ejemplo importante:

Formulario: web
Pilar: web-server

Debe mapearse correctamente en PHP.

🚀 Flujo completo
Usuario → Formulario
        ↓
recibir.php
        ↓
Genera:
  /srv/pillar/customers/empresa/*.sls
        ↓
Salt Master compila pillars
        ↓
Estados usan los datos
📊 Comparativa
Enfoque	Rendimiento	Mantenimiento	Escalabilidad
Monolítico	❌ Malo	❌ Difícil	❌ Limitado
Modular (.sls)	✅ Alto	✅ Fácil	✅ Excelente
🧠 Conclusión

Separar los pilares en múltiples archivos .sls:

es una buena práctica estándar
mejora significativamente el rendimiento
facilita el mantenimiento
permite escalar el sistema correctamente
