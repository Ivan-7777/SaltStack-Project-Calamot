wireguard:
  port: 51820
  address: 10.66.66.1/24
  static_lan_ip: 192.168.0.10/24
  wan_interface: enp0s3
  peers:
    cliente_externo:
      public_key: "mAi7WDc1BQx8hHxe5RQLaov6Gi1G9pULrOZDeoFY0wk="
      allowed_ips: "10.66.66.5/32"
