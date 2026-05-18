instalar_nginx:
  pkg.installed:
    - name: nginx

configurar_proxy:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://proxy/files/proxy.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalar_nginx

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - file: configurar_proxy
