# Componente de Base de Datos - MariaDB Centralizada

Este módulo de SaltStack gestiona el servidor de base de datos MariaDB centralizado, que actúa como el motor de almacenamiento tanto para el sistema de monitorización Zabbix 7.0 como para el sistema de registro de eventos (logs) de la infraestructura.

## Características Detalladas

- **Instalación Automatizada**: Despliegue completo de MariaDB Server y Client optimizado para Debian 13.
- **Acceso Remoto Seguro**: Configuración del `bind-address` a `0.0.0.0` para permitir conexiones desde el Servidor Zabbix, protegida por contraseñas robustas gestionadas vía Pillar.
- **Gestión de Esquemas y Usuarios**:
  - **Zabbix**: Creación de la base de datos `zabbix` con codificación `utf8mb4_bin` (requisito de Zabbix 7). Configuración de permisos remotos para el usuario `zabbix`.
  - **Salt Logs**: Creación de la base de datos `salt_logs` para el seguimiento de backups.
  - **SaltLogger**: Usuario dedicado `saltlogger` con permisos específicos para gestionar la tabla de eventos de máquinas.
- **Estructura de Datos**: Inicialización de la tabla `machine_backups` con índices para optimizar las consultas por hostname y estado de ejecución.

## Aplicación del Estado

Para aplicar este estado al minion de base de datos (habitualmente `MINIONBDD`):

```bash
salt "MINIONBDD" state.apply bdd
```

## Detalles de Configuración (Pillar)

El estado depende de los siguientes datos definidos en `/srv/pillar/bdd.sls`:

- `mysql:root_password`: Contraseña administrativa de MariaDB.
- `zabbix:db_pass`: Contraseña para el usuario de servicio de Zabbix.
- `mysql:password`: Contraseña para el usuario `saltlogger`.

## Archivos y Directorios Gestionados

- `/etc/mysql/mariadb.conf.d/50-server.cnf`: Modificado para permitir escucha en red.
- Comandos SQL internos para la provisión de usuarios y bases de datos.
- Persistencia de datos en `/var/lib/mysql`.

## Mantenimiento

Si necesitas verificar manualmente el acceso desde el servidor Zabbix:
```bash
mysql -h 192.168.0.5 -u zabbix -pUnclick2026 zabbix -e "status"
```
