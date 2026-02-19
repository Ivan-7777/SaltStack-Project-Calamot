#!/bin/bash

# ==============================================================================
# SCRIPT DE GESTIÓN DE HOSTING WEB CON NGINX
# Versión: 1.0
# Descripción: Crea o elimina sitios web con Nginx, SSL, SFTP y gestión de usuarios
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

success() {
    echo -e "${VERDE}✅ ÉXITO:${NC} $1"
}

error() {
    echo -e "${ROJO}❌ ERROR:${NC} $1" >&2
    exit 1
}

info() {
    echo -e "${AZUL}ℹ️ INFO:${NC} $1"
}

header() {
    echo -e "\n${CYAN}==================================================${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${CYAN}==================================================${NC}\n"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse con privilegios de root (sudo)."
    fi
}

# --- Funciones para Crear Sitio ---

crear_sitio() {
    clear
    check_root

    header "CREACIÓN DE SITIO WEB CON NGINX"

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

    nombre_sitio=$(echo "$nombre_dominio" | sed 's/\.[^.]*$//')

    # 2. Instalación de paquetes necesarios
    clear
    header "Paso 2/7: Instalación de Paquetes"
    info "Actualizando lista de paquetes e instalando Nginx y SSL..."
    apt update > /dev/null 2>&1
    apt install -y nginx ssl-cert > /dev/null 2>&1 || error "Fallo al instalar Nginx o ssl-cert."
    systemctl restart nginx > /dev/null 2>&1
    success "Paquetes instalados y Nginx reiniciado."

    # 3. Verificar existencia previa
    clear
    header "Paso 3/7: Verificación de Existencia"
    info "Verificando si el sitio ${nombre_dominio} ya existe..."
    if [ -d "/var/www/$nombre_dominio" ]; then
        error "El directorio de la web /var/www/$nombre_dominio ya existe. Abortando."
    fi
    if [ -f "/etc/nginx/sites-available/$nombre_dominio.conf" ]; then
        error "El archivo de configuración de Nginx /etc/nginx/sites-available/$nombre_dominio.conf ya existe. Abortando."
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
    <p>Este es el archivo de prueba. Puedes editarlo en /var/www/$nombre_dominio/pagina/index.html</p>
    <p>Configuración completada con éxito.</p>
</body>
</html>"

    echo "$nuevo_contenido_index" > "$archivo_index" || error "Fallo al escribir el archivo index.html."
    success "Estructura de directorios y archivo index.html creados."

    # 5. Configurar Nginx (HTTP y HTTPS)
    clear
    header "Paso 5/7: Configuración de Nginx (HTTP y HTTPS)"
    archivo_conf="/etc/nginx/sites-available/$nombre_dominio.conf"
    info "Generando archivo de configuración: $archivo_conf"

    # Generar certificado SSL auto-firmado
    info "Generando certificado SSL auto-firmado para pruebas..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "/etc/ssl/private/$nombre_dominio.key" \
        -out "/etc/ssl/certs/$nombre_dominio.crt" \
        -subj "/C=ES/ST=Local/L=Local/O=TestOrg/OU=TestUnit/CN=$nombre_dominio" > /dev/null 2>&1 || error "Fallo al generar el certificado SSL."
    success "Certificado SSL auto-firmado generado."

    # Crear configuración de Nginx
    cat << EOF > "$archivo_conf"
# Redirección de HTTP a HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $nombre_dominio www.$nombre_dominio;
    return 301 https://\$server_name\$request_uri;
}

