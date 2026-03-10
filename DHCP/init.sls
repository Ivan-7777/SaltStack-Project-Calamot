instalar_dnsmasq:
  pkg.installed:
   - name: 'dnsmasq'

/etc/dnsmasq.d/dhcp.conf:
  file.managed:
    - source: salt://DHCP/dhcp.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true

/etc/network/interfaces:
  file.managed:
    - source: salt://DHCP/interfaces
    - user: root
    - group: root
    - mode: 644

dhcpmasq-service:
  service.running:
   - name: dnsmasq
   - enable: True
   - reload: True

aplicar_cambios:
  cmd.run:
   - name: reboot
