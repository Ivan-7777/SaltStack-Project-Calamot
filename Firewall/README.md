# Firewall

## Descripción

Este componente del proyecto se encarga de la **seguridad perimetral de la infraestructura**, actuando como primera línea de defensa frente a accesos no autorizados.

El firewall controla y filtra el tráfico de red entrante, saliente y reenviado, permitiendo únicamente las comunicaciones necesarias para el correcto funcionamiento del sistema.

---

## Objetivos

- Reducir la superficie de ataque del sistema.
- Controlar el tráfico entre interfaces y redes.
- Permitir únicamente los servicios estrictamente necesarios.
- Centralizar y automatizar la configuración mediante SaltStack.

---

## Enfoque de seguridad

El firewall está diseñado siguiendo un enfoque restrictivo:
- Todo el tráfico se bloquea por defecto.
- Solo se permiten reglas explícitas.
- Se controla el forwarding de paquetes.
- Se evita la exposición innecesaria de servicios.

La configuración se gestiona de forma automatizada para asegurar coherencia y evitar errores manuales.

