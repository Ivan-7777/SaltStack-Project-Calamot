# Salt Master finalizado

Aqui se encuentra la entrega del Salt Master finalizado, incluyendo la maquina virtual exportada en formato OVA y/o el disco VDI asociado.

## Contenido esperado

- `*.ova`: maquina virtual completa del Salt Master, lista para importar en VirtualBox.
- `*.vdi`: disco virtual del Salt Master, util si se quiere montar manualmente en una VM nueva.
  
## Informacion del proyecto

Este Salt Master contiene la automatizacion de despliegue one-shot mediante SaltStack. El objetivo es que, tras generar el formulario y aplicar los estados, se instalen y configuren automaticamente los servicios seleccionados.

Servicios contemplados:

- Firewall restrictivo con nftables.
- DNS y DHCP.
- DHCP relay cuando corresponde.
- Webserver con WordPress.
- Proxy.
- WireGuard.
- Base de datos.
- Restic server y clientes de backup.
- Zabbix server y agentes.
- PKI/CA.

## Uso recomendado

1. Importar la OVA en VirtualBox, o crear una VM nueva usando el VDI.
2. Arrancar el Salt Master.
3. Comprobar conectividad con los minions:

```bash
salt '*' test.ping
```

4. Generar el formulario con los servicios deseados.
5. Aplicar el despliegue:

```bash
salt '*' state.apply
```

6. Validar los servicios con los scripts incluidos en:

```bash
/srv/salt/Scripts
```

Despues refrescar pillars y comprobar minions:

```bash
salt '*' saltutil.refresh_pillar
salt '*' test.ping
```

## Nota

Si el nuevo entorno usa otros rangos de red o cambia la IP del Salt Master, se debe regenerar el formulario o revisar los valores de red en los pillars generados para mantener coherencia entre LAN, D
