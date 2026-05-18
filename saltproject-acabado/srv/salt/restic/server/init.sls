# Restic - Servidor de Backups (minion-08)

restic_installed:
  pkg.installed:
    - name: restic

rest_server_installed:
  pkg.installed:
    - name: restic-rest-server

rest_server_default:
  file.managed:
    - name: /etc/default/restic-rest-server
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        LISTEN = :{{ salt['pillar.get']('restic:port', 8000) }}
        BACKUP_DIR = /backups/restic
        ARGS = "--no-auth"
    - require:
      - pkg: rest_server_installed

mysql_client:
  pkg.installed:
    - name: default-mysql-client

rest_server_service_running:
  service.running:
    - name: restic-rest-server
    - enable: True
    - reload: True
    - require:
      - pkg: rest_server_installed
      - file: rest_server_default
      - cmd: init_restic_repo
    - watch:
      - file: rest_server_default

backups_parent_dir:
  file.directory:
    - name: /backups
    - user: root
    - group: root
    - mode: "0755"
    - makedirs: True

repo_directory:
  file.directory:
    - name: /backups/restic
    - user: restic-rest-server
    - group: restic-rest-server
    - mode: "0750"
    - makedirs: True
    - require:
      - file: backups_parent_dir

init_restic_repo:
  cmd.run:
    - name: RESTIC_PASSWORD="{{ pillar['restic']['password'] }}" restic init --repo /backups/restic
    - unless: test -f /backups/restic/config
    - runas: restic-rest-server
    - require:
      - file: repo_directory

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

server_env_file:
  file.managed:
    - name: /root/.restic_env
    - user: root
    - group: root
    - mode: "0600"
    - contents: |
        export RESTIC_REPOSITORY="/backups/restic"
        export RESTIC_PASSWORD="{{ pillar['restic']['password'] }}"

restic_maintenance_cron:
  cron.present:
    - name: "/usr/local/bin/restic_maintenance.sh >> /var/log/restic_maintenance.log 2>&1"
    - user: root
    - minute: "{{ salt['pillar.get']('restic:cron_minute', '30') }}"
    - hour: "{{ salt['pillar.get']('restic:cron_hour', '2') }}"
