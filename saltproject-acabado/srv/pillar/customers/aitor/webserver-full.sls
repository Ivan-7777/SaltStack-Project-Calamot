web-server:
  domain: server.es
  webroot: /var/www/user/server/html
  ssl:
    cert: server.crt
    key: server.key
  network:
    interface: enp0s3
    address: 10.1.105.65
    mask: 24
    gateway: 10.1.105.1
    dns: 10.1.105.1
  ssh:
    port: 22
    permit_root_login: yes
