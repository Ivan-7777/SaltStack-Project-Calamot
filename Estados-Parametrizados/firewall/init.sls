# -------------------------------
# ATENCION: Este bloque cambia /etc/network/interfaces y rompe SSH
# Solo se debe aplicar si se tiene acceso por consola o IP alternativa
configurar_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://firewall/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# -------------------------------
# Configuracion de nftables
instalar_nftables:
  pkg.installed:
    - name: nftables
    - refresh: False

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

# OPTIMIZADO: solo ejecuta sysctl -p si el archivo sysctl.conf cambio
aplicar_sysctl_firewall:
  cmd.run:
    - name: sysctl -p
    - onchanges:
      - file: sysctl_conf

# -------------------------------
# ISC DHCP Relay
# -------------------------------
instalacion_relay:
  pkg.installed:
    - name: isc-dhcp-relay
    - refresh: False

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
    - refresh: False
    - enable: True
    - watch:
      - file: dhcp_relay_config
    - require:
      - pkg: instalacion_relay

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

networking_service:
  service.running:
    - name: networking
    - enable: True
    - watch:
      - file: configurar_interfaces
