# ============================================================
# MariaDB - Gestión de Base de Datos Centralizada (MINIONBDD)
# ============================================================

# Extracción de credenciales de Zabbix desde Pillar
{% set zabbix_db_name = salt["pillar.get"]("zabbix:db_name", "zabbix") %}
{% set zabbix_db_user = salt["pillar.get"]("zabbix:db_user", "zabbix") %}
{% set zabbix_db_pass = salt["pillar.get"]("zabbix:db_pass", "Unclick2026") %}
{% set saltlogger_pass = salt["pillar.get"]("restic:mysql:password", salt["pillar.get"]("mysql:password", "Unclick2026")) %}

# Instalación del servidor MariaDB
mariadb_server_installed:
  pkg.installed:
    - name: mariadb-server

# Instalación del cliente MariaDB para gestión local
mariadb_client_installed:
  pkg.installed:
    - name: mariadb-client

# Instalación de librerías Python para que Salt pueda gestionar SQL
python_mysql:
  pkg.installed:
    - name: python3-mysqldb

# Restaura ficheros de configuracion de MariaDB si el minion fue limpiado
# manualmente pero el paquete sigue marcado como instalado.
restore_mariadb_server_config:
  cmd.run:
    - name: apt-get install --reinstall -y -o Dpkg::Options::="--force-confmiss" mariadb-server
    - unless: test -f /etc/mysql/mariadb.conf.d/50-server.cnf
    - require:
      - pkg: mariadb_server_installed

# Permite conexiones desde cualquier IP (necesario para el servidor Zabbix remoto)
mariadb_bind_address:
  file.replace:
    - name: /etc/mysql/mariadb.conf.d/50-server.cnf
    - pattern: "^\\s*#?\\s*bind-address\\s*=.*"
    - repl: "bind-address = 0.0.0.0"
    - ignore_if_missing: True
    - require:
      - cmd: restore_mariadb_server_config

# Asegura que el servicio MariaDB esté activo y se reinicie al cambiar el bind-address
mariadb_service_running:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: mariadb_server_installed
      - file: mariadb_bind_address
    - watch:
      - file: mariadb_bind_address

# Configura la contraseña del usuario root (usa ALTER USER para compatibilidad moderna)
set_root_password:
  cmd.run:
    - name: |
        mysql -u root -e "
          ALTER USER \"root\"@\"localhost\" IDENTIFIED VIA mysql_native_password USING PASSWORD(\"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}\");
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}" -e "SELECT 1" 2>/dev/null
    - require:
      - service: mariadb_service_running

# CREACIÓN DE LA BASE DE DATOS ZABBIX: Crea la DB, el usuario y otorga permisos remotos
create_zabbix_db:
  cmd.run:
    - name: |
        mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}" -e "
          CREATE DATABASE IF NOT EXISTS {{ zabbix_db_name }} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
          CREATE USER IF NOT EXISTS \"{{ zabbix_db_user }}\"@\"%\" IDENTIFIED BY \"{{ zabbix_db_pass }}\";
          ALTER USER \"{{ zabbix_db_user }}\"@\"%\" IDENTIFIED BY \"{{ zabbix_db_pass }}\";
          GRANT ALL PRIVILEGES ON {{ zabbix_db_name }}.* TO \"{{ zabbix_db_user }}\"@\"%\";
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u {{ zabbix_db_user }} -p"{{ zabbix_db_pass }}" -e "status"
    - require:
      - cmd: set_root_password

# Crea la base de datos de logs para el sistema de backups
create_salt_logs_db:
  cmd.run:
    - name: mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}" -e "CREATE DATABASE IF NOT EXISTS salt_logs;"
    - unless: mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}" -e "USE salt_logs;" 2>/dev/null
    - require:
      - cmd: set_root_password

# Crea el usuario 'saltlogger' con permisos de red
create_saltlogger_user:
  cmd.run:
    - name: |
        mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}" -e "
          CREATE USER IF NOT EXISTS \"saltlogger\"@\"%\" IDENTIFIED BY \"{{ saltlogger_pass }}\";
          ALTER USER \"saltlogger\"@\"%\" IDENTIFIED BY \"{{ saltlogger_pass }}\";
          GRANT ALL PRIVILEGES ON salt_logs.* TO \"saltlogger\"@\"%\";
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u saltlogger -p"{{ saltlogger_pass }}" -h 127.0.0.1 -e "SELECT 1" 2>/dev/null
    - require:
      - cmd: create_salt_logs_db

# Crea la tabla de eventos de backup con índices para búsquedas rápidas
create_backup_table:
  cmd.run:
    - name: |
        mysql -u saltlogger -p"{{ saltlogger_pass }}" -h 127.0.0.1 salt_logs -e "
          CREATE TABLE IF NOT EXISTS machine_backups (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hostname VARCHAR(255) NOT NULL,
            backup_path VARCHAR(512) NOT NULL,
            status ENUM(\"success\", \"fail\") NOT NULL,
            execution_time DATETIME NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_hostname (hostname),
            INDEX idx_status (status),
            INDEX idx_execution_time (execution_time)
          ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        "
    - unless: mysql -u saltlogger -p"{{ saltlogger_pass }}" -h 127.0.0.1 salt_logs -e "DESCRIBE machine_backups;" 2>/dev/null
    - require:
      - cmd: create_saltlogger_user

# CREACIÓN DE LA BASE DE DATOS WORDPRESS
create_wordpress_db:
  cmd.run:
    - name: |
        mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "Unclick2026") }}" -e "
          CREATE DATABASE IF NOT EXISTS {{ salt["pillar.get"]("wordpress:db_name", "wordpress") }};
          CREATE USER IF NOT EXISTS \"{{ salt["pillar.get"]("wordpress:db_user", "wordpress") }}\"@\"%\" IDENTIFIED BY \"{{ salt["pillar.get"]("wordpress:db_pass", "WordPress_2026!") }}\";
          CREATE USER IF NOT EXISTS \"{{ salt["pillar.get"]("wordpress:db_user", "wordpress") }}\"@\"localhost\" IDENTIFIED BY \"{{ salt["pillar.get"]("wordpress:db_pass", "WordPress_2026!") }}\";
          ALTER USER \"{{ salt["pillar.get"]("wordpress:db_user", "wordpress") }}\"@\"%\" IDENTIFIED BY \"{{ salt["pillar.get"]("wordpress:db_pass", "WordPress_2026!") }}\";
          ALTER USER \"{{ salt["pillar.get"]("wordpress:db_user", "wordpress") }}\"@\"localhost\" IDENTIFIED BY \"{{ salt["pillar.get"]("wordpress:db_pass", "WordPress_2026!") }}\";
          GRANT ALL PRIVILEGES ON {{ salt["pillar.get"]("wordpress:db_name", "wordpress") }}.* TO \"{{ salt["pillar.get"]("wordpress:db_user", "wordpress") }}\"@\"%\";
          GRANT ALL PRIVILEGES ON {{ salt["pillar.get"]("wordpress:db_name", "wordpress") }}.* TO \"{{ salt["pillar.get"]("wordpress:db_user", "wordpress") }}\"@\"localhost\";
          FLUSH PRIVILEGES;
        "
    - require:
      - cmd: set_root_password
