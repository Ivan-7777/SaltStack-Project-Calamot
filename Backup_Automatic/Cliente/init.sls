instalar_restic:
  pkg.installed:
    - name: restic

crear_script_backup:
  file.managed:
    - name: /usr/local/bin/restic_backup.sh
    - mode: 755
    - contents: |
        #!/bin/bash

        export RESTIC_REPOSITORY="{{ pillar['restic']['repository'] }}"
        export RESTIC_PASSWORD="{{ pillar['restic']['password'] }}"

        restic backup {% for path in pillar['restic']['backup_paths'] %} {{ path }} {% endfor %}

programar_cron:
  cron.present:
    - name: "/usr/local/bin/restic_backup.sh"
    - user: root
    - minute: {{ pillar['restic']['cron_minute'] }}
    - hour: {{ pillar['restic']['cron_hour'] }}
conn.close()
