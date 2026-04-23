# Pillar data para el servidor Zabbix (MINIONZABBIX)
zabbix:
  server_ip: "192.168.0.4"
  server_port: 10051
  agent_port: 10050
  frontend_alias: "monitor.serverweb.com"
  db_host: "192.168.0.5"
  db_port: 3306
  db_name: "zabbix"
  db_user: "zabbix"
  db_pass: "Unclick2026"
  mysql_root_password: "Unclick2026"
  monitored_hosts:
    - hostname: "Zabbix Server"
      ip: "192.168.0.4"
      type: "server"
    - hostname: "minion_prueba"
      ip: "192.168.0.3"
      type: "agent"
