# Estado: Proxy Inverso

Este estado configura un servidor Nginx para actuar como puerta de entrada segura a los servicios internos.

## ¿Qué hace este estado?

1.  **Instalación**: Instala el servidor web Nginx.
2.  **Configuración de Proxy**: Configura Nginx para recibir peticiones externas y redirigirlas a los servidores correspondientes (como el servidor web o el balanceador), protegiendo la identidad y ubicación real de estos últimos.
3.  **Aislamiento de Red**: Configura una interfaz de red estática diseñada para operar dentro de una zona desmilitarizada (DMZ) o detrás de un firewall, estableciendo la ruta correcta hacia la salida de internet.
4.  **Servicio Siempre Activo**: Mantiene el servicio Nginx funcionando y lo recarga automáticamente ante cualquier cambio en la configuración de los sitios o del proxy.

## Ventajas
*   Mejora la seguridad al ocultar los servidores internos.
*   Permite la terminación de SSL en un único punto.
*   Facilita el balanceo de carga en futuras expansiones.
