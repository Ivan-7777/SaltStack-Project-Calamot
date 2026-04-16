# ============================================================
# Restic - Estado del Servidor de Backups (MINIONBACKUP)
# ============================================================
# Este estado configura el servidor de backups que almacena
# repositorios Restic de múltiples clientes mediante REST API.
#
# Funcionalidades:
#   - Instala Restic y restic-rest-server
#   - Configura y arranca el servicio REST en puerto 8000
#   - Crea el repositorio Restic local (idempotente)
#   - Despliega script de mantenimiento con logging a MariaDB
#   - Programa cron para mantenimiento automático
# ============================================================

# --- 1. Instalar paquetes requeridos ---
restic_installed:
  pkg.installed:
    - name: restic

rest_server_installed:
  pkg.installed:
    - name: restic-rest-server

openssh_server:
  pkg.installed:
    - name: openssh-server

mysql_client:
  pkg.installed:
    - name: default-mysql-client

# --- 2. Asegurar que el servicio SSH está activo ---
ssh_service_running:
  service.running:
    - name: ssh
    - enable: True
    - require:
      - pkg: openssh_server

# --- 3. Configurar servicio restic-rest-server ---
# El servicio del servidor REST necesita configuración correcta
# para escuchar en el puerto 8000 y usar el directorio de backups.
rest_server_service_running:
  service.running:
    - name: restic-rest-server
    - enable: True
    - reload: True
    - require:
      - pkg: rest_server_installed
      - file: repo_directory
    # Reiniciar si la configuración cambia
    - watch:
      - file: repo_directory

# --- 4. Crear usuario dedicado 'salt' para gestión ---
salt_user_present:
  user.present:
    - name: salt
    - shell: /bin/bash
    - home: /home/salt
    - createhome: True
    - system: True

# --- 5. Configurar directorio SSH del usuario salt ---
salt_user_ssh_dir:
  file.directory:
    - name: /home/salt/.ssh
    - user: salt
    - group: salt
    - mode: "0700"
    - makedirs: True

# --- 6. Configurar claves SSH autorizadas para acceso de clientes ---
# Se importa la clave pública del cliente para permitir conexiones SSH
# Se usa ssh_auth.present para manejar claves SSH de forma nativa
{% set ssh_keys = salt['pillar.get']('restic:client_ssh_public_key', '').strip().splitlines() %}
{% for key in ssh_keys %}
{% if key.strip() %}
salt_user_authorized_key_{{ loop.index }}:
  ssh_auth.present:
    - user: salt
    - enc: {{ key.strip().split()[0] }}
    - name: {{ key.strip() }}
    - require:
      - file: salt_user_ssh_dir
{% endif %}
{% endfor %}

# --- 7. Crear directorio padre /backups (si no existe) ---
backups_parent_dir:
  file.directory:
    - name: /backups
    - user: root
    - group: root
    - mode: "0755"
    - makedirs: True

# --- 8. Crear directorio del repositorio Restic ---
# IMPORTANTE: El repositorio debe pertenecer al usuario restic-rest-server
# ya que el servicio REST se ejecuta bajo ese usuario.
repo_directory:
  file.directory:
    - name: /backups/restic
    - user: restic-rest-server
    - group: restic-rest-server
    - mode: "0750"
    - makedirs: True
    - require:
      - file: backups_parent_dir

# --- 8. Inicializar repositorio Restic (solo si no existe) ---
# Verificación idempotente: NO se reinicializa si ya existe el config
init_restic_repo:
  cmd.run:
    - name: >
        RESTIC_PASSWORD="{{ pillar['restic']['password'] }}"
        restic init --repo /backups/restic
    - unless: test -f /backups/restic/config
    - runas: restic-rest-server
    - require:
      - file: repo_directory

# --- 9. Desplegar script de mantenimiento del servidor ---
server_maintenance_script:
  file.managed:
    - name: /usr/local/bin/restic_maintenance.sh
    - source: salt://restic/server/restic_backup.sh
    - user: root
    - group: root
    - mode: "0750"
    - template: jinja
    - require:
      - pkg: mysql_client

# --- 10. Crear archivo de entorno para scripts del servidor ---
# Contiene las variables RESTIC necesarias (repositorio + contraseña)
server_env_file:
  file.managed:
    - name: /root/.restic_env
    - user: root
    - group: root
    - mode: "0600"
    - contents: |
        # Variables de entorno de Restic para scripts del servidor
        export RESTIC_REPOSITORY="/backups/restic"
        export RESTIC_PASSWORD="{{ pillar['restic']['password'] }}"

# --- 11. Programar tarea cron de mantenimiento ---
# Se ejecuta diariamente a las 02:30 (configurable por pillar)
restic_maintenance_cron:
  cron.present:
    - name: "/usr/local/bin/restic_maintenance.sh >> /var/log/restic_maintenance.log 2>&1"
    - user: root
    - minute: "{{ pillar.get('restic', {}).get('cron_minute', '30') }}"
    - hour: "{{ pillar.get('restic', {}).get('cron_hour', '2') }}"
