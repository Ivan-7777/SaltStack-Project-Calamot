# Instala Bind9
instalar_bind9:
  pkg.installed:
    - refresh: False
    - name: bind9

# Directorio de zonas
crear_directorio_zonas:
  file.directory:
    - name: /etc/bind/zones
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - require:
      - pkg: instalar_bind9

# Copiar named.conf.options desde Jinja
configurar_named_options:
  file.managed:
    - name: /etc/bind/named.conf.options
    - source: salt://dns/files/named.conf.options.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalar_bind9

# Copiar named.conf.local desde Jinja
configurar_named_local:
  file.managed:
    - name: /etc/bind/named.conf.local
    - source: salt://dns/files/named.conf.local.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: instalar_bind9

# Copiar archivos de zona desde files/zones/
configurar_zonas:
  file.recurse:
    - name: /etc/bind/zones
    - source: salt://dns/files/zones
    - template: jinja
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - require:
      - pkg: instalar_bind9

# Servicio Bind9
bind9_service:
  service.running:
    - name: bind9
    - enable: True
    - watch:
      - file: configurar_named_options
      - file: configurar_named_local
      - file: configurar_zonas
