# Estado: pkica

## Descripción
Este estado configura una Autoridad Certificadora (CA) local utilizando OpenSSL y una estructura PKI gestionada mediante SaltStack.

Permite generar certificados de forma controlada y centralizada.

## ¿Qué hace este estado?
- Instala OpenSSL
- Crea la estructura PKI en /etc/pki/ca
- Genera la clave privada de la CA
- Genera el certificado raíz
- Gestiona el archivo de configuración de OpenSSL

## ¿Cuándo se aplica?
Este estado se aplica en máquinas destinadas exclusivamente a actuar como CA.

## Sistemas afectados
- Servidores CA.

## Notas
Los archivos privados se protegen mediante permisos restrictivos para evitar accesos no autorizados.
