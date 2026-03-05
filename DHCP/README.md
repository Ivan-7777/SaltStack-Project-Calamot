# Estado: DHCP

## Descripción

Este estado se encarga de **instalar y configurar el servicio DHCP** en una máquina designada dentro de la infraestructura.  
El objetivo es **gestionar automáticamente la asignación de direcciones IP dentro de la red**, permitiendo que los dispositivos obtengan su configuración de red de forma dinámica.

La configuración se gestiona mediante **SaltStack**, lo que permite desplegar y mantener el servicio de forma automatizada en las máquinas virtuales del entorno.

---

## Contenido

### Servicio DHCP Global
Este componente configura el **servidor DHCP principal**, encargado de:

- Asignar direcciones IP dentro de un **rango específico de la red**.
- Definir parámetros básicos de red como:
  - puerta de enlace
  - máscara de red
  - servidores DNS

Este servicio permite que las máquinas cliente obtengan automáticamente su configuración de red al conectarse.

### Reglas
Se definen reglas específicas dentro del servidor DHCP para adaptar el comportamiento de la red, como por ejemplo:

- Especificar **qué servidores DNS utilizarán los clientes**.
- Asignar **direcciones IP fijas a determinadas máquinas** (por ejemplo servidores).
- Reservar direcciones en función de la **dirección MAC** del dispositivo.

Esto permite mantener una red organizada donde los servidores mantienen direcciones constantes mientras que el resto de dispositivos reciben IP dinámicas.

---

## Variables

La configuración del estado DHCP puede variar dependiendo del **entorno de red** en el que se despliegue.  
Algunos de los parámetros que pueden modificarse son:

- Rango de direcciones IP asignadas por DHCP
- Máscara de red
- Dirección de la puerta de enlace
- Servidores DNS utilizados
- Direcciones IP reservadas para servidores
- Configuración específica de la subred

Estas variables permiten adaptar el estado a diferentes topologías de red sin necesidad de modificar directamente la lógica del estado.

---

## Objetivo

El objetivo de este estado es **centralizar la gestión de direcciones IP dentro de la infraestructura**, facilitando:

- Automatización de la configuración de red
- Control sobre las direcciones asignadas
- Separación entre IP dinámicas y direcciones reservadas para servidores

Esto permite mantener una red **organizada, predecible y fácilmente administrable** dentro del entorno virtualizado del proyecto.
