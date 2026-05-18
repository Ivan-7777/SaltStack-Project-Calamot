{% set zabbix_srv_ip     = salt["pillar.get"]("zabbix:server_ip", "192.168.0.4") %}
{% set zabbix_agent_port = salt["pillar.get"]("zabbix:agent_port", "10050") %}
{% set zabbix_hostname   = salt["grains.get"]("id") %}
{% set minion_states     = salt["pillar.get"]("service_mapping:" ~ zabbix_hostname, []) %}
{% set enabled_services  = salt["pillar.get"]("enabled_services", {}) %}
{% set state_services = {
  "BDD": ["mariadb"],
  "dhcp": ["dnsmasq"],
  "dns": ["named"],
  "firewall": ["nftables"],
  "proxy": ["nginx"],
  "wordpress": ["apache2"],
  "webserver": ["apache2"],
  "wireguard": ["wg-quick@wg0", "nftables"],
  "zabbix.server": ["zabbix-server", "apache2"],
  "zabbix.agent": ["zabbix-agent"],
  "restic.server": ["restic-rest-server"]
} %}
{% set monitored_services = [] %}
{% for state in minion_states %}
{% for service_name in state_services.get(state, []) %}
{% if service_name not in monitored_services %}
{% do monitored_services.append(service_name) %}
{% endif %}
{% endfor %}
{% endfor %}
{% if "firewall" in minion_states and (enabled_services.get("dhcp", False) or enabled_services.get("proxy", False)) and "isc-dhcp-relay" not in monitored_services %}
{% do monitored_services.append("isc-dhcp-relay") %}
{% endif %}

zabbix_agent_pkg:
  pkg.installed:
    - pkgs:
      - zabbix-agent
      - fping

zabbix_etc_dir:
  file.directory:
    - name: /etc/zabbix
    - user: root
    - group: root
    - mode: "0755"
    - makedirs: True
    - require:
      - pkg: zabbix_agent_pkg

zabbix_agent_log_dir:
  file.directory:
    - name: /var/log/zabbix
    - user: zabbix
    - group: zabbix
    - mode: "0755"
    - makedirs: True
    - require:
      - pkg: zabbix_agent_pkg

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

zabbix_agent_d_dir:
  file.directory:
    - name: /etc/zabbix/zabbix_agentd.d
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: zabbix_etc_dir

zabbix_agent_monitoring_conf:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.d/monitoring.conf
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        UserParameter=service.ssh.status,systemctl is-active sshd >/dev/null 2>&1 && echo 1 || echo 0
        UserParameter=service.mariadb.status,systemctl is-active mariadb >/dev/null 2>&1 && echo 1 || echo 0
        UserParameter=service.status[*],systemctl is-active "$1" >/dev/null 2>&1 && echo 1 || echo 0
{% for service_name in monitored_services %}
        UserParameter=state.service.{{ service_name | replace("@", "_") | replace(".", "_") | replace("-", "_") }}.status,systemctl is-active {{ service_name }} >/dev/null 2>&1 && echo 1 || echo 0
{% endfor %}
    - require:
      - file: zabbix_agent_d_dir

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

zabbix_register_host_script:
  file.managed:
    - name: /usr/local/bin/zabbix_register_host.py
    - source: salt://zabbix/agent/zabbix_register_host.py
    - user: root
    - group: root
    - mode: "0750"
    - template: jinja
    - require:
      - pkg: zabbix_agent_pkg

zabbix_register_host_unit:
  file.managed:
    - name: /etc/systemd/system/zabbix-register-host.service
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        [Unit]
        Description=Register this host in Zabbix
        After=network-online.target zabbix-agent.service
        Wants=network-online.target

        [Service]
        Type=oneshot
        TimeoutStartSec=90
        ExecStart=/usr/local/bin/zabbix_register_host.py
    - require:
      - file: zabbix_register_host_script

zabbix_register_host_timer:
  file.managed:
    - name: /etc/systemd/system/zabbix-register-host.timer
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        [Unit]
        Description=Retry Zabbix host registration

        [Timer]
        OnBootSec=1min
        OnUnitActiveSec=5min
        Unit=zabbix-register-host.service
        Persistent=true

        [Install]
        WantedBy=timers.target
    - require:
      - file: zabbix_register_host_unit

zabbix_register_host_systemd_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: zabbix_register_host_unit
      - file: zabbix_register_host_timer

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
      - file: zabbix_agent_monitoring_conf

zabbix_register_host_timer_service:
  service.running:
    - name: zabbix-register-host.timer
    - enable: True
    - require:
      - cmd: zabbix_register_host_systemd_reload

zabbix_register_host_now:
  cmd.run:
    - name: systemctl reset-failed zabbix-register-host.service || true; systemctl start --no-block zabbix-register-host.service || true
    - require:
      - service: zabbix_agent_service
      - service: zabbix_register_host_timer_service
      - file: zabbix_register_host_script
