# -------------------------------
# Configuración de interfaces
# -------------------------------
configurar_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://firewall/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# -------------------------------
# Configuración de nftables
# -------------------------------
nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://firewall/files/nftables.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600

habilitar_nftables:
  cmd.run:
    - name: systemctl enable nftables.service
    - require:
      - file: configurar_interfaces

# -------------------------------
# Configuración de sysctl
# -------------------------------
sysctl_conf:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://firewall/sysctl.conf

# -------------------------------
# ISC DHCP Relay
# -------------------------------
instalación_relay:
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
      - pkg: instalación_relay

aplicar_relay:
  cmd.run:
    - name: systemctl restart isc-dhcp-relay
    - require:
      - file: dhcp_relay_config

habilitar_relay:
  cmd.run:
    - name: systemctl enable isc-dhcp-relay
    - require:
      - pkg: instalación_relay

# -------------------------------
# Reinicio final para aplicar cambios de red
# -------------------------------
reiniciar_sistema:
  cmd.run:
    - name: poweroff
    - require:
      - file: configurar_interfaces
