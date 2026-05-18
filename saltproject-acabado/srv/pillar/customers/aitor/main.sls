# ============================================================
# Pilar consolidado para cliente: aitor
# Incluye: wireguard, firewall, dhcp, web-server, dns, pkica
# ============================================================

wireguard:
  port: 51820
  address: 10.66.66.1/24
  static_lan_ip: 192.168.0.10/24
  wan_interface: enp0s3

firewall:
  wan:
    ip: 10.1.105.47
    mask: 24
    gateway: 10.1.105.1
    interface: enp0s3
  lan:
    ip: 192.168.0.1
    mask: 24
    interface: enp0s3
  dmz:
    ip: 192.168.1.1
    mask: 24
    interface: enp0s9

dhcp:
  server_ip: 192.168.0.10/24
  server_interface: enp0s3
  log: true
  interfaces:
    lan:
      name: enp0s8
      range_start: 192.168.0.50
      range_end: 192.168.0.200
      netmask: 255.255.255.0
      lease_time: 24h
    dmz:
      name: enp0s8
      range_start: 10.2.0.50
      range_end: 10.2.0.200
      netmask: 255.255.255.0
      lease_time: 24h
  options:
    gateway:
      0: 192.168.0.5
      1: 10.2.0.5
    dns:
      0: 192.168.0.5
      1: 10.2.0.5

web-server:
  domain: server.es
  webroot: /var/www/user/server/html
  ssl:
    cert: server.crt
    key: server.key
  network:
    interface: enp0s3
    address: 192.168.0.10
    mask: 24
    gateway: 192.168.0.5
    dns: 192.168.0.5
  ssh:
    port: 22
    permit_root_login: yes

dns:
  recursion: yes
  allow_query: "192.168.0.0/24; 10.2.0.0/24; 10.66.66.0/24"
  listen_on: []
  forwarders:
    - 8.8.8.8
    - 8.8.4.4

pkica:
  base_dir: /etc/pki/ca
  ca:
    country: ES
    state: Madrid
    locality: Madrid
    organization: MiOrg
    organizational_unit: IT
    common_name: mi-ca
    days_valid: 3650
    key_size: 4096
    digest: sha256
  files:
    index: /etc/pki/ca/index.txt
    serial: /etc/pki/ca/serial
    serial_start: 1000
    openssl_config: /etc/pki/ca/openssl.cnf
    private_key: /etc/pki/ca/private/ca.key.pem
    root_cert: /etc/pki/ca/certs/ca.cert.pem

proxy:
  ip: 192.168.1.10
  puerto_customizado: 80

mysql:
  root_password: "M@r1aDB_R00t_2026!"
  host: "192.168.0.10"
  port: 3306
  user: "saltlogger"
  password: "S@ltL0gg3r_2026!"
  database: "salt_logs"

wordpress:
  db_name: wordpress
  db_user: wordpress
  db_pass: "WordPress_2026!"
  admin_user: admin
  admin_pass: admin
  admin_email: admin@server.es
  title: "Bienvenido a mi sitio"
