# Estado: DNS

## Descripción

Este estado se encarga de **instalar y configurar el servicio DNS** en la máquina correspondiente dentro de la infraestructura del proyecto.  
Su objetivo es **resolver nombres de dominio internos y externos**, asegurando que todos los minions y servidores puedan comunicarse correctamente mediante nombres en lugar de direcciones IP.

---

## Contenido

### Servidor DNS principal
Configura un servidor DNS que:

- Resuelve nombres de host internos de la red.
- Reenvía consultas externas a servidores DNS públicos si es necesario.
- Permite que los minions y máquinas virtuales se conecten usando nombres amigables.

### Reglas y zonas
Se definen zonas y reglas específicas para:

- Asociar nombres de host con direcciones IP fijas.
- Configurar reenvíos (forwarders) a servidores DNS externos.
- Priorizar resolución interna sobre externa según la topología de red.

---

## Variables

La configuración del estado DNS puede variar según el tipo de red y la infraestructura:

- Direcciones IP de los servidores DNS internos y externos.
- Dominios y subdominios gestionados internamente.
- Direcciones IP fijas asignadas a máquinas críticas.
- Opciones de reenvío y caché de consultas.

---

## Objetivo

El objetivo de este estado es **garantizar la resolución de nombres de manera confiable** dentro de la red del proyecto, permitiendo:

- Comunicación estable entre todos los minions y servidores.
- Mantenimiento de registros internos de DNS.
- Facilidad para futuras ampliaciones de la infraestructura.
