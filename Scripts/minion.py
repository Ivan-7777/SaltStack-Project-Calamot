#!/usr/bin/env python3
import os
import subprocess
import sys

MINION_CONF = "/etc/salt/minion"

def run(cmd):
    print(f"[+] Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def detect_distro():
    with open("/etc/os-release") as f:
        data = f.read().lower()
    if "debian" in data or "ubuntu" in data:
        return "debian"
    elif "rocky" in data or "centos" in data or "rhel" in data:
        return "rhel"
    elif "arch" in data:
        return "arch"
    else:
        return "unknown"

def install_salt(distro):
    if distro == "debian":
        run("apt update")
        run("apt install -y curl gnupg")
        # Clave de Broadcom
        run(
            "curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public "
            "-o /usr/share/keyrings/salt-archive-keyring-2023.pgp"
        )
        # Repositorio Broadcom
        run(
            'echo "deb [signed-by=/usr/share/keyrings/salt-archive-keyring-2023.pgp arch=amd64] '
            'https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" '
            '> /etc/apt/sources.list.d/salt.list'
        )
        run("apt update")
        run("apt install -y salt-minion")

    elif distro == "rhel":
        run("dnf install -y https://repo.saltproject.io/salt/py3/redhat/salt-py3-repo-latest.noarch.rpm")
        run("dnf install -y salt-minion")

    elif distro == "arch":
        run("pacman -Sy --noconfirm salt")

    else:
        print("❌ Distribución no soportada")
        sys.exit(1)

def configure_minion(master_ip, minion_id):
    """Configura el minion con la IP del master y el ID del minion."""
    os.makedirs("/etc/salt", exist_ok=True)
    with open(MINION_CONF, "w") as f:
        f.write(f"""master: {master_ip}
id: {minion_id}
""")

def enable_minion():
    run("systemctl enable salt-minion")
    run("systemctl restart salt-minion")

def main():
    if os.geteuid() != 0:
        print("❌ Ejecuta este script como root")
        sys.exit(1)

    print("=== Instalación de Salt Minion ===")

    master_ip = input("IP del Salt Master: ").strip()
    if not master_ip:
        print("❌ La IP del master no puede estar vacía")
        sys.exit(1)

    minion_id = input("Nombre / ID del minion: ").strip()
    if not minion_id:
        print("❌ El ID del minion no puede estar vacío")
        sys.exit(1)

    distro = detect_distro()
    print(f"[+] Distribución detectada: {distro}")

    install_salt(distro)
    configure_minion(master_ip, minion_id)
    enable_minion()

    print("\n✅ Salt Minion instalado y en ejecución")
    print("➡️ Acepta la clave en el master con: salt-key -A")
    print(f"➡️ Minion ID: {minion_id}")

if __name__ == "__main__":
    main()
  
