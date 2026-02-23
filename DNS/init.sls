instalar_dnsmasq:
  pkg.installed:
   - name: 'dnsmasq'

enviarconf:
  file.managed:
   - name: /etc/dnsmasq.d/dns.conf
   - source: salt://installdns/dns.conf
   - makedirs: true 

dnsmasq-service:
  service.running:
   - name: dnsmasq
   - enable: True
   - reload: True
