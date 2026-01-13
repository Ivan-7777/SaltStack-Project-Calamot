#Instalación paquete nftables
instalar_nftables:
  pkg.installed:
   - name: 'nftables'

#Creación nftables
crearruta:
  file.managed:
   - name: /etc/nftables.conf
   - source: salt://firewall/nftables.conf
   - makedirs: true

#Habilitamos el servicio de nftables
habilitar_nftables:   
  cmd.run:
   - name: systemctl enable nftables.service

#Habilitamos forward de paquetes
habilitar_forward:
  file.managed:
   - name: /etc/sysctl.conf
   - source: salt://firewall/sysctl.conf
   - makedirs: true

#Aplicar cambios del archivo sysctl.conf
activar_forward:  
  cmd.run:
   - name: sysctl -p

aplicar-cambios-nftables:
  cmd.run:
   - name: systemctl restart nftables.service

#Asignación de IPs Firewall
cambio_ip:
  file.managed:
   - name: /etc/network/interfaces   
   - source: salt://firewall/interfaces
   - makedirs: true

aignación_ips:
  cmd.run:
   - name: systemctl restart networking.service

