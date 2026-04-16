# Sistema de Backups RESTIC con SaltStack

## Descripción general

Este repositorio contiene la automatización completa de un sistema de copias de seguridad basado en **Restic**, gestionado mediante **SaltStack**.

La arquitectura está compuesta por:

- Servidor central REST (almacena los backups)
- Clientes (envían backups)
- Base de datos MariaDB (registra logs)

El sistema permite realizar backups deduplicados, encriptados y automatizados.

---

## Arquitectura
Clientes (Restic + cron)
│
▼
Restic REST Server
│
▼
MariaDB (logs)

---

## Estructura del repositorio
restic/
├── client/
│ ├── init.sls
│ ├── restic_backup.sh
│ └── README.md
│
├── server/
│ ├── init.sls
│ ├── restic_maintenance.sh
│ └── README.md
│
├── pillar/
│ ├── restic_client.sls
│ └── restic_server.sls
│
└── README.md

---

## Componentes

### Restic
- Backups cifrados
- Deduplicación automática

### REST Server
- Servicio `restic-rest-server`
- Acceso al repositorio vía HTTP

### SaltStack
- Automatización
- Gestión de configuración
- Uso de Pillars

### MariaDB
- Registro de logs de backups y mantenimiento

---

## Funcionamiento

### Cliente

1. Comprueba conexión al servidor
2. Verifica rutas
3. Ejecuta backup (`restic backup`)
4. Guarda resultado en MariaDB

### Servidor

1. Ejecuta `restic check`
2. Limpia snapshots antiguos (7 diarios, 4 semanales)
3. Guarda logs en MariaDB

---

## Cron

| Sistema  | Tarea         | Hora  |
|----------|--------------|-------|
| Cliente  | Backup        | 01:00 |
| Servidor | Mantenimiento | 02:30 |

---
##  Seguridad
1. Backups cifrados
2. Uso de Salt Pillar para credenciales
3. Permisos restringidos (0600 / 0750)
4. Acceso REST en red interna
5. Uso de claves SSH
6. Credenciales no expuestas en CLI

---
##  Ventajas
1. Automatización completa
2. Escalable
3. Centralización de logs
4. Recuperación sencilla
5. Uso eficiente de almacenamiento

---
##  Mejoras futuras
1. Autenticación en REST server
2. Alertas
3. Backups más frecuentes
