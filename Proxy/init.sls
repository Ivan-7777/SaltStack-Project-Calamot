# Update system packages
proxy_packages:
  pkg.installed:
    - pkgs:
      - nginx

# Configure network interfaces
/etc/network/interfaces:
  file.managed:
    - source: salt://proxy-inverso/interfaces
    - user: root
    - group: root
    - mode: 644

# Configure Nginx as Reverse Proxy
/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://proxy-inverso/nginx.conf
    - user: root
    - group: root
    - mode: 644

# Create Nginx sites-available directory
/etc/nginx/sites-available:
  file.directory:
    - user: root
    - group: root
    - mode: 755

# Create reverse proxy configuration
/etc/nginx/sites-available/default:
  file.managed:
    - source: salt://proxy-inverso/default
    - user: root
    - group: root
    - mode: 644

# Enable site (create symlink if not exists)
proxy_enable_site:
  cmd.run:
    - name: ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default || true

# Enable and start Nginx
nginx:
  service.running:
    - enable: True

# Reiniciar la maquina para reiniciar sevicios
reiniciar-maquinaweb:
  cmd.run:
    - name: sleep 20 && reboot
