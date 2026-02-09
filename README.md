# SaltStack Project – Calamot 🧂

Este proyecto es un **laboratorio y repositorio de prácticas con SaltStack**, orientado a la automatización y gestión de sistemas Linux mediante infraestructuras.

El objetivo principal es **aprender, documentar y aplicar SaltStack en escenarios reales**, utilizando estados (`.sls`) para definir configuraciones reproducibles, seguras y controladas desde un Salt Master hacia uno o varios minions.

---

## Objetivo del proyecto

El proyecto nace con la intención de:

- **Comprender** el funcionamiento de SaltStack en entornos reales.
- **Automatizar** tareas de administración de sistemas.
- **Centralizar** configuraciones mediante estados salt.
- **Aplicar** buenas prácticas de infraestructura.
- **Servir como base de referencia** para futuros proyectos o ampliaciones posibles.

No está pensado como un producto final cerrado, sino como un **entorno de aprendizaje y evolución**, donde se pueden ir incorporando nuevos estados, servicios y configuraciones.

---

## Enfoque y Estructura

Este repositorio se centra en la gestión declarativa del sistema y la separación clara entre configuración y ejecución. Los estados incluidos son:

* **Master:** Configuración del cerebro de la infraestructura y gestión de llaves.
* **BDD (Base de Datos):** Despliegue y optimización de motores de datos.
* **CA (Certificaciones):** Automatización de certificados SSL/TLS internos.
* **Firewall:** Definición de reglas de red y seguridad perimetral.
* **Seguridad:** Hardening de Kernel (sysctl), SSH, protección del Minion y auditoría de logs.
* **Wireguard:** Configuración de túneles VPN seguros.

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
  - Uso del top.sls y targeting.

Estas guías han servido como base para el diseño modular y reutilizable de los estados del proyecto.

---

## Licencia

Este proyecto se distribuye bajo licencia **Apache 2.0**, para más detalles lee el archivo "LICENSE file" seguido de un resumen de licencias para módulos externos .

Consulta el archivo [LICENSE](LICENSE) para más información.
