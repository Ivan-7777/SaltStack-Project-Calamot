# Instala el paquete Restic en el sistema
instalar_restic:
  pkg.installed:
    - name: restic

# Crea archivo de entorno seguro con credenciales
# Evita exponer contraseña directamente en scripts
crear_env_restic:
  file.managed:
    - name: /root/.restic_env
    - mode: 600
    - contents: |
        # Variables necesarias para conectar con el repositorio
        export RESTIC_REPOSITORY="{{ pillar['restic']['repository'] }}"
        export RESTIC_PASSWORD="{{ pillar['restic']['password'] }}"

# Crea el script de backup en el sistema
crear_script_backup:
  file.managed:
    - name: /usr/local/bin/restic_backup.sh
    - mode: 755
    - contents: |
        #!/bin/bash

        # Carga variables del entorno
        source /root/.restic_env

        # Nombre de la máquina
        HOSTNAME=$(hostname)

        # Fecha actual
        DATE=$(date '+%Y-%m-%d %H:%M:%S')

        # Ejecuta backup de rutas definidas en pillar
        restic backup {% for path in pillar['restic']['backup_paths'] %} {{ path }} {% endfor %}

        # Guarda resultado del comando
        RESULT=$?

        # Determina estado del backup
        if [ $RESULT -eq 0 ]; then
            STATUS="success"
        else
            STATUS="fail"
        fi

        # Inserta resultado en la base de datos central
        mysql -u {{ pillar['mysql']['user'] }} -p{{ pillar['mysql']['password'] }} -h {{ pillar['mysql']['host'] }} -D {{ pillar['mysql']['database'] }} -e "
        INSERT INTO machine_backups (hostname, backup_path, status, execution_time)
        VALUES ('$HOSTNAME', 'restic_repo', '$STATUS', '$DATE');
        "

# Programa ejecución automática mediante cron
programar_cron:
  cron.present:
    - name: "/usr/local/bin/restic_backup.sh"
    - user: root
    - minute: {{ pillar['restic']['cron_minute'] }}
    - hour: {{ pillar['restic']['cron_hour'] }}
