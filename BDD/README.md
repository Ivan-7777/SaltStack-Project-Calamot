# BDD – Base de Datos

## Descripción

Este componente del proyecto corresponde a la **Base de Datos (BDD)** de la infraestructura.  
Su función es almacenar de forma persistente la información necesaria para los servicios desplegados en el entorno, garantizando **disponibilidad, integridad y seguridad de los datos**.

La base de datos forma parte de una infraestructura automatizada y gestionada mediante **SaltStack**, lo que permite una configuración coherente y reproducible.

---

## Objetivos

- Proporcionar almacenamiento persistente para aplicaciones y servicios.
- Garantizar la integridad y consistencia de los datos.
- Facilitar la automatización de la configuración.
- Integrarse de forma segura en la infraestructura.
- Reducir errores derivados de configuraciones manuales.

---

## Enfoque de seguridad

La Base de Datos se despliega siguiendo buenas prácticas de seguridad:

- Acceso restringido únicamente a los servicios autorizados.
- Comunicación segura dentro de la red interna o VPN.
- Protección del sistema mediante estados de seguridad comunes.
- Separación clara de roles dentro de la infraestructura.

No se expone directamente a redes públicas, minimizando la superficie de ataque.

---

## Automatización con SaltStack

La gestión de la Base de Datos se realiza mediante SaltStack, permitiendo:

- Instalación automática del motor de base de datos.
- Configuración coherente entre entornos.
- Aplicación de cambios controlados.
- Reproducibilidad del despliegue.

Esto facilita el mantenimiento y la escalabilidad del sistema.

---

## Integración en la infraestructura

La BDD se integra con otros componentes del proyecto:

- **Firewall**, que controla el acceso a los puertos necesarios.
- **Salt Master**, que gestiona su configuración.
- **WireGuard (VPN)**, que permite comunicación segura con otros nodos.

Esta integración garantiza un entorno estable y seguro.

---

## Notas finales

Este componente forma parte de una infraestructura mayor, donde cada nodo cumple una función específica.  
La Base de Datos está diseñada para ser **segura, automatizada y fácilmente mantenible**, alineada con los objetivos globales del proyecto.
