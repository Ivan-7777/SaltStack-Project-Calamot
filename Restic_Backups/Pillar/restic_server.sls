# Pillar data for the Restic backup server (MINIONBACKUP)
restic:
  # Repositorio local en el servidor de backups
  repository: /backups/restic
  # Contraseña fuerte para el repositorio Restic
  password: "R3st1c_B@ckup_S3cur3_2026!"
  # Puerto SSH para conexiones entrantes de clientes
  ssh_port: 22
  # Programación cron para tareas de mantenimiento (prune, forget, check)
  cron_minute: "30"
  cron_hour: "2"
  # Claves públicas SSH de clientes (se despliegan en authorized_keys del usuario salt)
  client_ssh_public_key: |
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL/8TCgu+JU1cSZjoGd+ArC8xvA59EzlsuS5PzIyOWMB root@debian
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0HR31XJCNtdRUbzAVXKW+pEVkMuj5sZky5xBhYbbSy9MjG6LII9c3uufeTsQkKPL2fo5AakDISZ6zeSQJls5ipDza7uwtV1RPvUbklLrqwKwSUI8On6ABbcWcIyLcOuDGeP76wKcQXC06UJUcJc90iBAQLOkjk/j8uXFbN8wShcDQs0VtnlqoRLkjg5a4cquJiQiNxLxH2bpK/3h6pBflFKi5y7JmfoJn/VQ1YjIwNYMqAZdJOVUbkgLVBz+5xpPaxFsssCsuFQfe2rVZJ8HgPPU0lMFm2PLPDRTL1BmUhYIoQzlO5lQrYbUMrrnUkG7AOLT2cRBWB+WmcaxpCB5kyPCJm0ORCXgCHnun7h7NJlgZ90OTDdTaicvIDHWF9g4FUD65FiG6APRDkaIZe1w1ijM1R9I0UeKM3thNG9z9enFGi+ns1J49mhalAMan6F55uCc3jXSSSt8w2BADOVg6heZwB2ed/7vOOX9LRNEbunL5z6UOPTGuwxB48SpkJyQ/LjLoPnuGLf8+GO6E0H1lPUFj5JJTU1pUQtjP3IJS/I8Uh1e1lKV1cRkXANXjaFeIhi9BXI0xP8gAfun0f/JdqZSaG6CbWx1vDFWOEjSGMdB0JS7uSTnAhGBe7V+aPSZNqnsxwno4tzYLyiLC0FI2JPc/JMuVSmmpDTZtVJWJfw== root@debian

# Conexión a MariaDB para logging de resultados
# La BD está en MINIONBDD (192.168.0.7)
mysql:
  host: "192.168.0.7"
  port: 3306
  user: "saltlogger"
  password: "S@ltL0gg3r_2026!"
  database: "salt_logs"
  root_password: "M@r1aDB_R00t_2026!"
