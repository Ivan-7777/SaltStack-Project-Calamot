# Instalar dnsmasq
instalar_dnsmasq:
  pkg.installed:
    - name: dnsmasq

# Generar dhcp.conf desde plantilla Jinja usando pillar
enviarconf:
  file.managed:
    - name: /etc/dnsmasq.conf
    - source: salt://dhcp/dhcp.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalar_dnsmasq

interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://dhcp/interfaces.jinja
    - template: jinja

habilitar_dnsmasq:
  cmd.run:
    - name: systemctl enable dnsmasq.service
    - require:
      - pkg: instalar_dnsmasq

enviar_interfaces:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://dhcp/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

aplicar_dhcp:
  cmd.run:
    - name: reboot  