# Configuración de HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $nombre_dominio www.$nombre_dominio;

    # Raíz del sitio
    root /var/www/$nombre_dominio/pagina;
    index index.html index.htm;

    # Logs
    access_log /var/log/nginx/${nombre_sitio}-access.log;
    error_log /var/log/nginx/${nombre_sitio}-error.log;

    # Certificados SSL
    ssl_certificate /etc/ssl/certs/$nombre_dominio.crt;
    ssl_certificate_key /etc/ssl/private/$nombre_dominio.key;

    # Configuración SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Configuración de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Ubicación raíz
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Denegar acceso a archivos ocultos
    location ~ /\. {
        deny all;
    }
}
EOF

    # Habilitar sitio
    info "Habilitando el sitio..."
    ln -sf "$archivo_conf" "/etc/nginx/sites-enabled/$nombre_dominio.conf" || error "Fallo al habilitar el sitio."

    # Verificar configuración
    info "Verificando configuración de Nginx..."
    nginx -t > /dev/null 2>&1 || error "Fallo en la configuración de Nginx. Revisa los logs."

    # Reiniciar Nginx
    info "Reiniciando Nginx..."
    systemctl restart nginx || error "Fallo al reiniciar Nginx."
    success "Configuración de Nginx (HTTP y HTTPS) completada."

    # 6. Configurar Usuario y Permisos
    clear
    header "Paso 6/7: Configuración de Usuario y Permisos SFTP"

    nombre_usuario="$nombre_sitio"

    if id "$nombre_usuario" &>/dev/null; then
        info "El usuario ${nombre_usuario} ya existe. Saltando la creación de usuario."
    else
        info "Creando usuario del sistema: ${nombre_usuario}"
        adduser "$nombre_usuario" || error "Fallo al crear el usuario ${nombre_usuario}."
    fi

    # Configurar permisos
    info "Estableciendo permisos y propiedad de directorios..."
    chown -R "$nombre_usuario":"$nombre_usuario" "/var/www/$nombre_dominio" || error "Fallo al cambiar la propiedad."
    chmod 755 "/var/www/$nombre_dominio" || error "Fallo al establecer permisos en el directorio raíz."
    chmod -R 755 "/var/www/$nombre_dominio/pagina" || error "Fallo al establecer permisos en el directorio de la página."

    # Configurar SFTP Chroot
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

    if grep -q "Match User $nombre_usuario" /etc/ssh/sshd_config; then
        info "La configuración SFTP para ${nombre_usuario} ya existe. Saltando la adición."
    else
        echo "$sftp_config" >> /etc/ssh/sshd_config || error "Fallo al escribir en sshd_config."
        info "Reiniciando el servicio SSH..."
        systemctl restart ssh.service || error "Fallo al reiniciar SSH."
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
    echo -e "1. ${BLANCO}Acceso al sitio:${NC} Añade a tu /etc/hosts: ${MAGENTA}IP_SERVIDOR\t$nombre_dominio${NC}"
    echo -e "2. ${BLANCO}Advertencia SSL:${NC} El certificado es auto-firmado. Acepta la advertencia del navegador."
    echo -e "3. ${BLANCO}Subir archivos:${NC} Usa SFTP con usuario ${nombre_usuario}"
    echo -e "4. ${BLANCO}Contraseña:${NC} Si no se te solicitó, usa 'passwd $nombre_usuario' para establecerla."
}

# --- Funciones para Eliminar Sitio ---

listar_sitios() {
    find /var/www/ -maxdepth 1 -mindepth 1 -type d ! -name "html" -exec basename {} \; 2>/dev/null
}

