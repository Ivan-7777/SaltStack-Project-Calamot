# Instalar el pkg de apache2
apache2:
  pkg.installed:
    - name: apache2

# Pasar el index.html de la pagina principal de hosting
web_conf:
  file.managed:
    - name: /var/www/html/index.html
    - source: salt://web-server/index.html
    - makedirs: True
    - show_changes: False

# Para crear si no esta creado el .ssh dentro de /root/
ssh_dir_root:
  file.directory:
    - name: /root/.ssh
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

# Para generar la clave ssh
generate_ssh_key:
  cmd.run:
    - name: ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" -q
    - unless: test -f /root/.ssh/id_ed25519
    - require:
      - file: ssh_dir_root

# Para añadir la clave pública al authorized_keys
add_ssh_key:
  ssh_auth.present:
    - user: root
    - name: root
    - enc: ssh-ed25519
    - source: /root/.ssh/id_ed25519.pub
    - require:
      - cmd: generate_ssh_key

# Para pasar la configuración del ssh
ssh_conf:
  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://web-server/sshd_config
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True

# Para pasar la configuración del dns 
dns_conf:
  file.managed:
    - name: /etc/resolv.conf
    - source: salt://web-server/resolv.conf
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True

# Para reinciar el servició de apache2 y habilitarlo
apache2_service:
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - file: web_conf

# Para pasar el script de cración de pagina web (este sirve para facilitarlo)
autohosting_sh:
  file.managed:
    - name: /root/Scripts/autohosting.sh
    - source: salt://web-server/autohosting.sh
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

# Para pasar el script de eliminación de pagina web (este sirve para facilitarlo)
autorhosting_sh:
  file.managed:
    - name: /root/Scripts/autorhosting.sh
    - source: salt://web-server/autorhosting.sh
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

# Pasar el interfaces para cuando tengamos nuestro dserver dhcp le de ip fija por mac ya que es un servidor y los servidores deben de tener ip fija por mac
interfaces_conf:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://web-server/interfaces
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True

# NUEVO: Crear directorio para reglas udev si no existe
udev_rules_dir:
  file.directory:
    - name: /etc/udev/rules.d
    - user: root
    - group: root
    - mode: 0755

# NUEVO: Crear regla udev para forzar nombre eth0 por MAC
create_udev_rule:
  cmd.run:
    - name: |
        IFACE=$(ls /sys/class/net | grep -v lo | head -n 1)
        MAC=$(cat /sys/class/net/$IFACE/address)
        echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="'$MAC'", NAME="eth0"' | tee /etc/udev/rules.d/10-network.rules
    - unless: |
        # Verificar si la regla ya existe y es correcta
        IFACE=$(ls /sys/class/net | grep -v lo | head -n 1)
        CURRENT_MAC=$(cat /sys/class/net/$IFACE/address 2>/dev/null)
        if [ -f /etc/udev/rules.d/10-network.rules ]; then
          grep -q "ATTR{address}==\"$CURRENT_MAC\"" /etc/udev/rules.d/10-network.rules
        else
          false
        fi
    - require:
      - file: udev_rules_dir

# NUEVO: Recargar reglas udev si se crea o modifica la regla
reload_udev_rules:
  cmd.run:
    - name: udevadm control --reload-rules && udevadm trigger --attr-match=subsystem=net
    - onchanges:
      - cmd: create_udev_rule

# Reiniciar y habilitar el servicio ssh
ssh_service:
  service.running:
    - name: ssh
    - enable: True
    - reload: True
    - watch:
      - file: ssh_conf

# Reiniciar Maquina para que se reinicien los demas servicios entre estos el networking.service
reiniar-maquinaweb:
  cmd.run:
    - name: sleep 20 && reboot
