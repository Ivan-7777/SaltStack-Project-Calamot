instalación_openvpn:
  cmd.run:
   - name: apt -y install openvpn

transferencia_archivo_server:
  file.managed:
   - name: /etc/openvpn/server.conf
   - source: salt://vpn/server.conf
   - makedirs: true

transferencia_archivo_sysctl:
  file.managed:   
   - name: /etc/sysctl.conf
   - source: salt://firewall/sysctl.conf
   - makedirs: true

aplicar_sysctl_vpn:
  cmd.run:
   - name: sysctl -p

identidad_vpn:
  file.recurse:
   - name: /etc/openvpn/
   - source: salt://vpn/openvpn
   - makedirs: true
   - dir_mode: 755

permisos_easyrsa:
  cmd.run:
   - name: chmod 755 /etc/openvpn/easy-rsa/easyrsa

firewall_vpn:
  file.managed:
   - name: /etc/nftables.conf
   - source: salt://vpn/nftables.conf
   - makedirs: true

habilitar_fw_vpn:
  cmd.run:
   - name: systemctl enable nftables.service && systemctl restart nftables.service

cambio_ip:
  file.managed:
   - name: /etc/network/interfaces
   - source: salt://vpn/interfaces

asignación_IP:
  cmd.run:
   - name: systemctl restart networking.service

reinicio_vpn:
  cmd.run:
   - name: systemctl restart openvpn@server

