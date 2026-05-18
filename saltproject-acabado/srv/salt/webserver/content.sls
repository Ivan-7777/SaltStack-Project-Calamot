instalar_apache:
  pkg.installed:
    - name: apache2

instalar_php:
  pkg.installed:
    - name: php
    - pkgs:
      - php
      - libapache2-mod-php
      - php-mysql

habilitar_php_apache:
  cmd.run:
    - name: |
        PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "")
        a2dismod mpm_event >/dev/null 2>&1 || true
        a2enmod mpm_prefork >/dev/null 2>&1 || true
        if [ -n "$PHP_VER" ]; then
          a2enmod php${PHP_VER}
        else
          a2enmod php*
        fi
    - unless: apache2ctl -M 2>/dev/null | grep -q php
    - require:
      - pkg: instalar_php

crear_webroot:
  file.directory:
    - name: {{ pillar['web-server']['webroot'] }}
    - user: www-data
    - group: www-data
    - mode: 755
    - makedirs: True
    - require:
      - pkg: instalar_apache

configurar_vhost:
  file.managed:
    - name: /etc/apache2/sites-available/server.es.conf
    - contents: |
        <VirtualHost *:80>
            ServerName {{ pillar['web-server']['domain'] }}
            DocumentRoot {{ pillar['web-server']['webroot'] }}
            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined
            <Directory {{ pillar['web-server']['webroot'] }}>
                Options FollowSymLinks
                AllowOverride All
                Require all granted
            </Directory>
            <LocationMatch "^/(wp-admin/|wp-login\.php|xmlrpc\.php)">
                Require ip 127.0.0.1
                Require ip {{ pillar['firewall']['lan']['ip'] }}/{{ pillar['firewall']['lan']['mask'] }}
                Require ip 10.66.66.0/24
            </LocationMatch>
        </VirtualHost>
    - require:
      - pkg: instalar_apache

habilitar_vhost:
  cmd.run:
    - name: a2ensite server.es.conf && a2dissite 000-default.conf
    - unless: test -L /etc/apache2/sites-enabled/server.es.conf && ! test -L /etc/apache2/sites-enabled/000-default.conf
    - require:
      - file: configurar_vhost

index_php:
  file.managed:
    - name: {{ pillar['web-server']['webroot'] }}/index.php
    - contents: |
        <h1>Hola desde {{ pillar['web-server']['domain'] }}</h1>
        <?php phpinfo(); ?>
    - user: www-data
    - group: www-data
    - mode: 644
    - require:
      - file: crear_webroot
    - unless: test -f {{ pillar['web-server']['webroot'] }}/wp-load.php

apache_service:
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - file: configurar_vhost
      - cmd: habilitar_vhost
      - cmd: habilitar_php_apache
