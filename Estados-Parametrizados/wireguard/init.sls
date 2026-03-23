# 1️⃣ Instalar WireGuard
installing_wireguard:
  pkg.installed:
    - pkgs:
      - wireguard-tools

wireguard_keys_dir:
  file.directory:
    - name: /etc/wireguard/keys
    - mode: 700
    - user: root
    - group: root

# 3️⃣ Claves
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

# 4️⃣ Sysctl
forwarding_wireguard:
  file.managed:
    - name: /etc/sysctl.conf
    - source: salt://wireguard/files/sysctl.conf
    - mode: 644

# 5️⃣ wg0.conf
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
      - file: wg0_conf
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
    - name: systemctl enable nftables.service

reinicio:
  cmd.run:
    - name: reboot
