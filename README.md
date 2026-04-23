# Sistema de Monitorización Infraestructura - Zabbix 7.0 LTS

Solución integral de monitorización profesional, automatizada y gestionada mediante **SaltStack**.

## Descripción General

Este proyecto implementa una infraestructura de monitorización distribuida capaz de supervisar servidores, servicios de red y eventos de backup en tiempo real. Está diseñado para ser **idempotente**, permitiendo reconstruir todo el sistema desde cero con un solo comando de Salt.

## Arquitectura del Sistema

La infraestructura se divide en tres capas principales:

| Capa | Nodo | IP Real | Función |
|---|---|---|---|
| **Servidor y Frontend** | `MINIONZABBIX` | `192.168.0.4` | Cerebro del sistema e interfaz de usuario. |
| **Base de Datos** | `MINIONBDD` | `192.168.0.5` | Almacenamiento centralizado de métricas y configuración. |
| **Agentes** | `PRUEBA`, etc. | `192.168.0.X` | Nodos monitorizados que reportan datos. |

## Puntos Fuertes de esta Implementación

- **Automatización Total**: Desde la creación de tablas en la base de datos hasta la configuración del idioma español en la interfaz web.
- **Compatibilidad Debian 13**: Optimizado para las últimas versiones de PHP (8.4) y Apache.
- **Auto-Reparación**: Incluye lógica para detectar y arreglar fallos comunes en el motor PHP de Apache tras reinstalaciones.
- **Seguridad Estandarizada**: Gestión de credenciales centralizada en Pillar (`Unclick2026`).
- **Integración de Backups**: Capacidad para monitorizar el estado de Restic y registrar eventos en la base de datos de logs.

## Guía de Despliegue Rápido

1. **Configuración**: Asegura que las IPs y contraseñas en `/srv/pillar/` sean correctas.
2. **Base de Datos**: `salt "MINIONBDD" state.apply bdd`
3. **Servidor Zabbix**: `salt "MINIONZABBIX" state.apply zabbix.server`
4. **Agentes Cliente**: `salt "*" state.apply zabbix.agent`

## Acceso al Panel de Control

Una vez completado el despliegue, accede a la monitorización en:
**`http://192.168.0.4/zabbix/`**
