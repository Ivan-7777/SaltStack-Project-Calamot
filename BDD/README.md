# BDD – Base de Datos

## Descripción

Este componente del proyecto corresponde a la **Base de Datos (BDD)** de la infraestructura.  

La base de datos forma parte de una infraestructura automatizada y gestionada mediante **SaltStack**, lo que permite una configuración coherente y reproducible.

---

## Objetivos

- Proporcionar almacenamiento persistente para aplicaciones y servicios.
- Garantizar la integridad y consistencia de los datos.
- Facilitar la automatización de la configuración.

---

## Enfoque de seguridad

La Base de Datos se despliega siguiendo buenas prácticas de seguridad:

- Acceso restringido únicamente a los servicios autorizados.
- Comunicación segura dentro de la red interna o VPN.
- Protección del sistema mediante estados de seguridad comunes.
- Separación clara de roles dentro de la infraestructura.

No se expone directamente a redes públicas, minimizando la superficie de ataque.

---

## Notas finales

Este componente forma parte de una infraestructura mayor, donde cada nodo cumple una función específica.  
La Base de Datos está diseñada para ser **segura, automatizada y fácilmente mantenible**, alineada con los objetivos globales del proyecto.
