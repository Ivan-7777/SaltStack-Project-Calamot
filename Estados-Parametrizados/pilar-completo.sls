wireguard:
  port: 51830
  address: 10.66.66.1/24
  static_lan_ip: 192.168.0.10/24
  wan_interface: enp0s3
firewall:
  wan:
    ip: 10.1.105.200
    mask: 24
    gateway: 10.1.105.1
    interface: enp0s3
  lan:
    ip: 192.168.0.1
    mask: 24
    interface: enp0s8
  dmz:
    ip: 10.2.0.1
    mask: 16
    interface: enp0s9
dhcp:
  server_ip: 192.168.0.50
  log: true
  interfaces:
    lan:
      name: enp0s3
      range_start: 192.168.0.50
      range_end: 192.168.0.200
      netmask: 255.255.255.0
      lease_time: 24h
    dmz:
      name: enp0s3
      range_start: 10.1.0.50
      range_end: 10.1.255.200
      netmask: 255.255.0.0
      lease_time: 24h
  options:
    gateway:
      0: 192.168.0.1
      1: 10.2.0.1
    dns:
      0: 192.168.0.20
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
    dns: 192.168.0.1

  ssh:
    port: 22
    permit_root_login: yes
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
