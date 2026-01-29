# Estado: webserver

## Descripción
Este estado despliega y configura un servidor web de forma automatizada mediante SaltStack.

Está pensado para sistemas que actúan como servidores web dentro de una infraestructura.

## ¿Qué hace este estado?
- Instala el servidor web
- Configura los archivos necesarios del servicio
- Asegura que el servicio esté habilitado y en ejecución

## ¿Cuándo se aplica?
Se aplica a máquinas cuyo rol principal es servir contenido web.

## Sistemas afectados
- Servidores web.

## Notas
Este estado puede combinarse con el estado de seguridad para reforzar la protección del sistema.
