# Datos de Configuración (Pillars) - Proyecto SaltStack

Este directorio contiene los **Pilares** de Salt, que son los datos de configuración específicos para cada cliente y servicio.

## ¿Qué son los Pilares?

Si los **Estados** (`salt/`) son las instrucciones de "cómo" instalar algo, los **Pilares** son el "qué" instalar. Por ejemplo, en los estados decimos que queremos un servidor DHCP, y en los pilares definimos qué rango de IPs debe repartir.

## Estructura de este directorio

*   **`top.sls`**: Es el mapa que indica qué datos de configuración pertenecen a cada máquina (minion).
*   **`customers/`**: Contiene carpetas por cliente. Actualmente, los datos principales se encuentran en `customers/aitor/`.

## Datos gestionados en los Pilares

En los archivos `.sls` de este directorio encontrarás:
*   **Credenciales**: Contraseñas de bases de datos, claves de WordPress, etc.
*   **Redes**: Direcciones IP estáticas, máscaras de red, puertas de enlace y rangos DHCP.
*   **Dominios**: Nombres de dominio para el servidor DNS y el servidor web.
*   **Certificados**: Parámetros para la generación de la CA y certificados SSL.

## Seguridad

Los Pilares son datos sensibles. Solo el Salt-Master tiene acceso a ellos y solo envía a cada Minion los datos que le corresponden específicamente, garantizando que una máquina no pueda ver las contraseñas de otra.
