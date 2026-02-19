Incluyo un formulario HTML para recopilar los datos. Con PHP, agarro estos datos y los transformo a pillars para que el servidor salt master los utilice para ejecutar estados customizados. 
Todos estos archivos se tienen que meter en /var/www/html/.
Instalar NGINX en salt master para incluir la página web con el formulario.

Teneis que crear directorio /srv/pillar/customers/
En ese directorio se irán pasando los pillars según el cliente haga el formulario.

Hay que descargar los paquetes apt install php php-fpm -y
