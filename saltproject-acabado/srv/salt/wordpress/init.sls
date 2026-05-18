include:
  - common
  - webserver.content

wordpress_download_dns:
  file.managed:
    - name: /etc/resolv.conf
    - contents: |
        nameserver 8.8.8.8
        nameserver 8.8.4.4
    - require:
      - cmd: common_network_runtime_apply

wordpress_mariadb_server_installed:
  pkg.installed:
    - name: mariadb-server

wordpress_mariadb_client_installed:
  pkg.installed:
    - name: mariadb-client

wordpress_restore_mariadb_config:
  cmd.run:
    - name: apt-get install --reinstall -y -o Dpkg::Options::="--force-confmiss" mariadb-server
    - unless: test -f /etc/mysql/mariadb.conf.d/50-server.cnf
    - require:
      - pkg: wordpress_mariadb_server_installed

wordpress_mariadb_service_running:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: wordpress_mariadb_server_installed
      - cmd: wordpress_restore_mariadb_config

wordpress_set_root_password:
  cmd.run:
    - name: |
        mysql -u root -e "
          ALTER USER \"root\"@\"localhost\" IDENTIFIED VIA mysql_native_password USING PASSWORD(\"{{ salt["pillar.get"]("mysql:root_password", "M@r1aDB_R00t_2026!") }}\");
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "M@r1aDB_R00t_2026!") }}" -e "SELECT 1" 2>/dev/null
    - require:
      - service: wordpress_mariadb_service_running

wordpress_local_database:
  cmd.run:
    - name: |
        mysql -u root -p"{{ salt["pillar.get"]("mysql:root_password", "M@r1aDB_R00t_2026!") }}" -e "
          CREATE DATABASE IF NOT EXISTS {{ salt["pillar.get"]("wordpress:db_name", "wordpress") }};
          CREATE USER IF NOT EXISTS \"{{ salt["pillar.get"]("wordpress:db_user", "wpuser") }}\"@\"localhost\" IDENTIFIED BY \"{{ salt["pillar.get"]("wordpress:db_pass", "Wp@2026!") }}\";
          ALTER USER \"{{ salt["pillar.get"]("wordpress:db_user", "wpuser") }}\"@\"localhost\" IDENTIFIED BY \"{{ salt["pillar.get"]("wordpress:db_pass", "Wp@2026!") }}\";
          GRANT ALL PRIVILEGES ON {{ salt["pillar.get"]("wordpress:db_name", "wordpress") }}.* TO \"{{ salt["pillar.get"]("wordpress:db_user", "wpuser") }}\"@\"localhost\";
          FLUSH PRIVILEGES;
        "
    - unless: mysql -u "{{ salt["pillar.get"]("wordpress:db_user", "wpuser") }}" -p"{{ salt["pillar.get"]("wordpress:db_pass", "Wp@2026!") }}" -h 127.0.0.1 "{{ salt["pillar.get"]("wordpress:db_name", "wordpress") }}" -e "SELECT 1" 2>/dev/null
    - require:
      - cmd: wordpress_set_root_password

# Instalar WP-CLI
descargar_wpcli:
  cmd.run:
    - name: curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /tmp/wp-cli.phar
    - creates: /usr/local/bin/wp
    - require:
      - file: wordpress_download_dns

instalar_wpcli:
  cmd.run:
    - name: chmod +x /tmp/wp-cli.phar && mv /tmp/wp-cli.phar /usr/local/bin/wp
    - onchanges:
      - cmd: descargar_wpcli
    - require:
      - cmd: descargar_wpcli

# Descargar WordPress
descargar_wordpress:
  cmd.run:
    - name: wp core download --path={{ pillar['web-server']['webroot'] }} --allow-root --locale=es_ES
    - unless: test -f {{ pillar['web-server']['webroot'] }}/wp-load.php
    - require:
      - cmd: instalar_wpcli
      - file: crear_webroot
      - file: wordpress_download_dns

wordpress_front_controller:
  file.managed:
    - name: {{ pillar['web-server']['webroot'] }}/index.php
    - user: www-data
    - group: www-data
    - mode: 644
    - contents: |
        <?php
        /**
         * Front to the WordPress application.
         */
        define( 'WP_USE_THEMES', true );
        require __DIR__ . '/wp-blog-header.php';
    - require:
      - cmd: descargar_wordpress

