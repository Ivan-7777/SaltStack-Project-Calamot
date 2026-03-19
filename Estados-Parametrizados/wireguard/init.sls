# 1️⃣ Instalar WireGuard
patata:
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

# 4️⃣ Sysctl
popo:
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

# 6️⃣ nftables (solo masquerade)
wireguard_nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - source: salt://wireguard/files/nftables.conf
    - template: jinja
    - mode: 600
    - user: root
    - group: root

# 7️⃣ Servicio WireGuard
wireguard_service:
  service.running:
    - name: wg-quick@wg0
    - enable: True
    - require:
      - file: wireguard_wg0_conf
# 8️⃣ Configuración de la IP LAN del minion
configure_lan_ip:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://wireguard/files/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

wireguard_sysctl_ipforward:
  file.managed:
    - name: /etc/wireguard/wireguard-cliente.sh
    - source: salt://wireguard/wireguard-cliente.sh
    - mode: 644

aplicar_nftables:
  cmd.run:
    - name: systemctl enable nftables.conf

reinicio:
  cmd.run:
    - name: reboot
