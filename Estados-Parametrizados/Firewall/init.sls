# -------------------------------
# Configuración de interfaces
# -------------------------------
configurar_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://Firewall/files/interfaces.jinja
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
    - source: salt://Firewall/files/nftables.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600

aplicar_nftables:
  cmd.run:
    - name: systemctl restart nftables.service
    - require:
      - file: nftables_conf

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
    - source: salt://Firewall/sysctl.conf

# -------------------------------
# ISC DHCP Relay
# -------------------------------
instalación_relay:
  pkg.installed:
    - name: isc-dhcp-relay

dhcp_relay_config:
  file.managed:
    - name: /etc/default/isc-dhcp-relay
    - source: salt://Firewall/files/isc-dhcp-relay.jinja
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
reiniciar_networking:
  cmd.run:
    - name: reboot
    - require:
      - file: configurar_interfaces
