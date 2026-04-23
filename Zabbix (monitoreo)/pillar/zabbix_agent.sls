# Pillar data para los agentes Zabbix (minions monitorizados)
# ============================================================
# Configuración del agente Zabbix que se despliega en cada
# host que será monitorizado por el servidor Zabbix.
# ============================================================

zabbix:
  # IP del servidor Zabbix (MINIONZABBIX)
  server_ip: "192.168.0.4"

  # Puerto del agente
  agent_port: 10050

  # El hostname se obtiene automáticamente del grain "host"
  # del minion. No es necesario especificarlo aquí a menos
  # que se quiera sobrescribir.
  # agent_hostname: "nombre_personalizado"
