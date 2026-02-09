# State: Wireguard VPN

Configuración de túneles VPN punto a punto utilizando el protocolo Wireguard.

## Funcionalidades
* Instalación del módulo del kernel y herramientas de Wireguard.
* Generación automática de llaves públicas y privadas por minion.
* Configuración de interfaces de red virtuales (ej. `wg0`).



## Notas
El estado intercambia automáticamente las llaves públicas entre el Master y los Minions a través de **Salt Mine** para facilitar la conexión entre pares.
