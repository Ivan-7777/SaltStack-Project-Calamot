# 🌐 Servicio Web (NGINX)

## 📌 Descripción

Este servicio proporciona un servidor web accesible mediante HTTP/HTTPS, preparado para alojar páginas web de forma segura.

Incluye:

- Servidor web **NGINX**
- Acceso seguro mediante **HTTPS (SSL)**
- Acceso remoto por **SSH**
- Configuración automática de red
- Script de autogestión del servicio

---

## 🚀 Acceso al servicio

Una vez desplegado, puedes acceder al servidor web mediante:

- **HTTP:**  
  `http://<IP_DEL_SERVIDOR>`

- **HTTPS:**  
  `https://<DOMINIO_CONFIGURADO>`

> ⚠️ Si es la primera vez, el certificado SSL es autofirmado, por lo que el navegador mostrará una advertencia.

---

## 📁 Ubicación de la web

La página web se encuentra en:


<RUTA_WEBROOT>


Ejemplo típico:

/var/www/html


El archivo principal es:


index.html


---

## 🧑‍💻 Cómo publicar tu web

1. Accede al servidor por SSH:

```bash
ssh usuario@<IP_DEL_SERVIDOR>
Accede al directorio web:
cd <RUTA_WEBROOT>
Sustituye el contenido de index.html o añade tus propios archivos.
🔐 Seguridad

El servicio incluye:

Certificado SSL (HTTPS)
Parámetros seguros de cifrado (DHParams)
Acceso por SSH configurable

Recomendaciones:

Cambiar credenciales SSH por defecto
Usar claves SSH en lugar de contraseña
Sustituir el certificado autofirmado por uno válido (ej: Let's Encrypt)
⚙️ Configuración relevante

Los siguientes parámetros pueden ser personalizados:

Dominio del servidor
Ruta del webroot
Certificados SSL:
Clave privada
Certificado público
🔄 Gestión del servicio
Reiniciar NGINX
systemctl restart nginx
Ver estado
systemctl status nginx
🛠️ Troubleshooting
❌ No carga la web
Verifica que el servicio está activo:
systemctl status nginx
Comprueba que los puertos 80 y 443 están accesibles
❌ Error de certificado
Es normal si es autofirmado
Solución:
Aceptar la advertencia del navegador
O instalar un certificado válido
❌ No puedes acceder por SSH
Verifica que el servicio está activo:
systemctl status ssh
📜 Script de autogestión

Existe un script disponible en:

/root/Scripts/autohosting.sh

Este script permite automatizar tareas relacionadas con el servicio web.

📡 Configuración de red

El servidor aplica configuración de red automáticamente.

⚠️ Tras cambios en red, el sistema puede reiniciarse automáticamente.

📞 Soporte

Si el servicio no funciona correctamente:

Verifica conectividad (ping al servidor)
Comprueba estado de servicios (nginx, ssh)
Revisa la configuración aplicada
