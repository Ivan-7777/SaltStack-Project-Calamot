# Pillar data for the Restic backup client (PRUEBA)
restic:
  # Repositorio remoto vía REST API (conecta al rest-server en MINIONBACKUP)
  # El rest-server escucha en 192.168.0.10:8000 con --path /backups/restic
  repository: "rest:http://192.168.0.10:8000/"
  # Debe coincidir con la contraseña del servidor
  password: "R3st1c_B@ckup_S3cur3_2026!"
  # Directorios a respaldar
  backup_paths:
    - /etc
    - /home
    - /var/www
  # Programación cron: diario a las 01:00
  cron_minute: "0"
  cron_hour: "1"
  # Puerto del servidor SSH en el servidor de backups
  ssh_server_port: 22

# Conexión a MariaDB para logging de resultados
# La BD está en MINIONBDD (192.168.0.7)
mysql:
  host: "192.168.0.7"
  port: 3306
  user: "saltlogger"
  password: "S@ltL0gg3r_2026!"
  database: "salt_logs"
  root_password: "M@r1aDB_R00t_2026!"
