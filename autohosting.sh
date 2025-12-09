#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURACIÓN AUTOMÁTICA DE SITIO WEB, USUARIO SFTP Y SSL (PRUEBA)
# Versión: 3.0 (Mejorada con SSL)
# Descripción: Crea la estructura de un sitio web, configura un VirtualHost en
#              Apache2, crea un usuario del sistema, lo configura para SFTP y
#              añade un certificado SSL de prueba (self-signed) para HTTPS.
# ==============================================================================

# --- Variables de Estilo ---
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
AZUL='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BLANCO='\033[1;37m'
NC='\033[0m' # Sin color

# --- Funciones de Utilidad ---

# Función para mostrar un mensaje de éxito
success() {
    echo -e "${VERDE}✅ ÉXITO:${NC} $1"
}

# Función para mostrar un mensaje de error
error() {
    echo -e "${ROJO}❌ ERROR:${NC} $1" >&2
    exit 1
}

# Función para mostrar un mensaje de información
info() {
    echo -e "${AZUL}ℹ️ INFO:${NC} $1"
}

# Función para mostrar un encabezado
header() {
    echo -e "\n${CYAN}==================================================${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${CYAN}==================================================${NC}\n"
}

# Función para verificar si se ejecuta como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse con privilegios de root (sudo)."
    fi
}

# --- Lógica Principal del Script ---

clear
check_root

header "INICIO DE CONFIGURACIÓN DE SITIO WEB CON SOPORTE SSL"

# 1. Solicitud de información inicial
while true; do
    echo -e "${BLANCO}Paso 1/7: Información Inicial${NC}"
    echo -e "Por favor, introduce el nombre de dominio deseado (ej: ${AMARILLO}misitio.com${NC}):"
    read -r nombre_dominio

    if [[ -z "$nombre_dominio" ]]; then
        echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} El nombre del dominio no puede estar vacío."
    elif [[ "$nombre_dominio" =~ [[:space:]] ]]; then
        echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} El nombre del dominio no debe contener espacios."
    else
        break
    fi
done

nombre_sitio=$(echo "$nombre_dominio" | sed 's/\.[^.]*$//') # Nombre corto para archivos de log/config

# 2. Instalación de paquetes necesarios
clear
header "Paso 2/7: Instalación de Paquetes"
info "Actualizando lista de paquetes e instalando Apache2 y SSL..."
apt update > /dev/null 2>&1
apt install -y apache2 ssl-cert > /dev/null 2>&1 || error "Fallo al instalar Apache2 o ssl-cert."
a2enmod ssl > /dev/null 2>&1
a2enmod headers > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
systemctl restart apache2 > /dev/null 2>&1
success "Paquetes instalados y módulos de Apache habilitados."

# 3. Verificar existencia previa
clear
header "Paso 3/7: Verificación de Existencia"
info "Verificando si el sitio ${nombre_dominio} ya existe..."
if [ -d "/var/www/$nombre_dominio" ]; then
    error "El directorio de la web /var/www/$nombre_dominio ya existe. Abortando."
fi
if [ -f "/etc/apache2/sites-available/$nombre_dominio.conf" ]; then
    error "El archivo de configuración de Apache /etc/apache2/sites-available/$nombre_dominio.conf ya existe. Abortando."
fi
success "Verificación completada. El sitio es nuevo."

# 4. Crear la estructura de directorios y archivo index.html
clear
header "Paso 4/7: Creación de Directorios y Archivo Index"
info "Creando directorio raíz: /var/www/$nombre_dominio"
mkdir -p "/var/www/$nombre_dominio/pagina" || error "Fallo al crear directorios."

archivo_index="/var/www/$nombre_dominio/pagina/index.html"
info "Creando archivo de prueba: $archivo_index"

nuevo_contenido_index="<!DOCTYPE html>
<html lang=\"es\">
<head>
    <meta charset=\"UTF-8\">
    <title>Bienvenido a $nombre_dominio</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f4f4f4; }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <h1>¡Bienvenido a tu nueva página web: $nombre_dominio!</h1>
    <p>Este es el archivo de prueba. Puedes editarlo en ${AMARILLO}/var/www/$nombre_dominio/pagina/index.html${NC}</p>
    <p>Configuración completada con éxito.</p>
</body>
</html>"

echo "$nuevo_contenido_index" > "$archivo_index" || error "Fallo al escribir el archivo index.html."
success "Estructura de directorios y archivo index.html creados."

# 5. Configurar Apache VirtualHost (HTTP y HTTPS)
clear
header "Paso 5/7: Configuración de Apache2 (HTTP y HTTPS)"
archivo_conf="/etc/apache2/sites-available/$nombre_dominio.conf"
info "Generando archivo de configuración de VirtualHost: $archivo_conf"

# Generar un certificado SSL auto-firmado para entornos de prueba
info "Generando certificado SSL auto-firmado para pruebas..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "/etc/ssl/private/$nombre_dominio.key" \
    -out "/etc/ssl/certs/$nombre_dominio.crt" \
    -subj "/C=ES/ST=Local/L=Local/O=TestOrg/OU=TestUnit/CN=$nombre_dominio" > /dev/null 2>&1 || error "Fallo al generar el certificado SSL."
success "Certificado SSL auto-firmado generado."

# Usamos un 'here document' para la configuración de Apache, incluyendo HTTP y HTTPS.
cat << EOF > "$archivo_conf"
# Redirección de HTTP a HTTPS
<VirtualHost *:80>
    ServerName $nombre_dominio
    ServerAlias www.$nombre_dominio
    Redirect permanent / https://$nombre_dominio/
