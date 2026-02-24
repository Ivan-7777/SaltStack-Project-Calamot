## Estado: Base de Datos (MariaDB)

Este estado instala y configura el servicio de base de datos MariaDB en una máquina correspondiente.

### Contenido

- **Servicio MariaDB Global:**  
  Proporciona un sistema de gestión de bases de datos relacional para almacenar y administrar la información de los servicios de la red.

- **Motor de Base de Datos:**  
  Instala y configura el servidor `mariadb-server`, incluyendo el servicio y los archivos de configuración principales.

- **Reglas:**  
  - Define usuarios de base de datos y asigna permisos específicos sobre las bases creadas.  
  - Configura el acceso local o remoto al servidor MariaDB según la topología de la red.  
  - Establece parámetros de seguridad (contraseñas, puerto de escucha, bind-address).

### Variables

La configuración puede variar según la arquitectura de la red (acceso local o remoto), las políticas de seguridad, el número de usuarios y las bases de datos requeridas.  
También puede modificarse el puerto y la dirección de escucha dependiendo de la segmentación de la red y la presencia de IP fijas.
