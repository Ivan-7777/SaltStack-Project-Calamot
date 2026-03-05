# Estado: BDD

## Descripción

Este estado se encarga de **crear y configurar la base de datos centralizada** del proyecto SaltStack en la máquina dedicada a la BDD.  
El objetivo es que todas las máquinas (minions) puedan **enviar información de logs y backups automáticamente** a un único lugar, de manera totalmente automatizada mediante SaltStack.

---

## Contenido

### Base de datos principal
Se crea la base de datos `salt_logs` que almacenará toda la información del proyecto.

### Tablas
Se crean dos tablas principales:

- `salt_state_logs`: guarda los **logs de ejecución de estados** de Salt en cada minion.
- `machine_backups`: registra los **backups automáticos** realizados en cada máquina.

### Usuario y permisos
Se crea un **usuario `saltlogger`** con permisos mínimos necesarios para que los minions puedan **insertar datos** en la base de datos sin comprometer la seguridad del servidor.

---

## Variables

La configuración puede variar según el entorno o los datos futuros que se quieran almacenar.  
Algunos parámetros que pueden modificarse son:

- Nombre de la base de datos (`salt_logs`)
- Nombre de usuario y contraseña (`saltlogger`)
- Permisos asignados al usuario
- Estructura de las tablas (campos, tipos de datos)
- Host de la BDD que podrán usar los minions (`localhost` o `%` para conexiones remotas)

---

## Objetivo

El objetivo de este estado es **automatizar la creación y preparación de la base de datos**, dejando todo listo para que:

- Todos los minions puedan enviar sus logs de ejecución de estados.
- Todos los minions puedan registrar sus backups automáticos.
- Los administradores tengan un **registro centralizado y seguro** de la actividad de la infraestructura.
