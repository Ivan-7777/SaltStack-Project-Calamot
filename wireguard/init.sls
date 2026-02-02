# 1️⃣ WireGuard (paquete que sabes que funciona)
wireguard_packages:
  pkg.installed:
    - pkgs:
      - wireguard-tools

# 2️⃣ Directorios base
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

# 3️⃣ Claves del servidor (NO se ejecuta hasta que el paquete existe)
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

# 4️⃣ Sysctl: forwarding IPv4 (persistente y correcto)
wireguard_sysctl_ipforward:
  file.managed:
    - name: /etc/sysctl.d/99-wireguard.conf
    - contents: |
        net.ipv4.ip_forward=1
    - mode: 644

wireguard_sysctl_apply:
  cmd.run:
    - name: sysctl --system
    - onchanges:
      - file: wireguard_sysctl_ipforward

# 5️⃣ wg0.conf (SIN JINJA DINÁMICO PELIGROSO)
wireguard_wg0_conf:
  file.managed:
    - name: /etc/wireguard/wg0.conf
    - source: salt://wireguard/files/wg0.conf
    - mode: 600
    - user: root
    - group: root
    - require:
      - cmd: wireguard_server_private_key

# 6️⃣ nftables (solo masquerade, todo ACCEPT)
wireguard_nftables_conf:
  file.managed:
    - name: /etc/nftables.conf
    - contents: |
        table inet filter {
          chain input {
            type filter hook input priority 0;
            policy accept;
          }

          chain forward {
            type filter hook forward priority 0;
            policy accept;
          }

          chain output {
            type filter hook output priority 0;
            policy accept;
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100;
            oifname "enp0s3" masquerade
          }
        }
    - mode: 600
    - user: root
    - group: root

wireguard_nftables_apply:
  cmd.run:
    - name: nft -f /etc/nftables.conf
    - require:
      - file: wireguard_nftables_conf

# 7️⃣ Servicio WireGuard (solo arranca cuando TODO está listo)
wireguard_wg0_privatekey_replace:
  file.replace:
    - name: /etc/wireguard/wg0.conf
    - pattern: '\{\{\s*server_private_key\s*\}\}'
    - repl: "{{ salt['cmd.run']('cat /etc/wireguard/keys/server_private.key') }}"
    - require:
      - cmd: wireguard_server_private_key

wireguard_service:
  service.running:
    - name: wg-quick@wg0
    - enable: True
    - require:
      - file: wireguard_wg0_conf
      - cmd: wireguard_sysctl_apply
      - cmd: wireguard_nftables_apply
