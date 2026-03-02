# Salt Minion Installer

Este script proporciona una forma **rápida y automatizada** de instalar y configurar un **Salt Minion** en una máquina nueva, de modo que se pueda conectar a un **Salt Master** y estar listo para recibir estados y configuraciones.

---

## 📋 Descripción

El script realiza las siguientes tareas:

1. **Detección de la distribución Linux**:
   - Debian/Ubuntu
   - RHEL/CentOS/Rocky
   - Arch Linux
   - Salida de error si la distribución no está soportada

2. **Instalación del Salt Minion**:
   - Configura el repositorio oficial de Salt según la distro
   - Instala el paquete `salt-minion` usando el gestor de paquetes correspondiente (`apt`, `dnf` o `pacman`)

3. **Configuración del Minion**:
   - Crea o modifica `/etc/salt/minion`
   - Configura la **IP del Salt Master** (`master`)
   - Configura el **ID del minion** (`id`) que identificará a la máquina en el Master

4. **Habilitación y arranque del servicio**:
   - Activa el servicio `salt-minion` para que arranque automáticamente
   - Reinicia el servicio para aplicar la configuración

5. **Indicaciones finales**:
   - Muestra instrucciones para aceptar la clave del minion en el Salt Master (`salt-key -A`)
   - Muestra el ID del minion configurado

---

## ⚙️ Uso

Ejecutar el script como **root**:

```bash
sudo python3 salt-minion-installer.py

Durante la ejecución se solicitará:

La IP del Salt Master

El nombre/ID del minion a usar

Ejemplo de ejecución:

=== Instalación de Salt Minion ===
IP del Salt Master: 192.168.0.100
Nombre / ID del minion: oficina1-fw

[+] Distribución detectada: debian
[+] Ejecutando: apt update
[+] Ejecutando: apt install -y curl gnupg
...
✅ Salt Minion instalado y en ejecución
➡️ Acepta la clave en el master con: salt-key -A
➡️ Minion ID: oficina1-fw
✅ Requisitos

Acceso como root o mediante sudo

Python 3 instalado

Conexión a Internet para descargar repositorios y paquetes

🔹 Compatibilidad de distribuciones

Debian / Ubuntu

RHEL / CentOS / Rocky Linux

Arch Linux

Otras distribuciones mostrarán un mensaje de error y finalizarán la ejecución.

💡 Ventajas

Instalación y configuración automatizada del Salt Minion

Compatible con múltiples distribuciones

Configura automáticamente la conexión con el Salt Master

Minimiza errores humanos en la configuración inicial

Preparado para integrarse en un flujo de despliegue profesional

🔧 Flujo interno

Detecta la distribución

Instala los paquetes necesarios y el minion

Crea /etc/salt/minion con master y ID

Habilita y reinicia el servicio salt-minion

Indica los pasos finales para aceptar el minion en el Master
