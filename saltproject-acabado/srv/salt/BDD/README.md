# Estado: Base de Datos (BDD)

Este estado se encarga de la instalación y configuración completa del servidor de bases de datos MariaDB.

## ¿Qué hace este estado?

1.  **Instalación de Software**: Instala el servidor y cliente de MariaDB, además de las librerías necesarias para que Salt pueda interactuar con las bases de datos.
2.  **Configuración de Acceso**: Configura MariaDB para permitir conexiones desde cualquier dirección IP (`0.0.0.0`), facilitando que otros servidores (como Zabbix o el Servidor Web) puedan conectarse de forma remota.
3.  **Seguridad**: Establece una contraseña robusta para el usuario `root` de la base de datos (obtenida de forma segura desde los pilares).
4.  **Gestión de Bases de Datos y Usuarios**:
    *   **Zabbix**: Crea la base de datos para el sistema de monitorización Zabbix, con su respectivo usuario y permisos remotos.
    *   **Logs de Salt**: Crea una base de datos llamada `salt_logs` y un usuario `saltlogger`. Esta base se utiliza para registrar eventos de copia de seguridad (backups) de todas las máquinas.
    *   **WordPress**: Prepara la base de datos y el usuario que utilizará el sitio web WordPress.

## Requisitos
*   Tener definidos los pilares correspondientes (`mysql:root_password`, `zabbix:db_name`, etc.) para una configuración personalizada.
