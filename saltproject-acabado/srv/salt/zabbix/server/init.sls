{% set server_ip = salt['pillar.get']('zabbix:server_ip', '192.168.0.4') %}
{% set db_host   = salt['pillar.get']('zabbix:db_host',   '192.168.0.5') %}
{% set db_port   = salt['pillar.get']('zabbix:db_port',   '3306') %}
{% set db_name   = salt['pillar.get']('zabbix:db_name',   'zabbix') %}
{% set db_user   = salt['pillar.get']('zabbix:db_user',   'zabbix') %}
{% set db_pass   = salt['pillar.get']('zabbix:db_pass',   'zabbix') %}

zabbix_server_pkgs:
  pkg.installed:
    - pkgs:
      - zabbix-server-mysql
      - zabbix-frontend-php
      - zabbix-agent
      - mariadb-client
      - php-mysql
      - apache2
      - libapache2-mod-php
      - locales
      - fping

locales_present:
  locale.present:
    - names:
      - en_US.UTF-8
      - es_ES.UTF-8

locale_gen:
  cmd.run:
    - name: locale-gen en_US.UTF-8 es_ES.UTF-8
    - unless: locale -a | grep -q es_ES.utf8

zabbix_log_dir:
  file.directory:
    - name: /var/log/zabbix
    - user: zabbix
    - group: zabbix
    - mode: "0755"
    - makedirs: True

zabbix_server_etc_dir:
  file.directory:
    - name: /etc/zabbix
    - user: root
    - group: root
    - mode: "0755"
    - makedirs: True
    - require:
      - pkg: zabbix_server_pkgs

zabbix_wait_for_db:
  cmd.run:
    - name: |
        for i in $(seq 1 60); do
          mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} -e "SELECT 1;" >/dev/null 2>&1 && exit 0
          sleep 5
        done
        echo "Zabbix database {{ db_name }} on {{ db_host }}:{{ db_port }} is not reachable" >&2
        exit 1
    - unless: mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} -e "SELECT 1 FROM users LIMIT 1;" 2>/dev/null
    - require:
      - pkg: zabbix_server_pkgs

zabbix_schema_import:
  cmd.run:
    - name: |
        zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} &&
        zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} &&
        zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }}
    - unless: mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} -e "SELECT 1 FROM users LIMIT 1;" 2>/dev/null
    - require:
      - pkg: zabbix_server_pkgs
      - cmd: zabbix_wait_for_db

zabbix_set_spanish:
  cmd.run:
    - name: mysql -h {{ db_host }} -P {{ db_port }} -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} -e "UPDATE users SET lang = 'es_ES' WHERE username = 'Admin';"
    - require:
      - cmd: zabbix_schema_import

zabbix_server_conf:
  file.managed:
    - name: /etc/zabbix/zabbix_server.conf
    - source: salt://zabbix/server/zabbix_server.conf
    - user: root
    - group: root
    - mode: "0644"
    - template: jinja
    - require:
      - file: zabbix_server_etc_dir

zabbix_web_config_dir:
  file.directory:
    - name: /etc/zabbix/web
    - user: www-data
    - group: www-data
    - mode: "0775"
    - require:
      - file: zabbix_server_etc_dir

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

zabbix_php_settings:
  cmd.run:
    - name: |
        PHP_INI=$(find /etc/php -name php.ini -path "*/apache2/*" 2>/dev/null | head -1)
        if [ -n "$PHP_INI" ]; then
          sed -i 's/^;*post_max_size =.*/post_max_size = 16M/' "$PHP_INI"
          sed -i 's/^;*max_execution_time =.*/max_execution_time = 300/' "$PHP_INI"
          sed -i 's/^;*max_input_time =.*/max_input_time = 300/' "$PHP_INI"
        fi
    - require:
      - pkg: zabbix_server_pkgs

zabbix_php_mysql_modules:
  cmd.run:
    - name: phpenmod mysqli pdo_mysql
    - unless: php -m | grep -Eiq '^(mysqli|pdo_mysql)$'
    - require:
      - pkg: zabbix_server_pkgs

zabbix_server_service:
  service.running:
    - name: zabbix-server
    - enable: True
    - watch:
      - file: zabbix_server_conf

zabbix_apache_config_enable:
  cmd.run:
    - name: a2enconf zabbix-frontend-php || a2enconf zabbix-server-mysql || true
    - require:
      - pkg: zabbix_server_pkgs

zabbix_apache_php_repair:
  cmd.run:
    - name: |
        PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.2")
        a2dismod mpm_event || true
        a2enmod mpm_prefork || true
        apt-get install --reinstall -y -o Dpkg::Options::="--force-confmiss" libapache2-mod-php${PHP_VER} 2>/dev/null || apt-get install --reinstall -y libapache2-mod-php
        ln -sf /etc/apache2/mods-available/php${PHP_VER}.load /etc/apache2/mods-enabled/ 2>/dev/null || true
        ln -sf /etc/apache2/mods-available/php${PHP_VER}.conf /etc/apache2/mods-enabled/ 2>/dev/null || true
    - unless: apache2ctl -M 2>/dev/null | grep -q php
    - require:
      - pkg: zabbix_server_pkgs

apache2_service:
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - file: /etc/zabbix/web/zabbix.conf.php
      - file: /etc/zabbix/zabbix.conf.php
      - cmd: zabbix_php_mysql_modules
      - cmd: zabbix_apache_php_repair

zabbix_verify_server_script:
  file.managed:
    - name: /usr/local/bin/zabbix_verify.sh
    - source: salt://zabbix/server/zabbix_verify.sh
    - user: root
    - group: root
    - mode: "0750"
    - template: jinja
    - require:
      - pkg: zabbix_server_pkgs
