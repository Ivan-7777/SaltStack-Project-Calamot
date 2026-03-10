# SaltStack Project – Calamot - UnClick

Este proyecto es un **laboratorio y repositorio de prácticas con SaltStack**, orientado a la automatización y gestión de sistemas Linux mediante infraestructuras.

El objetivo principal es **aprender, documentar y aplicar SaltStack en escenarios reales**, utilizando estados (`.sls`) para definir configuraciones reproducibles , seguras y controladas desde un Salt Master hacia uno o varios minions.

---

## Objetivo del proyecto

El proyecto nace con la intención de:

- **Comprender** el funcionamiento de SaltStack en entornos reales.
- **Automatizar** tareas de administración de sistemas.
- **Centralizar** configuraciones mediante estados salt.
- **Aplicar** buenas prácticas de infraestructura.
- **Servir como base de referencia** para posibles futuros proyectos o ampliaciones posibles.

No está pensado como un producto final cerrado, sino como un **entorno de aprendizaje y educativo**, donde se pueden ir incorporando nuevos estados, servicios y configuraciones.

---

## Enfoque y Estructura

Este repositorio se centra en la gestión declarativa del sistema y la separación clara entre configuración y ejecución. La infraestructura se basa en los estados disponibles de este proyecto de github:

| Módulo | Descripción |
| :--- | :--- |
| **Master** | Configuración del "cerebro" de la infraestructura de forma automatizada. |
| **BDD** | Despliegue, configuración y optimización de bases de datos. |
| **CA** | Servidor de Certificaciones Automáticas para gestión de SSL/TLS. |
| **Firewall** | Definición de reglas de red (nftables) y seguridad perimetral. |
| **Seguridad** | Hardening de Kernel (sysctl), SSH, protección del Minion y auditoría de logs. |
| **Wireguard** | Implementación de túneles VPN seguros para conectividad entre nodos. |

---

## Ciberseguridad

La seguridad es uno de los pilares fundamentales de este proyecto. Aunque se trata de un laboratorio de aprendizaje, todas las configuraciones se han diseñado teniendo en cuenta **principios básicos de ciberseguridad y hardening de sistemas**.

El objetivo es que la infraestructura automatizada con SaltStack no solo sea funcional, sino también **segura por defecto**.

Entre las medidas implementadas o contempladas dentro del proyecto se encuentran:

- **Hardening del sistema**
  - Ajustes de seguridad mediante `sysctl` para reforzar el kernel.
  - Configuraciones seguras del servicio **SSH** (restricción de accesos, deshabilitar login root, etc.).
  
- **Gestión segura de comunicaciones**
  - Uso de **certificados y autoridad de certificación (CA)** para servicios que requieran cifrado.
  - Implementación de **túneles VPN con WireGuard** para proteger la comunicación entre nodos.

- **Seguridad de red**
  - Uso de **nftables** para definir políticas de firewall claras y reproducibles.
  - Control de acceso a servicios mediante reglas declarativas.

- **Protección de la infraestructura Salt**
  - Configuración segura del **Salt Master y los Minions**.
  - Gestión controlada de claves de autenticación entre nodos.
  - Automatización de configuraciones para evitar errores manuales.

- **Auditoría y monitorización**
  - Registro de eventos y logs del sistema para facilitar auditorías.
  - Posibilidad de ampliar el proyecto con herramientas de análisis o detección de incidentes.

Este enfoque permite que el laboratorio no solo sirva para aprender **automatización con SaltStack**, sino también para practicar **despliegues de infraestructura con una mentalidad orientada a la seguridad**.
---

## Público objetivo

Nos gustaría que este proyecto fuese útil para:

- Estudiantes de sistemas o ciberseguridad.
- Personas que están aprendiendo SaltStack.
- Administradores que quieran ejemplos claros y funcionales.
- Laboratorios personales o académicos.

---

## Documentación de referencia

Este proyecto sigue las buenas prácticas recomendadas en la documentación oficial de SaltStack:

- **States – Parte 1 a 4:**
  - Introducción a los states.
  - Requisitos y dependencias.
  - Organización y reutilización.
  - Uso del top.sls y targeting (Objetivo).

Estas guías han servido como base para el diseño modular y reutilizable de los estados del proyecto.

---

## Licencia

Este proyecto se distribuye bajo licencia **Apache 2.0**, para más detalles lee el archivo "LICENSE file" seguido de un resumen de licencias para módulos externos .

Consulta el archivo [LICENSE](LICENSE) para más información.
