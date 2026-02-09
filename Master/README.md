# SaltStack Master Configuration

Este directorio contiene la configuración central del **Salt Master**, el nodo encargado de orquestar y controlar todos los minions de la infraestructura.

## Descripción
El Master gestiona la entrega de estados (SLS), la ejecución de comandos remotos y el almacenamiento de llaves públicas de los minions.

## Estructura Principal
* `/srv/salt/`: Directorio raíz de los estados (States).
* `/srv/pillar/`: Datos sensibles y variables específicas de cada minion.

## Comandos Útiles
* **Aceptar llaves:** `salt-key -a <minion_id>`
* **Probar conexión:** `salt '*' test.ping`
* **Aplicar estados:** `salt '*' state.apply`
