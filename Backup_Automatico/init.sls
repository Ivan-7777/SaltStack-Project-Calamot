# Distribuir scripts a cada minion
backup_y_scripts:
  file.managed:
    - name: /usr/local/bin/backup_maquina.sh
    - source: salt://backups/backup_maquina.sh
    - mode: 755

  file.managed:
    - name: /usr/local/bin/salt_db_logger.py
    - source: salt://backups/salt_db_logger.py
    - mode: 755

 # Programar cron para ejecutar backup_machine.sh diariamente a las 2:00
  cron.present:
    - name: '/usr/local/bin/backup_maquina.sh'
    - user: root
    - minute: 0
    - hour: 2
