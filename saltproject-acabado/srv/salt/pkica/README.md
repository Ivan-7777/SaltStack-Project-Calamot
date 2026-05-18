# Estado: PKI CA (Autoridad de Certificación)

Este estado establece una infraestructura de clave pública (PKI) propia para gestionar certificados de seguridad SSL/TLS.

## ¿Qué hace este estado?

1.  **Preparación**: Instala OpenSSL y crea una jerarquía de directorios segura para almacenar claves privadas, certificados emitidos y listas de revocación.
2.  **Configuración de CA**: Genera un archivo `openssl.cnf` personalizado que define los parámetros de emisión de certificados para toda la organización.
3.  **Creación de la Raíz de Confianza**:
    *   Genera una clave privada maestra para la Autoridad de Certificación (CA).
    *   Crea el certificado raíz autofirmado que servirá para firmar los certificados de los demás servidores y servicios.
4.  **Seguridad Estricta**: Asegura que las claves privadas tengan permisos de lectura restringidos únicamente al usuario `root`.

## Utilidad
Permite emitir certificados de confianza para servidores web internos, conexiones VPN y otros servicios que requieran cifrado, sin depender de autoridades externas.
