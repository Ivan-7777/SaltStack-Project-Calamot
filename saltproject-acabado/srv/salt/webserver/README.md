# Estado: Servidor Web (Base y Sistema)

Este estado establece la configuración fundamental de sistema para cualquier nodo que actúe como servidor web, asegurando identidad, conectividad y seguridad básica.

## ¿Qué hace este estado?

1.  **Identidad del Servidor**: Configura el nombre del host (`hostname`) de forma persistente y actualiza el archivo de hosts local.
2.  **Conectividad de Red**: Establece una configuración de red estática y define servidores DNS redundantes (Google y Cloudflare) para garantizar que el servidor siempre tenga acceso a internet y resolución de nombres.
3.  **Seguridad SSH**:
    *   Genera automáticamente claves de host SSH (RSA y Ed25519) si no existen.
    *   Configura un banner de advertencia legal que se muestra al intentar conectar por SSH.
4.  **Personalización**: Configura el "Mensaje del Día" (MOTD) que aparece al iniciar sesión, mostrando información útil sobre el servidor (nombre e IP).
5.  **Servicios Web (Content)**: A través de su módulo secundario, instala el servidor Apache2, PHP y prepara el directorio raíz para alojar páginas web, configurando un Host Virtual personalizado.

## Componentes principales
*   **Apache2**: El motor que sirve las páginas web.
*   **PHP**: El lenguaje necesario para ejecutar aplicaciones dinámicas como WordPress.
*   **Red Estática**: IP fija para asegurar que los servicios sean siempre localizables.
