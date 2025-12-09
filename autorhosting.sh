#!/bin/bash

# ==============================================================================
# SCRIPT DE ELIMINACIÓN AUTOMÁTICA DE SITIO WEB
# Versión: 1.0
# Descripción: Permite al usuario seleccionar y eliminar un sitio web previamente
#              creado, incluyendo su configuración de Apache, usuario SFTP y
#              archivos.
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

# --- Funciones Principales ---

# Función para listar los sitios web disponibles
listar_sitios() {
    # Busca directorios en /var/www/ que no sean el html por defecto
    find /var/www/ -maxdepth 1 -mindepth 1 -type d ! -name "html" -exec basename {} \; 2>/dev/null
}

# Función para eliminar un sitio web
eliminar_sitio() {
    local nombre_dominio="$1"
    local nombre_sitio=$(echo "$nombre_dominio" | sed 's/\.[^.]*$//') # Nombre corto para usuario/logs
    local archivo_conf="/etc/apache2/sites-available/$nombre_dominio.conf"
    local directorio_web="/var/www/$nombre_dominio"
    local nombre_usuario="$nombre_sitio"

    header "PROCESO DE ELIMINACIÓN: $nombre_dominio"

    # 1. Deshabilitar y eliminar configuración de Apache
    info "1/5. Deshabilitando sitio Apache..."
    if a2dissite "$nombre_dominio.conf" > /dev/null 2>&1; then
        success "Sitio deshabilitado."
    else
        info "El sitio no estaba habilitado o no existe. Continuando..."
    fi

    info "2/5. Eliminando archivo de configuración de Apache: $archivo_conf"
    if [ -f "$archivo_conf" ]; then
        rm "$archivo_conf" || error "Fallo al eliminar el archivo de configuración de Apache."
        success "Archivo de configuración eliminado."
    else
        info "Archivo de configuración no encontrado. Continuando..."
    fi

    info "Reiniciando Apache2..."
    systemctl restart apache2 || error "Fallo al reiniciar Apache2."
    success "Apache2 reiniciado."

    # 2. Eliminar directorio web
    info "3/5. Eliminando directorio web: $directorio_web"
    if [ -d "$directorio_web" ]; then
        rm -rf "$directorio_web" || error "Fallo al eliminar el directorio web."
        success "Directorio web eliminado."
    else
        info "Directorio web no encontrado. Continuando..."
    fi

    # 3. Eliminar usuario del sistema y configuración SFTP
    info "4/5. Eliminando usuario del sistema y configuración SFTP..."
    if id "$nombre_usuario" &>/dev/null; then
        # Eliminar configuración SFTP de sshd_config
        info "Eliminando configuración SFTP para el usuario $nombre_usuario de sshd_config..."
        # Usamos sed para eliminar el bloque de configuración
        sed -i "/# --- Configuración SFTP para $nombre_dominio ---/,/# ------------------------------------------------/d" /etc/ssh/sshd_config
        
        # Eliminar usuario y su directorio home en /home/ (si existe)
        userdel -r "$nombre_usuario" || error "Fallo al eliminar el usuario $nombre_usuario y su directorio home."
        
        info "Reiniciando SSH..."
        systemctl restart ssh.service || error "Fallo al reiniciar SSH."
        success "Usuario $nombre_usuario y configuración SFTP eliminados."
    else
        info "Usuario $nombre_usuario no encontrado. Saltando eliminación de usuario."
    fi

    # 4. Eliminar certificados SSL
    info "4/5. Eliminando certificados SSL..."
    rm -f "/etc/ssl/certs/$nombre_dominio.crt" "/etc/ssl/private/$nombre_dominio.key" 2>/dev/null
    success "Certificados SSL eliminados (si existían)."

    # 5. Mensaje final
    header "ELIMINACIÓN COMPLETADA"
    echo -e "${VERDE}El sitio web ${BLANCO}$nombre_dominio${VERDE} ha sido eliminado completamente.${NC}"
    echo -e "${VERDE}SUCCESSFULLY DOMAIN DELETION${NC}"
}

# --- Lógica Principal del Script ---

clear
check_root

header "ASISTENTE DE ELIMINACIÓN DE SITIOS WEB"

SITIOS=($(listar_sitios))

if [ ${#SITIOS[@]} -eq 0 ]; then
    echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} No se encontraron sitios web para eliminar en /var/www/ (excluyendo 'html')."
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
            echo -e "Esto eliminará ${ROJO}PERMANENTEMENTE${NC} todos los archivos, la configuración de Apache y el usuario SFTP asociado."
            echo -e "Confirma escribiendo el nombre del dominio: ${AMARILLO}$DOMINIO_A_ELIMINAR${NC}"
            read -r confirmacion

            if [ "$confirmacion" == "$DOMINIO_A_ELIMINAR" ]; then
                eliminar_sitio "$DOMINIO_A_ELIMINAR"
                exit 0
            else
                echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} Confirmación incorrecta. Volviendo a la selección."
            fi
        else
            echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} Selección no válida. Introduce un número de la lista."
        fi
    else
        echo -e "${AMARILLO}⚠️ ADVERTENCIA:${NC} Entrada no válida. Introduce un número."
    fi
done
