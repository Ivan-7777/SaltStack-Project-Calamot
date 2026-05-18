firewall:
  wan:
    ip: 10.1.105.47
    mask: 24
    gateway: 10.1.105.1
    interface: enp0s3
  lan:
    ip: 192.168.0.1
    mask: 24
    interface: enp0s8
  dmz:
    ip: 192.168.1.1
    mask: 24
    interface: enp0s9
