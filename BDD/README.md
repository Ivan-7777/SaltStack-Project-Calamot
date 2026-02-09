# State: BDD (Database)

Este estado se encarga de la instalación, configuración y securización de los servidores de Bases de Datos.

## Funcionalidades
* Instalación del motor de base de datos (PostgreSQL/MySQL).
* Configuración de archivos `conf` (optimización de memoria y conexiones).
* Creación de usuarios y bases de datos iniciales.

## Dependencias
* Requiere acceso al puerto correspondiente (ej. 5432) gestionado por el estado `firewall`.
