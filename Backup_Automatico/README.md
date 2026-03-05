# Estado: Backup y Logging

## Descripción

Este estado se encarga de **distribuir los scripts de backup y logging** a cada minion y de **programar la ejecución automática de backups** en la infraestructura del proyecto.  

Su objetivo es asegurar que **cada máquina registre su actividad y realice copias de seguridad de manera automatizada**, enviando toda la información a la base de datos central para su almacenamiento y análisis.

---

## Contenido

### Scripts

- `backup_machine.sh`  
  Script que realiza copias de seguridad de carpetas críticas (`/etc`, `/home`, `/var/www`) en cada minion y registra el resultado en la base de datos central.

- `salt_db_logger.py`  
  Script que recoge información sobre los estados de Salt ejecutados en cada minion y envía un registro a la base de datos central (`salt_state_logs`).

### Programación de backups

- Se crea una tarea **cron** que ejecuta `backup_machine.sh` automáticamente cada día a las 2:00 AM.
- Permite mantener los backups actualizados sin intervención manual.

---

## Variables

La configuración del estado puede variar según el entorno:

- Ruta donde se almacenan los backups en cada minion (`/backups` por defecto).
- IP o host de la **BDD central**.
- Usuario y contraseña de la base de datos (`saltlogger`).
- Carpeta o archivos que se quieran incluir en el backup.
- Hora de ejecución del cron.

---

## Objetivo

El objetivo de este estado es **automatizar los procesos de backup y logging**, permitiendo:

- Registrar todos los cambios de configuración realizados por Salt en la BDD central.
- Generar backups diarios de las máquinas críticas.
- Centralizar la información de logs y backups de toda la infraestructura.
- Garantizar trazabilidad y seguridad de los datos sin intervención manual.
