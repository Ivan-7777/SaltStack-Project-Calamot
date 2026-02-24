Estos archivos funcionan en base a un pillar que se debe encontrar en /srv/pillar/customers/

La estructura del pilar debe ser la siguiente:
wireguard:
  port: 45450
  static_lan_ip: 192.168.0.10
  wan_interface: enp0s3
