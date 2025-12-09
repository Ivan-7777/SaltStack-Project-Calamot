instalación_relay:
  cmd.run:
   - name: apt-get -y install isc-dhcp-relay

enviar_ficheros_relay:
  file.managed:
   - name: /etc/default/isc-dhcp-relay
   - source: salt://relay/isc-dhcp-relay
   - makedirs: true 

aplicar_relay:
  cmd.run:
   - name: systemctl restart isc-dhcp-relay

habilitar_relay:
  cmd.run:
   - name: systemctl enable isc-dhcp-relay
