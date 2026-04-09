# Estado: Backup Centralizado con Restic

## Descripción

Este estado se encarga de **implementar un sistema de copias de seguridad centralizado** utilizando Restic, así como de **automatizar la ejecución de backups** en todos los minions de la infraestructura.

Su objetivo es asegurar que **cada máquina realice copias de seguridad de forma automática**, enviándolas a un servidor central, y permitiendo su futura integración con el sistema de logging y base de datos del proyecto.

---

## Contenido

### Servidor de Backups

- Se instala Restic en la máquina servidor.
- Se crea el repositorio central en `/backups/restic`.
- Se inicializa el repositorio con contraseña segura.
- El servidor actúa como punto único de almacenamiento de backups.

---

### Clientes (Minions)

- Se instala Restic en cada máquina cliente.
- Se configura la conexión al servidor mediante SSH.
- Se define el repositorio remoto:

- Generar backups diarios de las máquinas críticas.
- Centralizar la información de logs y backups de toda la infraestructura.
- Garantizar trazabilidad y seguridad de los datos sin intervención manual.
