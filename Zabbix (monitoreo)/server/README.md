# Servidor Zabbix y Frontend Web

Este componente despliega el núcleo del sistema de monitorización Zabbix y su interfaz de gestión web, optimizado para entornos Debian 13 (Trixie).

## Stack Tecnológico

- **Motor**: Zabbix Server 7.0 LTS (MySQL edition).
- **Frontend**: Interfaz PHP 8.4 servida por Apache2.
- **Base de Datos**: MariaDB remota (alojada en `192.168.0.5`).

## Funcionalidades Clave

- **Provisión de Esquema**: Importación automática de los ficheros SQL iniciales (`schema`, `images`, `data`) solo en la primera instalación.
- **Localización Completa**:
  - Generación de locales `es_ES.UTF-8`.
  - Configuración automática del idioma de la interfaz a **Español** mediante comandos SQL directos en la tabla `users`.
- **Robustez del Servidor Web**:
  - Configuración del módulo `mpm_prefork` para compatibilidad total con PHP.
  - Reparación automática del motor PHP tras purgas o reinstalaciones de Apache.
- **Optimización de PHP**: Ajuste de directivas críticas en `php.ini` (`max_execution_time: 300`, `post_max_size: 16M`) para cumplir con los requisitos del frontend de Zabbix.

## Despliegue y Uso

Minion objetivo: `MINIONZABBIX` (IP: `192.168.0.4`)

```bash
# Aplicar el despliegue completo
salt "MINIONZABBIX" state.apply zabbix.server
```

## Verificación del Sistema

Tras el despliegue, puedes validar los servicios:

```bash
# Comprobar estado del servicio Zabbix
salt "MINIONZABBIX" service.status zabbix-server

# Validar que Apache está sirviendo PHP correctamente
curl -I http://192.168.0.4/zabbix/
```

Acceso web: **`http://192.168.0.4/zabbix/`** (Credenciales estándar definidas en Pillar).

## Resolución de Problemas (Troubleshooting)

- **Pantalla en blanco**: El estado de Salt incluye un script de reparación que reactiva el módulo PHP de Apache automáticamente.
- **Error de conexión DB**: Verifica que la IP `192.168.0.5` sea accesible y que el usuario `zabbix` tenga permisos remotos.
