# Estado: security

## Descripción
Este estado aplica medidas básicas de seguridad (hardening) sobre los minions gestionados por SaltStack.

El objetivo es reducir la superficie de ataque del sistema sin interferir con la automatización ni los servicios desplegados.

## ¿Qué hace este estado?
- Configura parámetros de seguridad del kernel
- Endurece el acceso SSH
- Ajusta permisos en directorios sensibles
- Controla el comportamiento de servicios críticos

## ¿Cuándo se aplica?
Este estado se aplica **después** de configurar el rol principal del sistema (web server, CA, etc.), como una capa adicional de seguridad.

## Sistemas afectados
- Minions Linux gestionados por SaltStack.

## Notas
Este estado está diseñado para ser reutilizable y no depende de servicios específicos.
