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