# Generar wp-config.php
configurar_wordpress:
  cmd.run:
    - name: |
        wp config create           --path={{ pillar['web-server']['webroot'] }}           --dbname={{ pillar['wordpress']['db_name'] }}           --dbuser={{ pillar['wordpress']['db_user'] }}           --dbpass='{{ pillar['wordpress']['db_pass'] }}'           --dbhost={{ salt['pillar.get']('wordpress:db_host', '127.0.0.1') }}           --allow-root
    - unless: test -f {{ pillar['web-server']['webroot'] }}/wp-config.php
    - require:
      - file: wordpress_front_controller
      - cmd: wordpress_local_database

# Realizar la instalacion automatica
instalar_wordpress_core:
  cmd.run:
    - name: |
        wp core install           --path={{ pillar['web-server']['webroot'] }}           --url=http://{{ pillar['web-server']['domain'] }}           --title='{{ pillar['wordpress']['title'] }}'           --admin_user={{ pillar['wordpress']['admin_user'] }}           --admin_password={{ pillar['wordpress']['admin_pass'] }}           --admin_email={{ pillar['wordpress']['admin_email'] }}           --allow-root
    - unless: wp core is-installed --path={{ pillar['web-server']['webroot'] }} --allow-root
    - require:
      - cmd: configurar_wordpress

# Ajustar permisos despues de todo
permisos_finales_wordpress:
  file.directory:
    - name: {{ pillar['web-server']['webroot'] }}
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group
    - require:
      - cmd: instalar_wordpress_core

# Crear pagina de bienvenida personalizada
crear_pagina_bienvenida:
  cmd.run:
    - name: |
        CONTENT='<div style="max-width:960px;margin:0 auto;padding:64px 24px;font-family:Arial,sans-serif;line-height:1.6;color:#1f2933;">
          <section style="padding:48px 0;border-bottom:1px solid #e5e7eb;">
            <p style="text-transform:uppercase;letter-spacing:.12em;font-size:13px;color:#0f766e;font-weight:700;margin:0 0 16px;">Unclick services</p>
            <h1 style="font-size:42px;line-height:1.1;margin:0 0 20px;color:#111827;">Bienvenido a tu nueva pagina web</h1>
            <p style="font-size:20px;margin:0;color:#4b5563;">Encantados de haberte ofrecido nuestros servicios. Esta pagina ha sido desplegada automaticamente y esta lista para empezar a trabajar.</p>
          </section>
          <section style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;padding:36px 0;">
            <div style="border:1px solid #e5e7eb;padding:24px;border-radius:8px;background:#ffffff;">
              <h2 style="font-size:20px;margin:0 0 10px;color:#111827;">Rapido</h2>
              <p style="margin:0;color:#4b5563;">Infraestructura preparada para publicar contenido desde el primer despliegue.</p>
            </div>
            <div style="border:1px solid #e5e7eb;padding:24px;border-radius:8px;background:#ffffff;">
              <h2 style="font-size:20px;margin:0 0 10px;color:#111827;">Seguro</h2>
              <p style="margin:0;color:#4b5563;">Acceso publico limitado a la web, con administracion protegida desde la red autorizada.</p>
            </div>
            <div style="border:1px solid #e5e7eb;padding:24px;border-radius:8px;background:#ffffff;">
              <h2 style="font-size:20px;margin:0 0 10px;color:#111827;">Gestionado</h2>
              <p style="margin:0;color:#4b5563;">Servicios instalados y mantenidos mediante SaltStack para repetir el despliegue de forma fiable.</p>
            </div>
          </section>
          <section style="padding:28px 0;">
            <p style="font-size:18px;margin:0 0 16px;color:#374151;">Gracias por confiar en Unclick. Puedes visitar nuestra pagina oficial en <a href="https://unclick.cat" style="color:#0f766e;font-weight:700;">unclick.cat</a>.</p>
          </section>
        </div>'
        PAGE_ID=$(wp post list --path={{ pillar['web-server']['webroot'] }} --post_type=page --name=pagina-de-bienvenida --field=ID --allow-root | head -1)
        if [ -z "$PAGE_ID" ]; then
          wp post create --path={{ pillar['web-server']['webroot'] }} \
            --post_type=page \
            --post_title='Pagina de Bienvenida' \
            --post_name='pagina-de-bienvenida' \
            --post_content="$CONTENT" \
            --post_status=publish \
            --allow-root
        else
          wp post update "$PAGE_ID" --path={{ pillar['web-server']['webroot'] }} \
            --post_title='Pagina de Bienvenida' \
            --post_content="$CONTENT" \
            --post_status=publish \
            --allow-root
        fi
    - require:
      - cmd: instalar_wordpress_core

