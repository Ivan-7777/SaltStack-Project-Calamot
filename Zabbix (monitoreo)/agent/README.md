# Agente Zabbix - Monitorización de Nodos Cliente

Agente ligero desplegado en los nodos de la infraestructura para recolectar y reportar métricas de rendimiento y estado del sistema.

## Capacidades de Monitorización

- **Métricas de Sistema**: Carga de CPU (Load), uso de memoria RAM, espacio en disco y estadísticas de red.
- **Monitorización de Servicios**: Incluye `UserParameters` personalizados para rastrear el estado de:
  - **SSH**: Alerta si el demonio `sshd` no está respondiendo.
  - **MariaDB**: Monitorización local del servicio de base de datos (si aplica).
- **Escalabilidad**: Preparado para el **Auto-Registro** (Auto-Registration), permitiendo que nuevos nodos se añadan al panel de Zabbix automáticamente al instalar el agente.

## Instalación y Aplicación

Se puede aplicar a cualquier nodo que requiera supervisión (ej. `PRUEBA`, `MINIONBACKUP`):

```bash
salt "PRUEBA" state.apply zabbix.agent
```

## Métricas Personalizadas Incluidas

El agente expone las siguientes claves para Zabbix:
- `service.ssh.status`: Devuelve 1 si el servicio está activo, 0 si está caído.
- `service.mariadb.status`: Devuelve el estado de MariaDB en el nodo local.

## Configuración y Seguridad

- **Acceso Restringido**: El agente solo acepta peticiones desde la IP del Servidor Zabbix (`192.168.0.4`) definida en Pillar.
- **Firewall Automático**: Gestión de reglas UFW para abrir el puerto `10050/tcp` solo para tráfico necesario.
- **Scripts de Validación**: Se despliega `/usr/local/bin/zabbix_agent_verify.sh` para pruebas rápidas de conectividad desde el propio minion.

## Mantenimiento

Para probar una métrica manualmente desde el agente:
```bash
zabbix_agentd -t service.ssh.status
```
