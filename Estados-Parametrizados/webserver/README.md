# Estado Salt: Webserver

Este estado de Salt (`webserver`) permite desplegar un **servidor web completo** en un sistema Debian/Ubuntu con Nginx y OpenSSH, utilizando los valores definidos en el pilar `web-server`. Además, genera certificados SSL, configura interfaces de red y prepara un script de autohosting.

---

## Estructura del estado

El estado se organiza en bloques claros para facilitar su mantenimiento:

1. **Instalación de paquetes**
   - `nginx`: servidor web.
   - `openssh-server`: para acceso SSH seguro.

2. **Webroot y página principal**
   - Se crea el directorio `webroot` según el pilar: `pillar['web-server']['webroot']`.
   - Se despliega el archivo `index.html` desde la carpeta `files` de Salt (`index.html.jinja`).

3. **Configuración de Nginx**
   - Se copia y genera la configuración por defecto de Nginx desde `default.jinja`, usando valores del pilar como dominio y ruta del webroot.
   - Se generan certificados SSL para HTTPS automáticamente según el dominio definido en el pilar.
   - Se genera un archivo `dhparam.pem` para mejorar la seguridad de TLS.
   - Se incluyen snippets SSL (`ssl-params.conf`) para parámetros adicionales de seguridad.

4. **SSH**
   - Se instala y configura SSH (`sshd_config.jinja`) según el pilar.
   - Incluye parámetros básicos: puerto, si se permite root login, SFTP habilitado, etc.
   - Reinicia el servicio SSH si la configuración cambia.

5. **Red**
   - Se configura la interfaz de red según el pilar (`interfaces.jinja`), incluyendo IP estática, máscara, gateway y DNS.
   - El reboot final aplica los cambios de red.

6. **Script de autohosting**
   - Se despliega un script de ayuda `/root/Scripts/autohosting.sh` con permisos ejecutables.

---

## Pilar `web-server`

El estado depende completamente del pilar `web-server`. Ejemplo de pilar:

```yaml
web-server:
  domain: hosting.local

  network:
    interface: enp0s8
    address: 192.168.0.20
    mask: 24
    gateway: 192.168.0.1
    dns: 192.168.0.1

  webroot: /var/www/html

  ssh:
    port: 22
    permit_root_login: yes

  ssl:
    key: server.key
    cert: server.crt
Notas sobre el pilar

domain: nombre del servidor web que se usará en Nginx y certificados SSL.

webroot: ruta donde se desplegará index.html.

network: configuración de la interfaz de red.

ssh: puerto y política de root login.

ssl: nombres de archivo para los certificados generados automáticamente.

Archivos Jinja utilizados

default.jinja: configuración Nginx por defecto, con soporte HTTP y HTTPS.

interfaces.jinja: configuración de la interfaz de red según pilar.

sshd_config.jinja: configuración de SSH basada en los valores del pilar.

index.html.jinja: página de bienvenida desplegada en el webroot.

Flujo de ejecución

Se instalan los paquetes (nginx, openssh-server).

Se crean directorios para webroot y scripts.

Se despliega la página principal.

Se copia la configuración de Nginx y se generan certificados SSL.

Se aplica la configuración SSH.

Se reinicia Nginx y SSH según sea necesario.

Se configura la interfaz de red.

Se ejecuta un reboot para aplicar cambios de red y certificados.

Uso básico

Copia el estado en /srv/salt/webserver/ y los archivos files/ correspondientes.

Configura el pilar web-server en /srv/pillar/webserver.sls.

Aplica el estado al minion:

sudo salt '<minion_id>' state.apply webserver

Una vez completado, tu servidor web estará accesible vía HTTP y HTTPS según el dominio configurado, y SSH estará configurado según el pilar.

Observaciones

Solo se soporta una página default, no se usan vhosts adicionales.

Los certificados SSL se generan automáticamente y son autofirmados para pruebas.

El reboot final es necesario para aplicar cambios de red; puede tardar si se usan estados largos como dhparam.

Puedes personalizar el contenido de index.html.jinja y los parámetros de seguridad de Nginx en ssl-params.conf.
