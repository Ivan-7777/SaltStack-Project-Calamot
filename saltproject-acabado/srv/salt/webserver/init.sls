include:
  - wordpress

# Estado Salt Stack para servidor web - Configuracion basica de red, SSH, hostname y MOTD

{% set domain = salt['pillar.get']('web-server:domain', 'server.es') %}
{% set address = salt['pillar.get']('web-server:network:address', '192.168.0.10') %}
{% set mask = salt['pillar.get']('web-server:network:mask', '24') %}
{% set gateway = salt['pillar.get']('web-server:network:gateway', '192.168.0.1') %}
{% set interface = salt['pillar.get']('web-server:network:interface', 'enp0s3') %}

# ============================================
# HOSTNAME: Cambiar hostname basado en el dominio
# ============================================
hostname_file:
  file.managed:
    - name: /etc/hostname
    - contents: |
        {{ domain.split('.')[0] }}

hostname_hosts:
  file.replace:
    - name: /etc/hosts
    - pattern: '127\.0\.0\.1\s+.*'
    - repl: '127.0.0.1\tlocalhost {{ domain.split('.')[0] }}'

apply_hostname:
  cmd.run:
    - name: hostnamectl set-hostname {{ domain.split('.')[0] }} && hostname {{ domain.split('.')[0] }}
    - require:
      - file: hostname_file

# ============================================
# DNS ESTATICO: Configurar resolv.conf
# ============================================
static_dns_config:
  file.managed:
    - name: /etc/resolv.conf
    - contents: |
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        search {{ domain }}

# ============================================
# MOTD: Mensaje de login con info del servidor web
# ============================================
login_motd:
  file.managed:
    - name: /etc/motd
    - contents: |
        ***************************************************************
        Servidor Web - {{ domain }}
        IP: {{ address }}
        Hostname: {{ domain.split('.')[0] }}
        ***************************************************************

# ============================================
# SSH BANNER: Configurar banner de SSH
# ============================================
ssh_banner_file:
  file.managed:
    - name: /etc/ssh/banner
    - contents: |
        ***************************************************************
        Servidor Web - {{ domain }} | IP: {{ address }}
        ***************************************************************

ssh_banner_config:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '#?Banner.*'
    - repl: 'Banner /etc/ssh/banner'
