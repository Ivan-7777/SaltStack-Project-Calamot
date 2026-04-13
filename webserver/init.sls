# Estado Salt Stack para servidor web - Configuracion basica de red, SSH, hostname y MOTD

# ============================================
# HOSTNAME: Cambiar hostname a serv-web
# ============================================
hostname_file:
  file.managed:
    - name: /etc/hostname
    - contents: |
        serv-web

hostname_hosts:
  file.replace:
    - name: /etc/hosts
    - pattern: '127\.0\.0\.1\s+.*'
    - repl: '127.0.0.1\tlocalhost serv-web'

apply_hostname:
  cmd.run:
    - name: hostnamectl set-hostname serv-web && hostname serv-web
    - require:
      - file: hostname_file

# ============================================
# INTERFAZ DE RED: IP estatica en enp0s3
# ============================================
static_network_config:
  file.managed:
    - name: /etc/network/interfaces
    - contents: |
        source /etc/network/interfaces.d/*

        auto lo
        iface lo inet loopback

        # Interfaz principal - IP estatica
        allow-hotplug enp0s3
        auto enp0s3
        iface enp0s3 inet static
            address 10.1.105.48/24
            gateway 10.1.105.1
            dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1

# ============================================
# DNS ESTATICO: Configurar resolv.conf permanente
# ============================================
static_dns_config:
  file.managed:
    - name: /etc/resolv.conf
    - contents: |
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        nameserver 1.1.1.1
        search localdomain

dns_resolvconf_override:
  file.managed:
    - name: /etc/resolvconf/resolv.conf.d/head
    - contents: |
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        nameserver 1.1.1.1
    - makedirs: True
    - require:
      - file: static_dns_config

# ============================================
# GENERACION DE CLAVES SSH: Publicas y privadas
# ============================================
ssh_host_keys:
  cmd.run:
    - name: ssh-keygen -A

ssh_root_keys:
  cmd.run:
    - name: |
        mkdir -p /root/.ssh && chmod 700 /root/.ssh
        if [ ! -f /root/.ssh/id_ed25519 ]; then
            ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" -q -C "root@serv-web"
        fi
        if [ ! -f /root/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N "" -q -C "root@serv-web"
        fi

# ============================================
# MOTD: Mensaje de login con info del servidor web
# ============================================
login_motd:
  file.managed:
    - name: /etc/motd
    - contents: |
        ***************************************************************
        Servidor Web - serv-web
        IP: 10.1.105.48
        Hostname: serv-web
        ***************************************************************

# ============================================
# SSH BANNER: Configurar banner de SSH
# ============================================
ssh_banner_file:
  file.managed:
    - name: /etc/ssh/banner
    - contents: |
        ***************************************************************
        Servidor Web - serv-web | IP: 10.1.105.48
        ***************************************************************

ssh_banner_config:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '#?Banner.*'
    - repl: 'Banner /etc/ssh/banner'
