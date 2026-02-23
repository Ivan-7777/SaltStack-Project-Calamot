instalar_dnsmasq:
  pkg.installed:
   - name: 'dnsmasq'

enviarconf:
  file.managed:
   - name: /etc/dnsmasq.d/dhcp.conf
   - sources: salt://installdhcp/dhcp.conf
   - makedirs: true

dhcpmasq-service:
  service.running:
   - name: dnsmasq
   - enable: True
   - reload: True
