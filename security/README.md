# State: Seguridad (Hardening & Auditing)

Este estado aplica una capa de seguridad crítica sobre los minions, enfocándose en el endurecimiento del kernel, la protección de las comunicaciones SSH y la integridad del propio agente de SaltStack.

## Componentes y Acciones

### 1. Hardening del Kernel (sysctl)
* **Archivo:** `/etc/sysctl.d/99-hardening.conf`
* **Acción:** Aplica parámetros de red y sistema para mitigar ataques (ej. ataques de inundación o redireccionamientos maliciosos). Ejecuta `sysctl --system` automáticamente al detectar cambios.

### 2. Seguridad en SSH
* **Instalación:** Asegura que `openssh-server` esté presente.
* **Configuración:** Aplica una configuración restrictiva (`sshd_config`) con permisos **600**.
* **Gestión:** Reinicia el servicio `ssh` automáticamente si la configuración es modificada.

### 3. Protección del Salt Minion
* **Hardening del agente:** Desactiva el multiprocesamiento y ajusta los tiempos de espera de aceptación para reducir la superficie de exposición del proceso minion.
* **Seguridad PKI:** Restringe los permisos del directorio `/etc/salt/pki` a **700**, asegurando que solo el usuario root pueda acceder a las llaves criptográficas.

### 4. Auditoría y Logs
* **Restricción de Logs:** Ajusta permisos en `/var/log/auth.log` y `/var/log/syslog` para que solo root y el grupo `adm` puedan leerlos (640).
* **Persistencia de Journald:** Configura y asegura la persistencia de logs del sistema mediante `journald.conf`, reiniciando el servicio para aplicar cambios.

## Estructura de Archivos
Este estado depende de los archivos locales situados en:
* `files/sysctl-hardening.conf`
* `files/sshd_config`
* `files/journald.conf`

## Requisitos de Aplicación
```bash
# Para aplicar este estado de seguridad a todos los minions:
salt '*' state.apply security
