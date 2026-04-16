
init.sls  README.md  restic_backup.sh
root@debian:/srv/salt/restic/server# nano restic_backup.sh
root@debian:/srv/salt/restic/server# nano README.md
  GNU nano 8.4                                README.md
# Restic Server - Estado de SaltStack

## Descripción

Este estado configura el **servidor central de backups** que almacena repositorios
Restic de múltiples máquinas cliente mediante la API REST.

## Minion objetivo

`MINIONBACKUP` (192.168.0.10)

## Funcionalidades

| Componente | Descripción |
|---|---|
| **Restic** | Motor de backups deduplicados y encriptados |
| **restic-rest-server** | Servidor HTTP que expone el repositorio a los clientes |
| **OpenSSH Server** | Permite acceso SSH para gestión remota |
| **MariaDB Client** | Cliente MySQL para registrar logs de mantenimiento |

## Estructura del estado

```
server/
├── init.sls           # Estado principal de SaltStack
├── restic_backup.sh   # Script de mantenimiento (desplegado por Salt)
└── README.md          # Este archivo
```

## Configuración desplegada

### Servicios

| Servicio | Puerto | Estado |
|---|---|---|
| `restic-rest-server` | 8000 | Habilitado y activo |
| `ssh` | 22 | Habilitado y activo |

### Archivos creados

| Archivo | Propósito |
|---|---|
| `/backups/restic/` | Directorio del repositorio Restic |
| `/usr/local/bin/restic_maintenance.sh` | Script de mantenimiento automático |
| `/root/.restic_env` | Variables de entorno (repositorio + contraseña) |
| `/home/salt/.ssh/authorized_keys` | Claves SSH autorizadas de clientes |

### Cron

| Tarea | Horario | Usuario |
|---|---|---|
| Mantenimiento Restic | 02:30 diario | root |
