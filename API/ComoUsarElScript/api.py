import requests
import urllib3
import json

# Deshabilitar advertencias de certificados auto-firmados (el flag -k de curl)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class SaltSecurityBot:
    def __init__(self, host, user, password):
        self.base_url = f"https://{host}:8000"
        self.user = user
        self.password = password
        self.token = None

    def login(self):
        """Autenticación eAuth para obtener el Token"""
        print(f"[*] Intentando login en {self.base_url}...")
        data = {
            'username': self.user,
            'password': self.password,
            'eauth': 'pam'
        }
        try:
            r = requests.post(f"{self.base_url}/login", data=data, verify=False)
            if r.status_code == 200:
                self.token = r.json()['return'][0]['token']
                print(f"[+] Token obtenido con éxito: {self.token[:10]}...")
                return True
            print(f"[-] Error de autenticación: {r.status_code}")
            return False
        except Exception as e:
            print(f"[!] Error de conexión: {e}")
            return False

    def ejecutar(self, target, funcion, argumentos=None):
        """Ejecutor genérico de comandos Salt"""
        if not self.token:
            return "No autenticado"

        headers = {'X-Auth-Token': self.token, 'Accept': 'application/json'}
        payload = {
            'client': 'local',
            'tgt': target,
            'fun': funcion
        }
        if argumentos:
            payload['arg'] = argumentos

        r = requests.post(self.base_url, headers=headers, data=payload, verify=False)
        return r.json()

# --- BLOQUE PRINCIPAL DE EJECUCIÓN ---
if __name__ == "__main__":
    # Configuración de acceso
    MASTER_IP = "localhost" 
    USUARIO = "root"
    CLAVE = "Asdqwe123"
    MINION = "PruebaAPI"

    bot = SaltSecurityBot(MASTER_IP, USUARIO, CLAVE)

    if bot.login():
        # 1. Verificación de conectividad
        print(f"\n[1] Verificando conexión con {MINION}...")
        ping = bot.ejecutar(MINION, 'test.ping')
        print(f"Resultado: {ping}")

        # 2. Aplicar Hardening (Tu archivo de seguridad.sls)
        # Descomenta las líneas de abajo cuando quieras ejecutar tu política de seguridad
        """
        print(f"\n[2] Aplicando política de HARDENING en {MINION}...")
        hardening = bot.ejecutar(MINION, 'state.apply', ['seguridad'])
        print(json.dumps(hardening, indent=2))
        """