eliminar_sitio() {
    local nombre_dominio="$1"
    local nombre_sitio=$(echo "$nombre_dominio" | sed 's/\.[^.]*$//')
    local archivo_conf="/etc/nginx/sites-available/$nombre_dominio.conf"
    local directorio_web="/var/www/$nombre_dominio"
    local nombre_usuario="$nombre_sitio"

    header "PROCESO DE ELIMINACIÓN: $nombre_dominio"

    # 1. Deshabilitar y eliminar configuración de Nginx
    info "1/5. Deshabilitando sitio Nginx..."
    if [ -f "/etc/nginx/sites-enabled/$nombre_dominio.conf" ]; then
        rm "/etc/nginx/sites-enabled/$nombre_dominio.conf" || error "Fallo al deshabilitar el sitio."
        success "Sitio deshabilitado."
    else
        info "El sitio no estaba habilitado. Continuando..."
    fi

    info "2/5. Eliminando archivo de configuración de Nginx: $archivo_conf"
    if [ -f "$archivo_conf" ]; then
        rm "$archivo_conf" || error "Fallo al eliminar el archivo de configuración."
        success "Archivo de configuración eliminado."
    else
        info "Archivo de configuración no encontrado. Continuando..."
    fi

    info "Reiniciando Nginx..."
    systemctl restart nginx || error "Fallo al reiniciar Nginx."
    success "Nginx reiniciado."

    # 2. Eliminar directorio web
    info "3/5. Eliminando directorio web: $directorio_web"
    if [ -d "$directorio_web" ]; then
        rm -rf "$directorio_web" || error "Fallo al eliminar el directorio web."
        success "Directorio web eliminado."
    else
        info "Directorio web no encontrado. Continuando..."
    fi

    # 3. Eliminar usuario y configuración SFTP
    info "4/5. Eliminando usuario del sistema y configuración SFTP..."
    if id "$nombre_usuario" &>/dev/null; then
        info "Eliminando configuración SFTP para el usuario $nombre_usuario..."
        sed -i "/# --- Configuración SFTP para $nombre_dominio ---/,/# ------------------------------------------------/d" /etc/ssh/sshd_config
        
        userdel -r "$nombre_usuario" || error "Fallo al eliminar el usuario $nombre_usuario."
        
        info "Reiniciando SSH..."
        systemctl restart ssh.service || error "Fallo al reiniciar SSH."
        success "Usuario $nombre_usuario y configuración SFTP eliminados."
    else
        info "Usuario $nombre_usuario no encontrado. Saltando eliminación de usuario."
    fi

    # 4. Eliminar certificados SSL
    info "5/5. Eliminando certificados SSL..."
    rm -f "/etc/ssl/certs/$nombre_dominio.crt" "/etc/ssl/private/$nombre_dominio.key" 2>/dev/null
    success "Certificados SSL eliminados (si existían)."

    # 5. Mensaje final
    header "ELIMINACIÓN COMPLETADA"
    echo -e "${VERDE}El sitio web ${BLANCO}$nombre_dominio${VERDE} ha sido eliminado completamente.${NC}"
    echo -e "${VERDE}SUCCESSFULLY DOMAIN DELETION${NC}"
}

# --- Lógica Principal ---

clear
check_root

header "GESTOR DE HOSTING WEB CON NGINX"

echo -e "${BLANCO}¿Qué deseas hacer?${NC}"
echo -e "${CYAN}1.${NC} Crear un nuevo sitio web"
echo -e "${CYAN}2.${NC} Eliminar un sitio web existente"
echo -e "${CYAN}0.${NC} Salir"
echo ""

read -r opcion

case $opcion in
    1)
        crear_sitio
        ;;
    2)
        clear
        check_root
        header "ASISTENTE DE ELIMINACIÓN DE SITIOS WEB"

        SITIOS=($(listar_sitios))

        if [ ${#SITIOS[@]} -eq 0 ]; then
            echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} No se encontraron sitios web para eliminar."
            exit 0
        fi

        echo -e "${BLANCO}Sitios web disponibles para eliminar:${NC}"
        echo "-------------------------------------"
        for i in "${!SITIOS[@]}"; do
            echo -e "${CYAN}$((i+1)).${NC} ${SITIOS[$i]}"
        done
        echo "-------------------------------------"

        while true; do
            echo -e "\n${BLANCO}Introduce el número del sitio a eliminar (o 0 para cancelar):${NC}"
            read -r seleccion

            if [[ "$seleccion" =~ ^[0-9]+$ ]]; then
                if [ "$seleccion" -eq 0 ]; then
                    info "Operación cancelada por el usuario."
                    exit 0
                elif [ "$seleccion" -ge 1 ] && [ "$seleccion" -le ${#SITIOS[@]} ]; then
                    DOMINIO_A_ELIMINAR="${SITIOS[$((seleccion-1))]}"
                    
                    echo -e "\n${ROJO}¡ADVERTENCIA!${NC} Estás a punto de eliminar el sitio ${BLANCO}$DOMINIO_A_ELIMINAR${NC}."
                    echo -e "Esto eliminará ${ROJO}PERMANENTEMENTE${NC} todos los archivos, la configuración y el usuario SFTP."
                    echo -e "Confirma escribiendo el nombre del dominio: ${AMARILLO}$DOMINIO_A_ELIMINAR${NC}"
                    read -r confirmacion

                    if [ "$confirmacion" == "$DOMINIO_A_ELIMINAR" ]; then
                        eliminar_sitio "$DOMINIO_A_ELIMINAR"
                        exit 0
                    else
                        echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} Confirmación incorrecta. Volviendo a la selección."
                    fi
                else
                    echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} Selección no válida."
                fi
            else
                echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} Entrada no válida."
            fi
        done
        ;;
    0)
        info "Saliendo del programa."
        exit 0
        ;;
    *)
        error "Opción no válida."
        ;;
esac
