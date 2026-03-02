# Salt Top Orchestrator

Este proyecto proporciona un script interactivo en CLI para orquestar despliegues de infraestructura con Salt Stack de forma declarativa, generando automáticamente los archivos `top.sls` tanto para estados como para pillars.

El objetivo es simplificar, estandarizar y asegurar los despliegues en entornos multiempresa, evitando ejecuciones manuales estado a estado y reduciendo errores humanos.

## 🧩 ¿Qué problema resuelve?

En despliegues reales:

*   Cada cliente tiene servicios distintos
*   Los estados tienen dependencias
*   Ejecutar estados manualmente no escala
*   Mantener coherencia entre minions, pillars y estados es complejo

Este script centraliza ese flujo y convierte la selección humana en configuración declarativa reproducible.

## 📁 Estructura esperada del proyecto

El script asume la siguiente estructura en el Salt Master:

```
/srv/salt/
├── firewall/
│   └── init.sls
├── wireguard/
│   └── init.sls
├── nginx/
│   └── init.sls
├── dns/
│   └── init.sls
└── top.sls            # generado automáticamente

/srv/pillar/
├── top.sls            # generado automáticamente
└── customers/
    ├── cliente1.sls
    ├── cliente2.sls
    └── cliente3.sls
```

## 📄 Estructura de los pillars de cliente

Cada cliente tiene un pillar propio en `/srv/pillar/customers/`.

Las claves de primer nivel representan los servicios que ese cliente utiliza. El script se basa en estas claves para decidir qué estados pueden desplegarse.

Ejemplo:

```yaml
wireguard:
  port: 51820
  address: 192.168.0.1
  static_lan_ip: 192.168.0.10
  wan_interface: enp0s3

firewall:
  wan:
    ip: 10.1.105.200
    mask: 24
    gateway: 10.1.105.1
  lan:
    ip: 192.168.0.1
    mask: 24
```

👉 Si un servicio no existe en el pillar, su estado no se mostrará.

## ⚙️ Funcionamiento del script

### Flujo completo

1.  **Detecta los clientes disponibles**
    *   Escanea `/srv/pillar/customers/*.sls`
    *   Carga el pillar del cliente seleccionado
    *   Obtiene los servicios definidos
2.  **Detecta minions activos**
    *   Usa `salt-run manage.up --out=json`
    *   Permite seleccionar uno o varios minions
3.  **Detecta todos los estados disponibles**
    *   Recorre `/srv/salt` recursivamente
    *   Filtra estados según el pillar
    *   Solo estados cuyo nombre coincide con servicios del cliente
4.  **Permite seleccionar estados**
5.  **Calcula un orden de ejecución recomendado**
6.  **Muestra el plan antes de aplicar cambios**
    *   Solicita confirmación explícita
7.  **Genera automáticamente**
    *   `/srv/salt/top.sls`
    *   `/srv/pillar/top.sls`

## 🔁 Orden de ejecución de estados

El orden se define en el script mediante:

`STATE_ORDER = [
```python
STATE_ORDER = ["firewall", "wireguard", "vpn", "nginx", "dns"]
```

Reglas:

*   Los estados incluidos se ejecutan primero y en ese orden
*   Los estados no listados se colocan al final
*   Ayuda a respetar dependencias lógicas (ej. firewall antes de VPN)

⚠️ Este orden es sugerido, no sustituye a `require` o `watch` dentro de los estados.

## 🧪 Ejemplo de uso

Ejecutar desde el Salt Master:

```bash
python3 salt-top-orchestrator.py
```

Ejemplo de interacción:

```
=== Selecciona un cliente ===
1) cliente1
2) cliente2
Cliente: 1

Minions disponibles:
1) fw-empresa1
2) vpn-empresa1
Selecciona minions (coma separados): 1,2

Estados disponibles según servicios del pillar:
1) firewall
2) wireguard

Orden de ejecución sugerido:
1) firewall
2) wireguard

¿Deseas proceder con la actualización de los top.sls y despliegue? (s/n): s
```

Aplicación final:

```bash
salt '*' state.apply
```

## ✅ Ventajas del enfoque

*   Uso 100% declarativo
*   Evita ejecuciones manuales repetitivas
*   Reduce errores humanos
*   Escalable para múltiples clientes
*   Ideal para despliegues reproducibles
*   Preparado para integración con UI web o CI/CD

## 📌 Requisitos

*   Salt Master operativo
*   Python 3
*   Acceso a `salt-run`
*   Permisos de escritura en:
    *   `/srv/salt/top.sls`
    *   `/srv/pillar/top.sls`
`
