# Estado: WordPress

Este estado automatiza la instalación completa y profesional del gestor de contenidos WordPress.

## ¿Qué hace este estado?

1.  **Gestión Inteligente (WP-CLI)**: Instala la herramienta de línea de comandos `wp-cli`, que permite gestionar WordPress de forma automatizada sin usar el navegador.
2.  **Descarga y Preparación**: Descarga la última versión de WordPress en español y la coloca en el directorio web correspondiente.
3.  **Configuración Automática**: Crea el archivo `wp-config.php` vinculándolo con la base de datos MariaDB configurada previamente.
4.  **Instalación del Núcleo**: Realiza la instalación inicial (título del sitio, usuario administrador, contraseña y correo) de forma totalmente desatendida.
5.  **Personalización de Bienvenida**:
    *   Crea automáticamente una página de inicio personalizada: "Pagina de Bienvenida".
    *   Configura WordPress para que use esta página como portada principal del sitio.
6.  **Seguridad de Archivos**: Ajusta correctamente los permisos de todos los archivos y carpetas para que el servidor web pueda funcionar de forma segura.

## Requisito previo
Es necesario que el estado `BDD` se haya ejecutado correctamente para que WordPress pueda conectarse a su base de datos.
