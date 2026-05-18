# Estado: DNS (Sistema de Nombres de Dominio)

Este estado configura un servidor DNS interno utilizando Bind9 para resolver nombres de dominio dentro de la infraestructura.

## ¿Qué hace este estado?

1.  **Instalación**: Instala el servidor DNS Bind9.
2.  **Organización**: Crea la estructura de directorios necesaria para almacenar los archivos de zona de forma ordenada.
3.  **Configuración de Servidor**:
    *   Configura las opciones globales (como reenviadores y seguridad) a través de `named.conf.options`.
    *   Declara las zonas locales (dominios que el servidor gestiona) en `named.conf.local`.
4.  **Zonas de Dominio**: Despliega automáticamente los archivos de zona (como `db.internal` y `db.web-server`) que contienen los registros de los nombres de host y sus respectivas direcciones IP.
5.  **Mantenimiento**: El servicio se reinicia automáticamente si se detectan cambios en cualquier archivo de configuración o de zona, garantizando que la resolución de nombres esté siempre actualizada.

## Uso
Permite que las máquinas de la red se comuniquen entre sí usando nombres (ej. `servidor.local`) en lugar de direcciones IP difíciles de recordar.
