# Proteccion kernel (sysctl)
kernel_hardening:
  file.managed:
    - name: /etc/sysctl.d/99-hardening.conf
    - source: salt://security/files/sysctl-hardening.conf
    - user: root
    - group: root
    - mode: 644

apply_sysctl:
  cmd.run:
    - name: sysctl --system
    - require:
      - file: kernel_hardening


# Instalar SSH
install_openssh:
  pkg.installed:
    - name: openssh-server

# Proteccion SSH
ssh_hardening:
  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://security/files/sshd_config
    - user: root
    - group: root
    - mode: 600

restart_ssh:
  service.running:
    - name: ssh
    - enable: True
    - watch:
      - file: ssh_hardening


# Proteccion minion
salt_minion_hardening:
  file.managed:
    - name: /etc/salt/minion.d/hardening.conf
    - contents: |
        multiprocessing: False
        acceptance_wait_time: 10
    - user: root
    - group: root
    - mode: 644

restart_salt_minion:
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - file: salt_minion_hardening

# Proteccion directorios criticos
secure_salt_pki:
  file.directory:
    - name: /etc/salt/pki
    - user: root
    - group: root
    - mode: 700

# Auditoria de logs - permisos
secure_auth_log:
  file.managed:
    - name: /var/log/auth.log
    - user: root
    - group: adm
    - mode: 640
    - replace: False

secure_syslog:
  file.managed:
    - name: /var/log/syslog
    - user: root
    - group: adm
    - mode: 640
    - replace: False

