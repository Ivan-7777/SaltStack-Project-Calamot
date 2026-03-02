# Configurar interfaces
configurar_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://firewall/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# Configurar nftables
nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://firewall/files/nftables.conf.jinja
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

reiniciar_networking:
  cmd.run:
    - name: reboot
    - require:
      - file: configurar_interfaces
