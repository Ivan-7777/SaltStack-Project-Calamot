# Restic Client - Estado de SaltStack

## Descripción

Este estado configura una **máquina cliente** que envía backups al repositorio
central Restic mediante la API REST. Los resultados se registran en la base
de datos MariaDB central.

## Minion objetivo

`PRUEBA` (192.168.0.9)

## Funcionalidades

| Componente | Descripción |
|---|---|
| **Restic** | Motor de backups deduplicados y encriptados |
| **curl** | Verificación de conectividad al servidor REST |
| **MariaDB Client** | Cliente MySQL para registrar logs de backup |

## Estructura del estado

```
client/
├── init.sls           # Estado principal de SaltStack
├── restic_backup.sh   # Script de backup (desplegado por Salt)
└── README.md          # Este archivo
```

## Configuración desplegada

### Archivos creados

| Archivo | Propósito |
|---|---|
| `/usr/local/bin/restic_backup.sh` | Script de backup automático |
| `/root/.restic_env` | Variables de entorno (repositorio REST + contraseña) |

### Cron

| Tarea | Horario | Usuario |
|---|---|---|
| Backup Restic | 01:00 diario | root |

### Flujo del script de backup

1. **Validar conectividad** al servidor REST (`curl`)
2. **Verificar directorios** existen antes de incluirlos en el backup
3. **Ejecutar backup** con `restic backup`
4. **Registrar resultado** en MariaDB (éxito o fallo)

## Variables de Pillar requeridas

```yaml
restic:
  repository: "rest:http://192.168.0.10:8000/"  # URL del servidor REST
  password: "misma_contraseña_servidor"          # Debe coincidir con el servidor
  backup_paths:                                    # Directorios a respaldar
    - /etc
    - /home
    - /var/www
  cron_minute: "0"                                 # Minuto del cron
  cron_hour: "1"                                   # Hora del cron

mysql:
  host: "192.168.0.7"                              # IP del servidor MariaDB
  user: "saltlogger"
  password: "contraseña"
  database: "salt_logs"
```

## Aplicar el estado

```bash
# Aplicar solo este estado
salt 'PRUEBA' state.apply restic.client

# Aplicar todos los estados del top file
salt 'PRUEBA' state.apply
```

## Verificación

```bash
# Verificar que Restic está instalado
salt 'PRUEBA' cmd.run 'restic version'

# Verificar archivo de entorno
salt 'PRUEBA' cmd.run 'cat /root/.restic_env'

# Verificar conectividad al servidor REST
salt 'PRUEBA' cmd.run 'curl -sf --connect-timeout 5 http://192.168.0.10:8000/'

# Ejecutar backup manualmente
salt 'PRUEBA' cmd.run '/usr/local/bin/restic_backup.sh'

# Verificar cron
salt 'PRUEBA' cron.raw_list root
```

## Seguridad

- Archivo de credenciales: `0600` (solo root)
- Script de backup: `0750` (root puede ejecutar)
- Contraseñas gestionadas exclusivamente por Salt Pillar
- Conexión al servidor REST sin autenticación (solo red interna)
- Las credenciales MySQL se pasan por archivo temporal, no por línea de comandos

## Solución de problemas

### Error de conexión al servidor REST

```bash
# Verificar que el rest-server está activo en el servidor
salt 'MINIONBACKUP' service.status restic-rest-server

# Verificar red desde el cliente
salt 'PRUEBA' cmd.run 'nc -zv 192.168.0.10 8000'
```

### Error al registrar en MariaDB

```bash
# Verificar conexión a la BD
salt 'PRUEBA' cmd.run 'mysql -u saltlogger -p"PASSWORD" -h 192.168.0.7 -e "SELECT 1"'
```
