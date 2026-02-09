# SaltStack Project – Calamot 🧂

Este proyecto es un **laboratorio y repositorio de prácticas con SaltStack**, orientado a la automatización y gestión de sistemas Linux mediante infraestructura como código (IaC).

> **Nota:** Este es un entorno de aprendizaje dinámico diseñado para comprender la orquestación centralizada desde un Salt Master hacia sus Minions.

---

## 🏗️ Estructura de la Infraestructura

El repositorio está organizado en estados (`states`) modulares que pueden aplicarse de forma independiente o conjunta:

| Directorio | Descripción |
| :--- | :--- |
| `master/` | Configuración del Salt Master y orquestación global. |
| `bdd/` | Despliegue y optimización de bases de datos. |
| `ca/` | Autoridad de Certificación interna y gestión de SSL/TLS. |
| `firewall/` | Gestión de políticas de red y seguridad perimetral. |
| `seguridad/` | Hardening de Kernel, SSH y auditoría de logs. |
| `wireguard/` | Despliegue de VPN punto a punto segura. |

---

## 🎯 Objetivos y Enfoque

El proyecto aplica las mejores prácticas de SaltStack para:
* **Gestión Declarativa:** Definir el "qué" y no el "cómo".
* **Idempotencia:** Asegurar que los estados puedan reaplicarse sin efectos secundarios negativos.
* **Seguridad por Defecto:** Aplicar hardening desde el despliegue inicial.

---

## 🚀 Uso Rápido

Para aplicar la configuración completa de seguridad y red a todos los nodos:

```bash
# Sincronizar estados
salt '*' state.apply seguridad,firewall
