# Paquete portable SaltStack

Este paquete contiene una copia preparada para mover el proyecto a otro Salt master.

## Contenido

- `srv/salt/`: estados Salt que deben copiarse a `/srv/salt`.
- `srv/pillar/`: pillar base y customers que deben copiarse a `/srv/pillar`.
- `var/www/html/`: formulario web del Salt master.
- `extras/`: copias auxiliares del repositorio local usadas durante el desarrollo.
- `restore_on_new_master.sh`: script para restaurar el paquete en un nuevo Salt master.

## Restauracion rapida

En el nuevo Salt master:

```bash
bash restore_on_new_master.sh
salt '*' saltutil.refresh_pillar
salt '*' test.ping
```

Despues genera de nuevo el formulario si quieres crear un nuevo customer/main.sls.

## Nota importante

Si el nuevo master tiene otra IP, revisa o regenera el formulario para que los valores de
`salt_master_ip`, gateways y rangos LAN/DMZ/WAN sean coherentes con la nueva red.
