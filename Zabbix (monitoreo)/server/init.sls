# ============================================================
# Zabbix Server - Estado de Instalación y Configuración
# ============================================================

# Definición de variables dinámicas obtenidas desde Pillar (configuración centralizada)
{% set server_ip = salt['pillar.get']('zabbix:server_ip', '192.168.0.4') %}
{% set db_host = salt['pillar.get']('zabbix:db_host', '192.168.0.5') %}
{% set db_port = salt['pillar.get']('zabbix:db_port', '3306') %}
{% set db_name = salt['pillar.get']('zabbix:db_name', 'zabbix') %}
{% set db_user = salt['pillar.get']('zabbix:db_user', 'zabbix') %}
{% set db_pass = salt['pillar.get']('zabbix:db_pass', 'Unclick2026') %}

# Instalación de paquetes necesarios para el servidor y el frontend web
zabbix_server_pkgs:
  pkg.installed:
    - pkgs:
      - zabbix-server-mysql    # Motor del servidor Zabbix
      - zabbix-frontend-php    # Interfaz web PHP
      - zabbix-agent           # Agente local para auto-monitorización
      - mariadb-client         # Cliente para ejecutar comandos SQL
      - apache2                # Servidor web
      - libapache2-mod-php     # Módulo de integración PHP-Apache
      - locales                # Soporte para idiomas

# Configuración de los 'locales' del sistema (necesario para el idioma español en la web)
locales_present:
  locale.present:
    - names:
      - en_US.UTF-8
      - es_ES.UTF-8
  cmd.run:
    - name: locale-gen en_US.UTF-8 es_ES.UTF-8
    - unless: locale -a | grep -q es_ES.utf8

# Creación del directorio de logs con permisos para el usuario zabbix
zabbix_log_dir:
  file.directory:
    - name: /var/log/zabbix
    - user: zabbix
    - group: zabbix
    - mode: "0755"
    - makedirs: True

# Importación del esquema de base de datos inicial (solo si la tabla 'users' no existe)
zabbix_schema_import:
  cmd.run:
    - name: |
        zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} && \
        zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} && \
        zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }}
    - unless: mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} -e "SELECT 1 FROM users LIMIT 1;"
    - require:
      - pkg: zabbix_server_pkgs

# Configuración automática del idioma Español para el usuario Admin en la base de datos
zabbix_set_spanish:
  cmd.run:
    - name: mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} -e "UPDATE users SET lang = 'es_ES' WHERE username = 'Admin';"
    - require:
      - cmd: zabbix_schema_import

# Gestión del archivo de configuración del servidor Zabbix (inyecta la IP de la BDD)
zabbix_server_conf:
  file.managed:
    - name: /etc/zabbix/zabbix_server.conf
    - source: salt://zabbix/server/zabbix_server.conf
    - user: root
    - group: root
    - mode: "0644"
    - template: jinja
    - require:
      - pkg: zabbix_server_pkgs

# Preparación del directorio de configuración de la interfaz web
zabbix_web_config_dir:
  file.directory:
    - name: /etc/zabbix/web
    - user: www-data
    - group: www-data
    - mode: "0775"
    - require:
      - pkg: zabbix_server_pkgs

# Creación de los archivos de configuración PHP de la web (en ambas rutas posibles para evitar fallos)
{% for config_file in ['/etc/zabbix/web/zabbix.conf.php', '/etc/zabbix/zabbix.conf.php'] %}
zabbix_web_config_{{ loop.index }}:
  file.managed:
    - name: {{ config_file }}
    - user: www-data
    - group: www-data
    - mode: "0644"
    - template: jinja
    - contents: |
        <?php
        // Archivo de configuración generado por SaltStack
        $DB["TYPE"]     = "MYSQL";
        $DB["SERVER"]   = "{{ db_host }}";
        $DB["PORT"]     = "{{ db_port }}";
        $DB["DATABASE"] = "{{ db_name }}";
        $DB["USER"]     = "{{ db_user }}";
        $DB["PASSWORD"] = "{{ db_pass }}";
        $DB["SCHEMA"]   = "";
        $DB["ENCRYPTION"] = false;
        $DB["KEY_FILE"]   = "";
        $DB["CERT_FILE"]  = "";
        $DB["CA_FILE"]    = "";
        $ZBX_SERVER      = "{{ server_ip }}";
        $ZBX_SERVER_PORT = "10051";
        $ZBX_SERVER_NAME = "Zabbix Server";
        $IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
    - require:
      - file: zabbix_web_config_dir
{% endfor %}

# Ajustes obligatorios en php.ini para que Zabbix funcione sin errores de memoria o tiempo
zabbix_php_post_max_size:
  file.replace:
    - name: /etc/php/8.4/apache2/php.ini
    - pattern: "^;?post_max_size =.*"
    - repl: "post_max_size = 16M"
    - require:
      - pkg: zabbix_server_pkgs

zabbix_php_max_execution_time:
  file.replace:
    - name: /etc/php/8.4/apache2/php.ini
    - pattern: "^;?max_execution_time =.*"
    - repl: "max_execution_time = 300"
    - require:
      - pkg: zabbix_server_pkgs

zabbix_php_max_input_time:
  file.replace:
    - name: /etc/php/8.4/apache2/php.ini
    - pattern: "^;?max_input_time =.*"
    - repl: "max_input_time = 300"
    - require:
      - pkg: zabbix_server_pkgs

# Asegura que el servicio del servidor Zabbix esté arrancado y habilitado
zabbix_server_service:
  service.running:
    - name: zabbix-server
    - enable: True
    - watch:
      - file: zabbix_server_conf

# Habilita la configuración de Zabbix en el servidor Apache
zabbix_apache_config_enable:
  cmd.run:
    - name: a2enconf zabbix-frontend-php || a2enconf zabbix-server-mysql || true
    - require:
      - pkg: zabbix_server_pkgs

# REPARACIÓN ROBUSTA: Fuerza el motor PHP-MPM adecuado para evitar ver código fuente en el navegador
zabbix_apache_php_repair:
  cmd.run:
    - name: |
        a2dismod mpm_event      # Desactiva el módulo incompatible
        a2enmod mpm_prefork     # Activa el módulo compatible con PHP-Apache
        apt-get install --reinstall -y -o Dpkg::Options::='--force-confmiss' libapache2-mod-php8.4 # Restaura configs borradas
        ln -sf /etc/apache2/mods-available/php8.4.load /etc/apache2/mods-enabled/ # Enlaces directos por seguridad
        ln -sf /etc/apache2/mods-available/php8.4.conf /etc/apache2/mods-enabled/
    - unless: apache2ctl -M | grep -q php
    - require:
      - pkg: zabbix_server_pkgs

# Gestión del servicio Apache (servidor web)
apache2_service:
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - file: /etc/zabbix/web/zabbix.conf.php
      - file: /etc/zabbix/zabbix.conf.php
      - cmd: zabbix_apache_php_repair