</VirtualHost>

# Configuración de HTTPS
<VirtualHost *:443>
    ServerAdmin webmaster@$nombre_dominio
    ServerName $nombre_dominio
    ServerAlias www.$nombre_dominio
    DocumentRoot /var/www/$nombre_dominio/pagina

    ErrorLog \${APACHE_LOG_DIR}/$nombre_sitio-error.log
    CustomLog \${APACHE_LOG_DIR}/$nombre_sitio-access.log combined

    <Directory /var/www/$nombre_dominio/pagina>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Configuración SSL
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/$nombre_dominio.crt
    SSLCertificateKeyFile /etc/ssl/private/$nombre_dominio.key
</VirtualHost>
EOF

# Habilitar sitio y reiniciar Apache
info "Habilitando el sitio con a2ensite..."
a2ensite "$nombre_dominio.conf" > /dev/null 2>&1 || error "Fallo al habilitar el sitio con a2ensite."

info "Reiniciando el servicio Apache2..."
systemctl restart apache2 || error "Fallo al reiniciar Apache2. Revisa los logs."
success "Configuración de Apache2 (HTTP y HTTPS) completada y servicio reiniciado."

# 6. Configurar Usuario y Permisos
clear
header "Paso 6/7: Configuración de Usuario y Permisos SFTP"

# El nombre de usuario será el nombre corto del sitio
nombre_usuario="$nombre_sitio"

# Crear usuario (si no existe)
if id "$nombre_usuario" &>/dev/null; then
    info "El usuario ${nombre_usuario} ya existe. Saltando la creación de usuario."
else
    info "Creando usuario del sistema: ${nombre_usuario}"
    # adduser pide contraseña interactivamente.
    adduser "$nombre_usuario" || error "Fallo al crear el usuario ${nombre_usuario}."
fi

# Configurar permisos
info "Estableciendo permisos y propiedad de directorios..."
# 1. Establecer el propietario del directorio raíz de la web
chown -R "$nombre_usuario":"$nombre_usuario" "/var/www/$nombre_dominio" || error "Fallo al cambiar la propiedad."

# 2. Permisos para el directorio raíz (solo lectura/ejecución para el usuario, para chroot)
chmod 755 "/var/www/$nombre_dominio" || error "Fallo al establecer permisos en el directorio raíz."

# 3. Permisos para el directorio de la página (lectura/escritura/ejecución para el usuario)
chmod -R 755 "/var/www/$nombre_dominio/pagina" || error "Fallo al establecer permisos en el directorio de la página."

# 4. Configurar SFTP Chroot en sshd_config
info "Configurando SFTP Chroot en /etc/ssh/sshd_config..."
sftp_config="
# --- Configuración SFTP para $nombre_dominio ---
Match User $nombre_usuario
        ChrootDirectory /var/www/$nombre_dominio
        ForceCommand internal-sftp
        X11Forwarding no
        AllowTcpForwarding no
        PasswordAuthentication yes
# ------------------------------------------------
"

# Verificar si la configuración ya existe para evitar duplicados
if grep -q "Match User $nombre_usuario" /etc/ssh/sshd_config; then
    info "La configuración SFTP para ${nombre_usuario} ya existe. Saltando la adición."
else
    echo "$sftp_config" >> /etc/ssh/sshd_config || error "Fallo al escribir en sshd_config."
    info "Reiniciando el servicio SSH..."
    systemctl restart ssh.service || error "Fallo al reiniciar SSH. Revisa la configuración."
fi

success "Configuración de usuario y SFTP completada."

# 7. Resumen Final
clear
header "Paso 7/7: RESUMEN Y PRÓXIMOS PASOS"

echo -e "${VERDE}SUCCESSFULLY DOMAIN CREATION${NC}"
echo -e "Se ha configurado el sitio web para el dominio: ${BLANCO}$nombre_dominio${NC}"
echo -e "El sitio está configurado para usar ${MAGENTA}HTTPS${NC} con un certificado de prueba."
echo -e "El usuario SFTP creado es: ${BLANCO}$nombre_usuario${NC}"
echo -e "El directorio raíz de tu sitio es: ${BLANCO}/var/www/$nombre_dominio/pagina${NC}"

echo -e "\n${AMARILLO}PRÓXIMOS PASOS IMPORTANTES:${NC}"
echo -e "1. ${BLANCO}Acceso al sitio:${NC} Para acceder desde tu máquina real, debes añadir la siguiente línea a tu archivo ${CYAN}/etc/hosts${NC} (o equivalente en Windows/Mac):"
echo -e "   ${MAGENTA}IP_MAQUINA_VIRTUAL\t$nombre_dominio${NC} (Reemplaza IP_MAQUINA_VIRTUAL con la IP real de tu servidor)"
echo -e "2. ${BLANCO}Advertencia SSL:${NC} Al acceder, tu navegador mostrará una advertencia de seguridad porque el certificado es auto-firmado. Debes aceptarla para continuar."
echo -e "3. ${BLANCO}Subir archivos:${NC} Usa el usuario ${nombre_usuario} y la contraseña que estableciste para conectarte por SFTP al servidor."
echo -e "4. ${BLANCO}Contraseña:${NC} Si no se te solicitó una contraseña, usa 'passwd $nombre_usuario' para establecerla."

