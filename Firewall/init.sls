# Configurar interfaces
configurar_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://Firewall/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# Configurar nftables
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

# Configurar nftables
nftables_conf:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://Firewall/sysctl.conf
    - user: root
    - group: root
    - mode: 600

reiniciar_networking:
  cmd.run:
    - name: reboot
    - require:
      - file: configurar_interfaces
