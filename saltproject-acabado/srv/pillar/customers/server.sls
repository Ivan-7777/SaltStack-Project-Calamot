empresa: server
servicios_activos:
  - webserver
web-server:
  domain: server.es
  webroot: /var/www/html/
  ssl:
    cert: server.crt
    key: server.key
  network:
    interface: enp0s3
    address: 192.168.0.25
    mask: 24
    gateway: 192.168.0.1
    dns: 192.168.0.1
  ssh:
    port: 22
    permit_root_login: yes
