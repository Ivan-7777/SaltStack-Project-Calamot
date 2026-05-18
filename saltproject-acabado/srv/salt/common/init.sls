{% set node = salt['pillar.get']('network_nodes:' ~ grains['id'], {}) %}
{% set interfaces = node.get('interfaces', []) if node else [] %}
{% set salt_master_ip = node.get('salt_master_ip', salt['config.get']('master', '192.168.0.3')) if node else salt['config.get']('master', '192.168.0.3') %}

{% if interfaces %}
common_apt_force_ipv4:
  file.managed:
    - name: /etc/apt/apt.conf.d/99force-ipv4
    - user: root
    - group: root
    - mode: 644
    - contents: 'Acquire::ForceIPv4 "true";'

common_salt_master_config:
  file.replace:
    - name: /etc/salt/minion
    - pattern: '^master:.*'
    - repl: 'master: {{ salt_master_ip }}'
    - append_if_not_found: True

common_network_interfaces_d_clean:
  file.directory:
    - name: /etc/network/interfaces.d
    - user: root
    - group: root
    - mode: 755
    - clean: True

common_network_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - user: root
    - group: root
    - mode: 644
    - contents: |
        source /etc/network/interfaces.d/*

        auto lo
        iface lo inet loopback

{% for iface in interfaces %}
        auto {{ iface.get('name', 'enp0s3') }}
        allow-hotplug {{ iface.get('name', 'enp0s3') }}
        iface {{ iface.get('name', 'enp0s3') }} inet static
            pre-up ip addr flush dev {{ iface.get('name', 'enp0s3') }} || true
            address {{ iface.get('ip') }}/{{ iface.get('mask', 24) }}
{% if iface.get('gateway') %}
            gateway {{ iface.get('gateway') }}
{% endif %}
{% if iface.get('dns') %}
            dns-nameservers {{ iface.get('dns') }}
{% endif %}

{% endfor %}
    - require:
      - file: common_network_interfaces_d_clean

common_network_runtime_apply:
  cmd.run:
    - name: |
        set -e
{% for iface in interfaces %}
        ip link set {{ iface.get('name', 'enp0s3') }} up
        ip -4 addr flush dev {{ iface.get('name', 'enp0s3') }} scope global || true
        ip addr add {{ iface.get('ip') }}/{{ iface.get('mask', 24) }} dev {{ iface.get('name', 'enp0s3') }}
{% if iface.get('gateway') %}
        ip route replace {{ salt_master_ip }}/32 dev {{ iface.get('name', 'enp0s3') }}
        ip route replace default via {{ iface.get('gateway') }} dev {{ iface.get('name', 'enp0s3') }} onlink
{% endif %}
{% endfor %}
    - require:
      - file: common_network_interfaces

common_networking_service_restart:
  cmd.run:
    - name: |
        systemd-run --unit=salt-delayed-networking-restart --on-active=180s /bin/systemctl restart networking.service >/dev/null 2>&1 || \
        nohup sh -c 'sleep 180; systemctl restart networking.service' >/dev/null 2>&1 &
    - onchanges:
      - file: common_network_interfaces_d_clean
      - file: common_network_interfaces
    - require:
      - cmd: common_network_runtime_apply

common_salt_minion_delayed_restart:
  cmd.run:
    - name: |
        systemd-run --unit=salt-delayed-minion-restart --on-active=240s /bin/systemctl restart salt-minion.service >/dev/null 2>&1 || \
        nohup sh -c 'sleep 240; systemctl restart salt-minion.service' >/dev/null 2>&1 &
    - onchanges:
      - file: common_salt_master_config
      - file: common_network_interfaces_d_clean
      - file: common_network_interfaces
{% else %}
common_network_noop:
  test.nop:
    - name: "No network_nodes entry for {{ grains['id'] }}"
{% endif %}
