# -------------------------------
# Instalar nginx
# -------------------------------
instalación_nginx:
  pkg.installed:
    - name: nginx
    - enable: True

# -------------------------------
# Crear directorio webroot desde pillar
# -------------------------------
crear_webroot:
  file.directory:
    - name: {{ pillar['web-server']['webroot'] }}
    - user: www-data
    - group: www-data
    - mode: 755
    - makedirs: True

# -------------------------------
# Crear página default
# -------------------------------
index_web:
  file.managed:
    - name: {{ pillar['web-server']['webroot'] }}/index.html
    - source: salt://webserver/files/index.html.jinja
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 644
    - require:
      - file: crear_webroot

# -------------------------------
# Configuración nginx
# -------------------------------
nginx_conf:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://webserver/files/default.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalación_nginx

# -------------------------------
# Instalar SSH
# -------------------------------
instalación_ssh:
  pkg.installed:
    - name: openssh-server

# -------------------------------
# Configuración SSH desde pillar
# -------------------------------
ssh_conf:
  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://webserver/files/sshd_config.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalación_ssh

# -------------------------------
# Reiniciar servicio SSH si cambia configuración
# -------------------------------
ssh_service:
  service.running:
    - name: ssh
    - enable: True
    - reload: True
    - watch:
      - file: ssh_conf

# -------------------------------
# Crear certificados SSL
# -------------------------------
certificado_ssl:
  cmd.run:
    - name: >
        openssl req -x509 -nodes -days 365
        -newkey rsa:2048
        -keyout /etc/ssl/private/{{ pillar['web-server']['ssl']['key'] }}
        -out /etc/ssl/certs/{{ pillar['web-server']['ssl']['cert'] }}
        -subj "/C=ES/ST=Barcelona/L=Castelldefels/O=Server/CN={{ pillar['web-server']['domain'] }}"
    - unless: test -f /etc/ssl/private/{{ pillar['web-server']['ssl']['key'] }}

# -------------------------------
# Generar dhparam para nginx
# -------------------------------
dhparam:
  cmd.run:
    - name: openssl dhparam -out /etc/nginx/dhparam.pem 2048
    - unless: test -f /etc/nginx/dhparam.pem

# -------------------------------
# Snippets SSL
# -------------------------------
snippets_ssl:
  file.managed:
    - name: /etc/nginx/snippets/ssl-params.conf
    - source: salt://webserver/ssl-params.conf
    - makedirs: True

# -------------------------------
# Aplicar cambios en nginx
# -------------------------------
aplicar_nginx:
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - file: nginx_conf
      - file: index_web
      - cmd: certificado_ssl
      - cmd: dhparam
      - file: snippets_ssl

# -------------------------------
# Script de autohosting
# -------------------------------
script_sw:
  file.managed:
    - name: /root/Scripts/autohosting.sh
    - source: salt://webserver/autohosting.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

# -------------------------------
# Configuración interfaces desde pillar
# -------------------------------
interfaces_conf:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://webserver/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# -------------------------------
# Enviar Readme intrucciones del servicio
# -------------------------------
webserver_readme:
  file.managed:
    - name: /Instrucciones/README.md
    - source: salt://webserver/manual.md

# -------------------------------
# Aplicar cambios de red con reboot
# -------------------------------
aplicar_cambios:
  cmd.run:
    - name: reboot
    - require:
      - file: interfaces_conf
