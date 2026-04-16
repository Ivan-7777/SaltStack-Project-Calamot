# ============================================================
# Restic - Estado del Cliente de Backups (PRUEBA / minion_prueba)
# ============================================================
# Este estado configura una máquina cliente para enviar backups
# al repositorio central Restic mediante la API REST.
#
# Funcionalidades:
#   - Instala Restic y cliente MySQL
#   - Crea archivo de entorno con credenciales Restic
#   - Despliega script de backup con validación de conectividad
#   - Programa cron para backups automáticos
# ============================================================

# --- 1. Instalar paquetes requeridos ---
restic_installed:
  pkg.installed:
    - name: restic

curl_installed:
  pkg.installed:
    - name: curl

mysql_client:
  pkg.installed:
    - name: default-mysql-client

# --- 2. Crear archivo de entorno con credenciales Restic ---
# Contiene RESTIC_REPOSITORY y RESTIC_PASSWORD
# Permisos restrictivos: solo root puede leer
restic_env_file:
  file.managed:
    - name: /root/.restic_env
    - user: root
    - group: root
    - mode: "0600"
    - contents: |
        # Variables de entorno de Restic para el cliente
        export RESTIC_REPOSITORY="{{ pillar['restic']['repository'] }}"
        export RESTIC_PASSWORD="{{ pillar['restic']['password'] }}"

# --- 3. Desplegar script de backup ---
# Se usa template: jinja para renderizar variables del pillar
# como las rutas de backup y credenciales MySQL
backup_script:
  file.managed:
    - name: /usr/local/bin/restic_backup.sh
    - user: root
    - group: root
    - mode: "0750"
    - template: jinja
    - source: salt://restic/client/restic_backup.sh
    - require:
      - pkg: restic_installed
      - pkg: curl_installed
      - pkg: mysql_client
      - file: restic_env_file

# --- 4. Programar backup vía cron ---
# Se ejecuta diariamente a la 01:00 (configurable por pillar)
backup_cron:
  cron.present:
    - name: "/usr/local/bin/restic_backup.sh >> /var/log/restic_backup.log 2>&1"
    - user: root
    - minute: "{{ pillar.get('restic', {}).get('cron_minute', '0') }}"
    - hour: "{{ pillar.get('restic', {}).get('cron_hour', '1') }}"
