# Plan de Contingencia: Infraestructura SaltStack API

Este plan de contingencia define las estrategias de respuesta, recuperación y mitigación ante fallos críticos en el sistema de orquestación y automatización de seguridad basado en SaltStack.

---

## 1. Escenarios de Riesgo y Acciones Inmediatas

| Escenario | Impacto | Acción de Respuesta |
| :--- | :--- | :--- |
| **Fallo de Autenticación (401/403)** | Bloqueo total de la API | Verificar vigencia del Token y estado del servicio PAM. Reiniciar `salt-master`. |
| **Error SSL / Certificado Expirado** | Conexión denegada (HTTPS) | Regenerar certificados en `/etc/salt/pki/` y actualizar `api.conf`. |
| **Pérdida de Conexión con Minions** | Inoperatividad del Hardening | Verificar conectividad de red, borrar minions antiguos `salt-key -d`  y re-aceptar llaves con `salt-key -a`. |
| **Configuración de Seguridad Errónea** | Bloqueo de servicios (ej. SSH) | Acceso por consola de emergencia para revertir `/etc/ssh/sshd_config`. |

---

## 2. Estrategia de Backup y Recuperación

Para garantizar una recuperación rápida (MTTR bajo), se deben mantener copias de seguridad actualizadas de los siguientes componentes:

### A. Directorios Críticos
* **`/etc/salt/`**: Contiene la configuración del Master y, lo más importante, la carpeta **`pki/`**. Sin las llaves PKI, los minions no confiarán en el Master.
* **`/srv/salt/`**: Contiene todos los estados (`.sls`) y archivos de configuración de seguridad del apartado salt.
* **`/srv/pillar/`**: Contiene los datos sensibles y variables de entorno.

### B. Repositorio de Código
* Todo cambio en los archivos `.sls` debe ser versionado en un repositorio **Git** externo. En caso de error, la contingencia consiste en realizar un `git checkout` a la última versión estable.

---

## 3. Procedimiento de "Rollback" (Marcha Atrás)

Si una actualización de seguridad enviada a través de la API causa inestabilidad:

1.  **Identificación:** Localizar el ID del trabajo (JID) fallido en los logs de `/var/log/salt/api`.
2.  **Reversión Manual:** Aplicar el estado de emergencia `undo_security.sls` diseñado para restaurar valores por defecto de red y SSH.
3.  **Restauración de Configuración:** Copiar los archivos de backup `.bak` generados automáticamente por el módulo `file.managed` de Salt.



---

## 4. Protocolo de Recuperación ante Desastres (DRP)

En caso de caída total del servidor Master:

1.  **Reaprovisionamiento:** Levantar una nueva instancia de Debian 12.
2.  **Restauración de Identidad:** Copiar la carpeta `/etc/salt/pki/` desde el backup para mantener la relación de confianza con los minions existentes.
3.  **Despliegue de API:** Reinstalar `salt-api` y aplicar el archivo `api.conf` respaldado.
4.  **Validación:** Ejecutar el script `seguridad_api.py` con la función `test.ping` para confirmar la restauración del servicio.

---

## 5. Mantenimiento Preventivo

* **Auditoría de Logs:** Revisión semanal de `/var/log/salt/master` para detectar intentos de intrusión o errores de sintaxis recurrentes.
* **Rotación de Certificados:** Renovación anual de los certificados SSL de la API.
* **Simulacro de Fallo:** Una vez al trimestre, verificar que el backup de las llaves PKI es funcional.

---
**Última actualización:** Marzo 2026
**Responsable:** Administrador de Sistemas / Seguridad
