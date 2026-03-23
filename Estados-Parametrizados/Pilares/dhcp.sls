dhcp:
  server_ip: 192.168.0.50/24
  server_interface: enp0s3
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
      0: 192.168.0.20  # IP del servidor DNS principal
      1: 10.2.0.20     # IP DNS secundario, opcional para DMZ
