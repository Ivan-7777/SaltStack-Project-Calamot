{% set enabled = salt['pillar.get']('enabled_services', {}) %}
{% set enable_dhcp_relay = enabled.get('dhcp', False) or enabled.get('proxy', False) %}

aplicar_interfaces_firewall:
  cmd.run:
    - name: |
        set -e
        ip link set {{ pillar['firewall']['lan']['interface'] }} up
        ip link set {{ pillar['firewall']['dmz']['interface'] }} up
        ip addr add {{ pillar['firewall']['lan']['ip'] }}/{{ pillar['firewall']['lan']['mask'] }} dev {{ pillar['firewall']['lan']['interface'] }} 2>/dev/null || true
        ip addr del {{ pillar['firewall']['dmz']['ip'] }}/{{ pillar['firewall']['dmz']['mask'] }} dev {{ pillar['firewall']['lan']['interface'] }} 2>/dev/null || true
        ip addr add {{ pillar['firewall']['dmz']['ip'] }}/{{ pillar['firewall']['dmz']['mask'] }} dev {{ pillar['firewall']['dmz']['interface'] }} 2>/dev/null || true

# -------------------------------
# Configuracion de nftables
instalar_nftables:
  pkg.installed:
    - name: nftables

# -------------------------------
nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://firewall/files/nftables.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600

# -------------------------------
# Configuracion de sysctl (habilitar IP forwarding)
# -------------------------------
sysctl_conf:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://firewall/sysctl.conf

aplicar_sysctl_firewall:
  cmd.run:
    - name: |
        sysctl -w net.ipv4.ip_forward=1
        sysctl -p /etc/sysctl.conf
    - require:
      - file: sysctl_conf

# -------------------------------
# ISC DHCP Relay
# -------------------------------
{% if enable_dhcp_relay %}
instalacion_relay:
  pkg.installed:
    - name: isc-dhcp-relay

dhcp_relay_config:
  file.managed:
    - name: /etc/default/isc-dhcp-relay
    - source: salt://firewall/files/isc-dhcp-relay.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalacion_relay

# OPTIMIZADO: service.running es idempotente, restart solo si config cambio
isc_dhcp_relay_service:
  service.running:
    - name: isc-dhcp-relay
    - enable: True
    - watch:
      - file: dhcp_relay_config
    - require:
      - pkg: instalacion_relay
      - cmd: aplicar_interfaces_firewall
{% endif %}

# -------------------------------
# OPTIMIZADO: un solo estado para enable + start/restart nftables
# Solo reinicia si nftables.conf cambio (watch)
# -------------------------------
nftables_service:
  service.running:
    - name: nftables
    - enable: True
    - watch:
      - file: nftables_conf

# networking_service:
#   service.running:
#     - name: networking
#     - enable: True
#     - watch:
#       - file: configurar_interfaces
