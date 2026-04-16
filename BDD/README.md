# Estado: Base de Datos (MariaDB)

## Descripción

Este estado se encarga de **instalar y configurar un servidor MariaDB** que actúa como base de datos central del sistema.  

Su función principal es **almacenar los registros de backups generados por los minions**, permitiendo llevar un control y trazabilidad de las copias de seguridad realizadas en la infraestructura.

---

## Contenido

### Instalación del servicio

- Instalación de:
  - `mariadb-server`
  - `mariadb-client`
  - `python3-mysqldb` (necesario para interacción con MySQL desde Python/Salt)

---

### Configuración del servidor

- Se modifica el archivo de configuración de MariaDB para permitir conexiones remotas:
  - Cambio de `bind-address` de `127.0.0.1` a `0.0.0.0`
- Se inicia y habilita el servicio MariaDB en el sistema

---

### Seguridad y autenticación

- Se configura la contraseña del usuario `root`
- Se cambia el método de autenticación por defecto (`unix_socket`) a `mysql_native_password`
- Se aplican los privilegios correspondientes

---

### Base de datos

- Se crea la base de datos:
  - `salt_logs`

---

### Usuario de acceso

- Se crea el usuario:
  - `saltlogger`
- Se le otorgan permisos completos sobre la base de datos `salt_logs`
- Se permite acceso remoto (`'%'`) para que los minions puedan conectarse

---

### Tabla de backups

Se crea la tabla:

- `machine_backups`

#### Estructura:

- `id`: identificador único
- `hostname`: nombre del minion
- `backup_path`: ruta del backup o repositorio
- `status`: estado del backup (`success` o `fail`)
- `execution_time`: fecha de ejecución
- `created_at`: fecha de inserción automática

#### Índices:

- Índice por hostname
- Índice por estado
- Índice por fecha de ejecución

---

## Variables

La configuración del estado depende de variables definidas en **Pillar**:

- `mysql.root_password` → contraseña del usuario root
- `mysql.password` → contraseña del usuario `saltlogger`

Estas variables permiten:

- evitar hardcodear credenciales
- mejorar la seguridad
- facilitar cambios en el entorno

---

## Objetivo

El objetivo de este estado es **proporcionar una base de datos centralizada y segura** para:

- Registrar los resultados de los backups realizados por los minions
- Mantener un histórico de ejecuciones
- Permitir trazabilidad y auditoría del sistema
- Facilitar futuras integraciones (monitorización, alertas, análisis)

---

## Resultado

Tras aplicar este estado:

- MariaDB queda instalado y operativo
- La base de datos `salt_logs` está creada
- El usuario `saltlogger` tiene acceso remoto
- La tabla `machine_backups` está lista para almacenar datos

Esto permite que los scripts de backup y otros servicios del sistema **registren automáticamente su actividad en la base de datos central**.
