# SaltStackAPI: Hardening & Automation

Este repositorio contiene la configuración y guía de implementación para desplegar una **API profesional** sobre una infraestructura de **SaltStack**, este proyecto transforma el control de nodos mediante CLI en un sistema de orquestación moderno, seguro y programable.

---

## ¿Qué es la Salt API?
La Salt API (`salt-api`) es un servicio que expone las capacidades de gestión de SaltStack a través de protocolos web estándar. Permite que sistemas externos interactúen con el Master de forma segura y eficiente.

### Pilares de Seguridad Implementados
* **Cifrado TLS (HTTPS):** Comunicación cifrada de extremo a extremo para proteger las órdenes enviadas a la infraestructura.
* **Autenticación eAuth (PAM):** Integración con el sistema de autenticación nativo de Linux para validar identidades.
* **Gestión de Tokens de Sesión:** Una vez autenticado, el usuario recibe un token temporal con caducidad programada (normalmente 12h), minimizando la exposición de credenciales.
* **Interfaz RESTful:** Compatibilidad universal con cualquier lenguaje capaz de realizar peticiones HTTP (Python, JS, Java, etc.).

---

## Configuración del Entorno

### 1. Certificados SSL
Para garantizar el uso de HTTPS, se deben generar certificados en una ruta accesible por el servicio de Salt:

```bash
# Generación de certificado auto-firmado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/salt/pki/api/salt_api.key \
  -out /etc/salt/pki/api/salt_api.crt \
  -subj "/C=ES/ST=Lab/L=Gava/O=SaltProject/CN=saltmaster"
