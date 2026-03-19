# 1️⃣ Instalar WireGuard
wireguard_packages:
  pkg.installed:
    - pkgs:
      - wireguard-tools

# 2️⃣ Directorios
wireguard_base_dir:
  file.directory:
    - name: /etc/wireguard
    - mode: 700
    - user: root
    - group: root
    - require:
      - pkg: wireguard_packages

wireguard_keys_dir:
  file.directory:
    - name: /etc/wireguard/keys
    - mode: 700
    - user: root
    - group: root
    - require:
      - file: wireguard_base_dir

# 3️⃣ Claves
wireguard_server_private_key:
  cmd.run:
    - name: wg genkey > /etc/wireguard/keys/server_private.key
    - creates: /etc/wireguard/keys/server_private.key
    - require:
      - pkg: wireguard_packages
      - file: wireguard_keys_dir

wireguard_server_public_key:
  cmd.run:
    - name: wg pubkey < /etc/wireguard/keys/server_private.key > /etc/wireguard/keys/server_public.key
    - creates: /etc/wireguard/keys/server_public.key
    - require:
      - cmd: wireguard_server_private_key

# 4️⃣ Sysctl
wireguard_sysctl_ipforward:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://wireguard/files/sysctl.conf
    - mode: 644

# 5️⃣ wg0.conf
wireguard_wg0_conf:
  file.managed:
    - name: /etc/wireguard/wg0.conf
    - source: salt://wireguard/files/wg0.conf
    - template: jinja
    - mode: 600
    - user: root
    - group: root
    - require:
      - cmd: wireguard_server_private_key

# 6️⃣ nftables (solo masquerade)
wireguard_nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://wireguard/files/nftables.conf
    - template: jinja
    - mode: 600
    - user: root
    - group: root

wireguard_nftables_apply:
  cmd.run:
    - name: nft -f /etc/nftables.conf
    - require:
      - file: wireguard_nftables_conf

# 7️⃣ Servicio WireGuard
wireguard_service:
  service.running:
    - name: wg-quick@wg0
    - enable: True
    - require:
      - file: wireguard_wg0_conf
      - cmd: wireguard_sysctl_apply
      - cmd: wireguard_nftables_apply
# 8️⃣ Configuración de la IP LAN del minion
configure_lan_ip:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://wireguard/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

reinicio:
  cmd.run:
    - name: reboot
