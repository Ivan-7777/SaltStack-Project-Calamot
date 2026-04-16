# ============================================================
# Estado del Servidor MariaDB (MINIONBDD)
# ============================================================
# Este estado instala y configura el servidor MariaDB que
# almacena los registros de backup de todos los minions.
#
# Funcionalidades:
#   - Instala el servidor MariaDB
#   - Inicia y habilita el servicio
#   - Configura contraseña de root
#   - Crea la base de datos salt_logs
#   - Crea el usuario saltlogger con permisos
#   - Crea la tabla machine_backups para registros
# ============================================================

# --- 1. Instalar servidor MariaDB ---
mariadb_server_installed:
  pkg.installed:
    - name: mariadb-server

mariadb_client_installed:
  pkg.installed:
    - name: mariadb-client

python_mysql:
  pkg.installed:
    - name: python3-mysqldb

# --- 2. Configurar MariaDB para escuchar en todas las interfaces ---
# Por defecto solo escucha en 127.0.0.1. Los clientes necesitan acceso remoto.
mariadb_bind_address:
  file.replace:
    - name: /etc/mysql/mariadb.conf.d/50-server.cnf
    - pattern: '^bind-address\s*=\s*127\.0\.0\.1'
    - repl: 'bind-address = 0.0.0.0'
    - require:
      - pkg: mariadb_server_installed

mariadb_service_running:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: mariadb_server_installed
      - file: mariadb_bind_address
    - watch:
      - file: mariadb_bind_address

# --- 3. Configurar autenticación de root con contraseña ---
# En Debian 13, MariaDB usa unix_socket por defecto.
# Primero establecemos la contraseña de root mediante el socket unix.
set_root_password:
  cmd.run:
    - name: |
        mysql -u root -e "
          ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('{{ pillar['mysql']['root_password'] }}');
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u root -p"{{ pillar['mysql']['root_password'] }}" -e "SELECT 1" 2>/dev/null
    - require:
      - service: mariadb_service_running

# --- 4. Crear base de datos para logs ---
create_salt_logs_db:
  cmd.run:
    - name: mysql -u root -p"{{ pillar['mysql']['root_password'] }}" -e "CREATE DATABASE IF NOT EXISTS salt_logs;"
    - unless: mysql -u root -p"{{ pillar['mysql']['root_password'] }}" -e "USE salt_logs;" 2>/dev/null
    - require:
      - cmd: set_root_password

# --- 5. Crear usuario saltlogger ---
create_saltlogger_user:
  cmd.run:
    - name: |
        mysql -u root -p"{{ pillar['mysql']['root_password'] }}" -e "
          CREATE USER IF NOT EXISTS 'saltlogger'@'%' IDENTIFIED BY '{{ pillar['mysql']['password'] }}';
          GRANT ALL PRIVILEGES ON salt_logs.* TO 'saltlogger'@'%';
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u saltlogger -p"{{ pillar['mysql']['password'] }}" -h 127.0.0.1 -e "SELECT 1" 2>/dev/null
    - require:
      - cmd: create_salt_logs_db

# --- 6. Crear tabla machine_backups ---
create_backup_table:
  cmd.run:
    - name: |
        mysql -u saltlogger -p"{{ pillar['mysql']['password'] }}" -h 127.0.0.1 salt_logs -e "
          CREATE TABLE IF NOT EXISTS machine_backups (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hostname VARCHAR(255) NOT NULL,
            backup_path VARCHAR(512) NOT NULL,
            status ENUM('success', 'fail') NOT NULL,
            execution_time DATETIME NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_hostname (hostname),
            INDEX idx_status (status),
            INDEX idx_execution_time (execution_time)
          ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        "
    - unless: mysql -u saltlogger -p"{{ pillar['mysql']['password'] }}" -h 127.0.0.1 salt_logs -e "DESCRIBE machine_backups;" 2>/dev/null
    - require:
      - cmd: create_saltlogger_user
