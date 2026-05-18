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

# OPTIMIZADO: service.enabled es idempotente
habilitar_dnsmasq:
  service.enabled:
    - name: dnsmasq
    - require:
      - pkg: instalar_dnsmasq

# OPTIMIZADO: service.running con watch - restart solo si dnsmasq.conf cambio
reiniciar_dnsmasq:
  service.running:
    - name: dnsmasq
    - enable: True
    - watch:
      - file: enviarconf
