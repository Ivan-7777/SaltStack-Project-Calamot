# 1 Instalar WireGuard
installing_wireguard:
  pkg.installed:
    - refresh: False
    - pkgs:
      - wireguard-tools

wireguard_keys_dir:
  file.directory:
    - name: /etc/wireguard/keys
    - mode: 700
    - user: root
    - group: root

# 3 Claves (solo crea si no existen - ya correcto con creates)
crear_clave_wireguard:
  cmd.run:
    - name: wg genkey > /etc/wireguard/keys/server_private.key
    - creates: /etc/wireguard/keys/server_private.key
    - require:
      - file: wireguard_keys_dir

wireguard_server_public_key:
  cmd.run:
    - name: wg pubkey < /etc/wireguard/keys/server_private.key > /etc/wireguard/keys/server_public.key
    - creates: /etc/wireguard/keys/server_public.key

# 4 Sysctl (habilitar IP forwarding)
forwarding_wireguard:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://wireguard/files/sysctl.conf
    - mode: 644

# OPTIMIZADO: solo ejecuta sysctl -p si el archivo cambio
aplicar_sysctl_wireguard:
  cmd.run:
    - name: sysctl -p
    - onchanges:
      - file: forwarding_wireguard

# 5 wg0.conf
wg0_conf:
  file.managed:
    - name: /etc/wireguard/wg0.conf
    - source: salt://wireguard/files/wg0.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - require:
      - cmd: crear_clave_wireguard

# 6 nftables (solo masquerade)
wireguard_nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://wireguard/files/nftables.conf
    - template: jinja
    - mode: 600
    - user: root
    - group: root

# 7 Servicio WireGuard: watch sobre wg0.conf (maneja restart automaticamente)
wireguard_service:
  service.running:
    - name: wg-quick@wg0
    - enable: True
    - reload: True
    - watch:
      - file: wg0_conf

# 8 Script generador de clientes
wireguard_sysctl_ipforward:
  file.managed:
    - name: /etc/wireguard/wireguard-cliente.sh
    - source: salt://wireguard/wireguard-cliente.sh
    - mode: 644

# OPTIMIZADO: service.running en lugar de 3 cmd.run encadenados
# Solo hace enable/start/restart si nftables.conf cambio
nftables_wireguard_service:
  service.running:
    - name: nftables
    - enable: True
    - watch:
      - file: wireguard_nftables_conf

# ELIMINADO: reiniciar_wireguard era duplicado de wireguard_service
# wireguard_service ya tiene watch: [file: wg0_conf] que lo maneja
