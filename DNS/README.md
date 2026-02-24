## Estado: DNS

Este estado instala y configura el servicio DNS en una máquina correspondiente.

### Contenido

- **Servicio DNS Global:**  
  Proporciona resolución de nombres en la red, permitiendo traducir nombres de dominio a direcciones IP.
  
- **Reglas:**  
  - Especifica qué servidores DNS externos se utilizarán como *forwarders*.  
  - Asigna nombres de dominio a servidores con IP fija (DNS, LDAP, Web, Gateway, etc.).

### Variables

La configuración puede variar según el tipo de red (dominio, máscara, subred, IP fijas disponibles).  
También puede variar según si el servidor actúa como DNS principal o secundario, y si se requiere reenvío hacia DNS externos.
