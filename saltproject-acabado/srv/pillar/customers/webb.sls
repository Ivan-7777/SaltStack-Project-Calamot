empresa: webb
servicios_activos:
  - webserver
web-server:
  domain: aitor.es
  network:
    interface: enp0s3
    address: 10.0.2.16
    mask: 24
    gateway: 10.0.2.1
    dns: 10.0.2.1
  webroot: /var/www/html
  ssh:
    port: 22
    permit_root_login: yes
