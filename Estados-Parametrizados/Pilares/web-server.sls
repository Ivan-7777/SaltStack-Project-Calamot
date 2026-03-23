web-server:
  domain: server.es
  webroot: /var/www/user/server/html
  ssl:
    cert: server.crt
    key: server.key
  network:
    interface: enp0s8
    address: 192.168.0.20
    mask: 24
    gateway: 192.168.0.1
    dns: 192.168.0.20
  ssh:
    port: 22
    permit_root_login: yes
