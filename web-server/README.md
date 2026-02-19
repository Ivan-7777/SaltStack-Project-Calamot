# State: Web-Server (Servidor de Aplicaciones y Hosting)

Este módulo gestiona el nodo dedicado a servicios web del laboratorio. Su función principal es proporcionar un entorno de hosting robusto, automatizado y con una identidad de red fija.

## Propósito del Estado

El objetivo de este estado es transformar un minion en un **Servidor Web listo para producción**, asegurando que el despliegue del contenido, la conectividad y las herramientas de administración estén disponibles desde el primer minuto.

### Áreas de Gestión

* **Servicio de Hosting:** Despliega el servidor **Apache2** junto con la estructura de directorios necesaria para alojar la página principal del proyecto.
* **Identidad de Red Estática:** Implementa mecanismos de bajo nivel (udev y networking) para garantizar que el servidor siempre mantenga el nombre de interfaz `eth0` y una IP fija, facilitando su localización por otros servicios como el DHCP o el Firewall.
* **Herramientas de Autogestión:** Proporciona scripts de ayuda (`autohosting`) que simplifican las tareas comunes de creación y eliminación de sitios web, optimizando el flujo de trabajo.



## Consideraciones de Despliegue

Para garantizar que la configuración de red sea persistente y que el sistema reconozca los cambios en las interfaces físicas, el estado realiza un **reinicio programado** al finalizar su ejecución. Esto asegura que el servidor arranque en un estado limpio y con todas las reglas de red aplicadas correctamente.

## Uso

```bash
# Aplicar la configuración completa del servidor web:
salt 'web-server' state.apply web-server
