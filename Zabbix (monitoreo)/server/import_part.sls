zabbix_import_schema:
  cmd.run:
    - name: |
        zcat /usr/share/zabbix-server-mysql/schema.sql.gz | MYSQL_PWD='{{ zabbix_db_root }}' mysql -h {{ zabbix_db_host }} -u root {{ zabbix_db_name }}
        zcat /usr/share/zabbix-server-mysql/images.sql.gz | MYSQL_PWD='{{ zabbix_db_root }}' mysql -h {{ zabbix_db_host }} -u root {{ zabbix_db_name }}
        zcat /usr/share/zabbix-server-mysql/data.sql.gz | MYSQL_PWD='{{ zabbix_db_root }}' mysql -h {{ zabbix_db_host }} -u root {{ zabbix_db_name }}
    - unless: |
        MYSQL_PWD='{{ zabbix_db_root }}' mysql -h {{ zabbix_db_host }} -u root {{ zabbix_db_name }} -e "SELECT COUNT(*) FROM users;" 2>/dev/null
    - require:
      - cmd: zabbix_create_user
