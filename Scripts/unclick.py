#!/usr/bin/env python3
import os
import subprocess
import json
import yaml
from pathlib import Path

SALT_ROOT = "/srv/salt"
PILLAR_ROOT = "/srv/pillar/customers"
SALT_TOP = Path("/srv/salt/top.sls")
PILLAR_TOP = Path("/srv/pillar/top.sls")

# Orden de prioridad para despliegue (puedes modificar)
STATE_ORDER = ["firewall", "wireguard", "vpn", "nginx", "dns"]


# --- Funciones Salt CLI ---
def run_cmd(cmd):
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Error al ejecutar {' '.join(cmd)}:\n{result.stderr}")
    return result.stdout


def get_minions_up():
    output = run_cmd(["salt-run", "manage.up", "--out=json"])
    data = json.loads(output)
    if isinstance(data, dict):
        return list(data.keys())
    elif isinstance(data, list):
        return data
    else:
        raise RuntimeError(f"Formato inesperado de salida de manage.up: {type(data)}")


# --- Funciones de pilares y estados ---
def list_clients(pillar_root=PILLAR_ROOT):
    clients = []
    for file in os.listdir(pillar_root):
        if file.endswith(".sls"):
            clients.append(os.path.splitext(file)[0])
    return sorted(clients)


def load_client_pillar(client_name):
    path = os.path.join(PILLAR_ROOT, client_name + ".sls")
    pillar_data = {}
    if os.path.exists(path):
        with open(path, "r") as f:
            pillar_data = yaml.safe_load(f)
    return pillar_data or {}


def list_states(salt_root=SALT_ROOT):
    states = []
    for root, dirs, files in os.walk(salt_root):
        for file in files:
            if file.endswith(".sls"):
                rel_path = os.path.relpath(root, salt_root)
                if rel_path == ".":
                    state_name = os.path.splitext(file)[0]
                else:
                    state_name = rel_path.replace(os.sep, ".")
                states.append(state_name)
    return sorted(set(states))


def filter_states_by_pillar(all_states, client_pillar):
    services = client_pillar.keys()
    filtered = [s for s in all_states if any(s.lower().startswith(service.lower()) for service in services)]
    return sorted(filtered)


def sort_states_by_order(selected_states):
    """Ordena los estados según prioridad definida en STATE_ORDER"""
    return sorted(selected_states, key=lambda s: STATE_ORDER.index(s) if s in STATE_ORDER else 999)


# --- Función para actualizar tops ---
def update_top(minions, client, states):
    # Top de Salt
    if SALT_TOP.exists():
        with open(SALT_TOP, "r") as f:
            salt_top = yaml.safe_load(f) or {}
    else:
        salt_top = {}
    salt_top.setdefault("base", {})
    for minion in minions:
        salt_top["base"][minion] = states
    with open(SALT_TOP, "w") as f:
        yaml.safe_dump(salt_top, f, default_flow_style=False)

    # Top de Pillars
    if PILLAR_TOP.exists():
        with open(PILLAR_TOP, "r") as f:
            pillar_top = yaml.safe_load(f) or {}
    else:
        pillar_top = {}
    pillar_top.setdefault("base", {})
    for minion in minions:
        pillar_top["base"][minion] = [f"customers.{client}"]
    with open(PILLAR_TOP, "w") as f:
        yaml.safe_dump(pillar_top, f, default_flow_style=False)


# --- Función principal ---
def main():
    print("=== Selecciona un cliente ===")
    clients = list_clients()
    if not clients:
        print("No se encontraron pillars de clientes en", PILLAR_ROOT)
        return
    for i, c in enumerate(clients, 1):
        print(f"{i}) {c}")
    client_idx = int(input("Cliente: ")) - 1
    selected_client = clients[client_idx]
    client_pillar = load_client_pillar(selected_client)
    print(f"Cliente seleccionado: {selected_client}\n")

    # Minions disponibles
    minions = get_minions_up()
    if not minions:
        print("No hay minions activos.")
        return

    print("Minions disponibles:")
    for i, m in enumerate(minions, 1):
        print(f"{i}) {m}")
    selected_input = input("Selecciona minions (coma separados, ej: 1,2): ")
    selected_indices = [int(i.strip()) - 1 for i in selected_input.split(",")]
    selected_minions = [minions[i] for i in selected_indices]

    # Estados filtrados según pillar
    all_states = list_states()
    available_states = filter_states_by_pillar(all_states, client_pillar)
    if not available_states:
        print("No se encontraron estados para aplicar según los servicios del pillar del cliente.")
        return

    print("\nEstados disponibles según servicios del pillar:")
    for i, s in enumerate(available_states, 1):
        print(f"{i}) {s}")

    selected_input = input("\nSelecciona estados (coma separados, ej: 1,3): ")
    selected_indices = [int(i.strip()) - 1 for i in selected_input.split(",")]
    selected_states = [available_states[i] for i in selected_indices]

    # Ordenar los estados
    ordered_states = sort_states_by_order(selected_states)
    print("\nOrden de ejecución sugerido de los estados:")
    for i, s in enumerate(ordered_states, 1):
        print(f"{i}) {s}")

    confirm = input("\n¿Deseas proceder con la actualización de los top.sls y despliegue? (s/n): ").lower()
    if confirm != "s":
        print("Despliegue cancelado.")
        return

    # Actualizar tops
    update_top(selected_minions, selected_client, ordered_states)
    print("\nTop.sls y pillar top.sls actualizados correctamente.")
    print("Ahora puedes ejecutar:\n  salt '*' state.apply\npara desplegar los estados a todos los minions seleccionados.")


if __name__ == "__main__":
    main()
