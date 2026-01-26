#INSTALAMOS LOS PAQUETES NECESARIOS
mariadb-server:
  pkg.installed:
    - name: mariadb-server

python3-pip:
  pkg.installed

#BINDINGS PYTHON PARA SALT
pymysql:
  pip.installed:
    - name: PyMySQL
    - require:
      - pkg: python3-pip

#SERVICIO MYSQL
mariadb@.service:
  service.running:
    - name: mysql
    - enable: True
    - require:
      - pkg: mariadb-server

#BASE DE DATOS
crear_basedatos:
  mysql_database.present:
    - name: ejemplo_db
    - connecion_user: root
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
    - connection_backend: PyMySQL
    - require:
      - service: mariadb@.service
      - pip: pymysql

#USUARIO MYSQL
crear_usuario:
  mysql_user.present:
    - name: ejemplo_user
    - host: localhost
    - password: '326Edwin'
    - connection_user: root
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
    - connection_backend: PyMySQL
    - require:
      - mysql_database: crear_basedatos

#PRIVILEGIOS
permisos_usuario:
  mysql_grants.present:
    - grant: all privileges
    - database: ejemplo_db.*
    - user: ejemplo_user
    - host: localhost
    - connection_user: root
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
    - connection_backend: PyMySQL
    - require:
      - mysql_user: crear_usuario
