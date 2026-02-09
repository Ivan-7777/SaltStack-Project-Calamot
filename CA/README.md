# Estado: pkica

### State: CA (Certificate Authority)

Estado diseñado para automatizar la generación y distribución de certificados SSL/TLS dentro de la red interna.

## Funcionalidades
* Configuración de una CA interna (ej. mediante OpenSSL o Smallstep).
* Renovación automática de certificados.
* Distribución del certificado raíz a los minions para establecer confianza.



## Uso
Para solicitar un certificado, el minion debe estar etiquetado en el pillar correspondiente.
