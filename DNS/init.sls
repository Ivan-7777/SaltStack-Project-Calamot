instalar_dnsmasq:
  pkg.installed:
   - name: 'dnsmasq'

enviarconf:
  file.managed:
   - name: /etc/dnsmasq.d/dns.conf
   - source: salt://DNS/dns.conf
   - makedirs: true 

dnsmasq-service:
  service.running:
   - name: dnsmasq
   - enable: True
   - reload: True
