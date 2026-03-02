# --------------------------------------------------------
# Estado para crear la base de datos MariaDB central y tablas
# --------------------------------------------------------

# Instalar Paquetes necesarios
mariadb-server:
  pkg.installed: []

python3-pip:
  pkg.installed

#BINDINGS PYTHON PARA SALT
pymysql:
  pip.installed:
    - name: PyMySQL
    - require:
      - pkg: python3-pip


# Iniciar el servicio de MariaDB
mariadb-service:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: mariadb-server

# Crear la base de datos 'salt_logs'
crear_basedatos:
  mysql_database.present:
    - name: salt_logs
    - connecion_user: root
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
    - connection_backend: PyMySQL

# Crear usuario 'saltlogger' con permisos mínimos
crear_usuario_saltlogger:
  cmd.run:
    - name: >
        mysql -u root -pYOUR_ROOT_PASSWORD -e "
        CREATE USER IF NOT EXISTS 'saltlogger'@'%' IDENTIFIED BY 'PASSWORD_SEGURA';
        CREATE USER IF NOT EXISTS 'saltlogger'@'localhost' IDENTIFIED BY 'PASSWORD_SEGURA';
        GRANT INSERT, SELECT, CREATE, ALTER ON salt_logs.* TO 'saltlogger'@'%';
        GRANT INSERT, SELECT, CREATE, ALTER ON salt_logs.* TO 'saltlogger'@'localhost';
        FLUSH PRIVILEGES;"

# Crear tabla para logs de ejecución de estados
crear_tabla_logs:
  cmd.run:
    - name: >
        mysql -u root -pYOUR_ROOT_PASSWORD -D salt_logs -e "
        CREATE TABLE IF NOT EXISTS salt_state_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hostname VARCHAR(255),
            state_name VARCHAR(255),
            result BOOLEAN,
            changes TEXT,
            execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );"

# Crear tabla para backups de máquinas
crear_tabla_backups:
  cmd.run:
    - name: >
        mysql -u root -pYOUR_ROOT_PASSWORD -D salt_logs -e "
        CREATE TABLE IF NOT EXISTS machine_backups (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hostname VARCHAR(255),
            backup_path TEXT,
            status VARCHAR(50),
            execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );"
