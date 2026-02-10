# Update system packages
webserver_packages:
  pkg.installed:
    - pkgs:
      - nginx

# Configure network interfaces
/etc/network/interfaces:
  file.managed:
    - source: salt://webserver-proxy/interfaces
    - user: root
    - group: root
    - mode: 644

# Configure Nginx
/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://webserver-proxy/nginx.conf
    - user: root
    - group: root
    - mode: 644

# Create web content directory
/var/www/html:
  file.directory:
    - user: www-data
    - group: www-data
    - mode: 755

# Deploy index.html
/var/www/html/index.html:
  file.managed:
    - source: salt://webserver-proxy/index.html
    - user: www-data
    - group: www-data
    - mode: 644

# Enable and start Nginx
nginx:
  service.running:
    - enable: True