# Establecer como pagina de inicio
establecer_inicio:
  cmd.run:
    - name: |
        CONTENT='<div style="max-width:960px;margin:0 auto;padding:64px 24px;font-family:Arial,sans-serif;line-height:1.6;color:#1f2933;">
          <section style="padding:48px 0;border-bottom:1px solid #e5e7eb;">
            <p style="text-transform:uppercase;letter-spacing:.12em;font-size:13px;color:#0f766e;font-weight:700;margin:0 0 16px;">Unclick services</p>
            <h1 style="font-size:42px;line-height:1.1;margin:0 0 20px;color:#111827;">Bienvenido a tu nueva pagina web</h1>
            <p style="font-size:20px;margin:0;color:#4b5563;">Encantados de haberte ofrecido nuestros servicios. Esta pagina ha sido desplegada automaticamente y esta lista para empezar a trabajar.</p>
          </section>
          <section style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;padding:36px 0;">
            <div style="border:1px solid #e5e7eb;padding:24px;border-radius:8px;background:#ffffff;">
              <h2 style="font-size:20px;margin:0 0 10px;color:#111827;">Rapido</h2>
              <p style="margin:0;color:#4b5563;">Infraestructura preparada para publicar contenido desde el primer despliegue.</p>
            </div>
            <div style="border:1px solid #e5e7eb;padding:24px;border-radius:8px;background:#ffffff;">
              <h2 style="font-size:20px;margin:0 0 10px;color:#111827;">Seguro</h2>
              <p style="margin:0;color:#4b5563;">Acceso publico limitado a la web, con administracion protegida desde la red autorizada.</p>
            </div>
            <div style="border:1px solid #e5e7eb;padding:24px;border-radius:8px;background:#ffffff;">
              <h2 style="font-size:20px;margin:0 0 10px;color:#111827;">Gestionado</h2>
              <p style="margin:0;color:#4b5563;">Servicios instalados y mantenidos mediante SaltStack para repetir el despliegue de forma fiable.</p>
            </div>
          </section>
          <section style="padding:28px 0;">
            <p style="font-size:18px;margin:0 0 16px;color:#374151;">Gracias por confiar en Unclick. Puedes visitar nuestra pagina oficial en <a href="https://unclick.cat" style="color:#0f766e;font-weight:700;">unclick.cat</a>.</p>
          </section>
        </div>'
        PAGE_ID=$(wp post list --path={{ pillar['web-server']['webroot'] }} --post_type=page --name=pagina-de-bienvenida --field=ID --allow-root | head -1)
        if [ -z "$PAGE_ID" ]; then
          PAGE_ID=$(wp post create --path={{ pillar['web-server']['webroot'] }} \
            --post_type=page \
            --post_title='Pagina de Bienvenida' \
            --post_name='pagina-de-bienvenida' \
            --post_content="$CONTENT" \
            --post_status=publish \
            --porcelain \
            --allow-root)
        fi
        wp option update show_on_front page --path={{ pillar['web-server']['webroot'] }} --allow-root
        wp option update page_on_front $PAGE_ID --path={{ pillar['web-server']['webroot'] }} --allow-root
        wp option update blog_public 1 --path={{ pillar['web-server']['webroot'] }} --allow-root
    - unless: test "$(wp option get show_on_front --path={{ pillar['web-server']['webroot'] }} --allow-root 2>/dev/null)" = "page" && test -n "$(wp option get page_on_front --path={{ pillar['web-server']['webroot'] }} --allow-root 2>/dev/null)" && test "$(wp option get page_on_front --path={{ pillar['web-server']['webroot'] }} --allow-root 2>/dev/null)" != "0"
    - require:
      - cmd: crear_pagina_bienvenida
