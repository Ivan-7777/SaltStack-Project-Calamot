Incluyo un formulario HTML para recopilar los datos. Con PHP, agarro estos datos y los transformo a pillars para que el servidor salt master los utilice para ejecutar estados customizados. 
Todos estos archivos se tienen que meter en /var/www/html/.
Instalar NGINX en salt master para incluir la página web con el formulario.

Teneis que crear directorio /srv/pillar/customers/
En ese directorio se irán pasando los pillars según el cliente haga el formulario.

Hay que descargar los paquetes apt install php php-fpm -y

Los archivos recibir.php y index.html los meteis en /var/www/html

el archivo default va en /etc/nginx/sites-available/

Haceis un restart del servicio una vez metido.

Accedeis via web al servidor salt y al poner los datos se os creará un sls con el nombre del archivo en /srv/pillar/customers/.

Para hacer que el minion use el pilar, dentro de /srv/pillar/ creais un archivo top.sls que tenga esta estructura:
base:
  'wg-minion':
    - customers.funcasta

siendo entre las comillas el nombre del minion, y abajo el nombre del directorio, seguido del nombre del sls.
