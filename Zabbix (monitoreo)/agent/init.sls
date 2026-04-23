# ============================================================
# Zabbix Agent - Estado de Monitorización de Clientes
# ============================================================

# Definición de variables globales para el agente
{% set zabbix_srv_ip   = salt["pillar.get"]("zabbix:server_ip", "192.168.0.4") %}
{% set zabbix_agent_port = salt["pillar.get"]("zabbix:agent_port", "10050") %}
{% set zabbix_hostname = salt["grains.get"]("id") %}

# Instalación del paquete del agente Zabbix y utilidades de red
zabbix_agent_pkg:
  pkg.installed:
    - pkgs:
      - zabbix-agent
      - fping

# Asegura que el directorio principal de configuración exista
zabbix_etc_dir:
  file.directory:
    - name: /etc/zabbix
    - user: root
    - group: root
    - mode: "0755"
    - makedirs: True
    - require:
      - pkg: zabbix_agent_pkg

# Crea el directorio de logs del agente
zabbix_agent_log_dir:
  file.directory:
    - name: /var/log/zabbix
    - user: zabbix
    - group: zabbix
    - mode: "0755"
    - makedirs: True
    - require:
      - pkg: zabbix_agent_pkg

# Gestiona el archivo de configuración principal (inyecta la IP del servidor)
zabbix_agent_conf:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf
    - source: salt://zabbix/agent/zabbix_agentd.conf
    - user: root
    - group: root
    - mode: "0644"
    - template: jinja
    - require:
      - file: zabbix_etc_dir

# Directorio para parámetros de monitorización adicionales
zabbix_agent_d_dir:
  file.directory:
    - name: /etc/zabbix/zabbix_agentd.d
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: zabbix_etc_dir

# Definición de UserParameters (métricas personalizadas para Zabbix)
zabbix_agent_monitoring_conf:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.d/monitoring.conf
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        # Comprobación de estado de servicios básicos
        UserParameter=service.ssh.status,systemctl is-active sshd >/dev/null 2>&1 && echo 1 || echo 0
        UserParameter=service.mariadb.status,systemctl is-active mariadb >/dev/null 2>&1 && echo 1 || echo 0
    - require:
      - file: zabbix_agent_d_dir

# Abre el puerto 10050 en el firewall local (UFW)
zabbix_open_firewall:
  cmd.run:
    - name: ufw allow {{ zabbix_agent_port }}/tcp 2>/dev/null || true
    - require:
      - pkg: zabbix_agent_pkg

# Despliega el script de verificación manual del agente
zabbix_verify_agent_script:
  file.managed:
    - name: /usr/local/bin/zabbix_agent_verify.sh
    - source: salt://zabbix/agent/zabbix_agent_verify.sh
    - user: root
    - group: root
    - mode: "0750"
    - template: jinja
    - require:
      - pkg: zabbix_agent_pkg

# Control del servicio del agente (arranque y reinicio automático)
zabbix_agent_service:
  service.running:
    - name: zabbix-agent
    - enable: True
    - require:
      - pkg: zabbix_agent_pkg
      - file: zabbix_agent_conf
      - file: zabbix_agent_log_dir
    - watch:
      - file: zabbix_agent_conf
