# 1 Instalar WireGuard
installing_wireguard:
  pkg.installed:
    - pkgs:
      - wireguard-tools

wireguard_conf_dir:
  file.directory:
    - name: /etc/wireguard
    - mode: 700
    - user: root
    - group: root
    - require:
      - pkg: installing_wireguard

wireguard_keys_dir:
  file.directory:
    - name: /etc/wireguard/keys
    - mode: 700
    - user: root
    - group: root
    - require:
      - file: wireguard_conf_dir

# 3 Claves
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
    - require:
      - cmd: crear_clave_wireguard
    - onlyif: test -f /etc/wireguard/keys/server_private.key

# 4 Sysctl (habilitar IP forwarding)
forwarding_wireguard:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://wireguard/files/sysctl.conf
    - mode: 644

aplicar_sysctl_wireguard:
  cmd.run:
    - name: |
        sysctl -w net.ipv4.ip_forward=1
        sysctl -p /etc/sysctl.conf
    - require:
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
      - file: wireguard_conf_dir

# 6 nftables (solo masquerade)
wireguard_nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://wireguard/files/nftables.conf
    - template: jinja
    - mode: 600
    - user: root
    - group: root

# 7 Servicio WireGuard
wireguard_service:
  service.running:
    - name: wg-quick@wg0
    - enable: True
    - watch:
      - file: wg0_conf

# 8 Script generador de clientes
wireguard_sysctl_ipforward:
  file.managed:
    - name: /etc/wireguard/wireguard-cliente.sh
    - source: salt://wireguard/wireguard-cliente.sh
    - mode: 644
    - require:
      - file: wireguard_conf_dir

# 9 nftables service
nftables_wireguard_service:
  service.running:
    - name: nftables
    - enable: True
    - watch:
      - file: wireguard_nftables_conf
