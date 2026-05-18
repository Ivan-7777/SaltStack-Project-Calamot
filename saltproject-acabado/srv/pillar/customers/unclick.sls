wireguard:
  port: 51820
  address: 192.168.0.1
  static_lan_ip: 192.168.0.10
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
