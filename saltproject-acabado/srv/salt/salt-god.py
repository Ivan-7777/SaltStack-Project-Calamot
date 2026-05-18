import subprocess

# Definir un diccionario que mapea números de estado a nombres de estado
estados = {
    1: "",
    2: "nombre_estado_2",
    3: "nombre_estado_3",
    # Agrega más estados según sea necesario
}

def ejecutar_estado(nombre_minion, numero_estado):
    nombre_estado = estados.get(numero_estado)
    if nombre_estado:
        comando = f"salt {nombre_minion} state.apply {nombre_estado}"
        resultado = subprocess.run(comando, shell=True, capture_output=True, text=True)
        if resultado.returncode == 0:
            print("Estado aplicado correctamente.")
            print(resultado.stdout)
        else:
            print("Hubo un error al aplicar el estado.")
            print(resultado.stderr)
    else:
        print("Número de estado inválido.")

def main():
    while True:
        nombre_minion = input("Ingrese el nombre del minion:")
        print("Estados disponibles:")
        for num, nombre in estados.items():
            print(f"{num}: {nombre}")
        numero_estado = int(input("Ingrese el número del estado que desea aplicar:"))
        ejecutar_estado(nombre_minion, numero_estado)
        opcion = input("¿Desea aplicar otro estado a otro minion? (s/n):")
        if opcion.lower() != 's':
            break

if __name__ == "__main__":
    main()
