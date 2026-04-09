# Instala Restic en el servidor de backups
instalar_restic:
  pkg.installed:
    - name: restic

# Crea el directorio donde se almacenarán los backups
crear_directorio_backup:
  file.directory:
    - name: /backups/restic
    - user: root
    - group: root
    - mode: 755

# Inicializa el repositorio Restic solo si no existe
init_repo:
  cmd.run:
    - name: restic init --repo /backups/restic
    - unless: test -f /backups/restic/config
    - env:
        # Usa la contraseña definida en pillar
        RESTIC_PASSWORD: "{{ pillar['restic']['password'] }}"
