# Documentación de Salt REST API

## Configuración del entorno

- **URL de la API:** `http://10.1.105.56:8000`
- **Usuario:** `root`
- **Contraseña:** `Asdqwe123`
- **Método de autenticación:** PAM
- **Minion disponible:** `QWEN1`

---

## 1. Autenticación (Login)

### Obtener token

```bash
curl -s http://10.1.105.56:8000/login \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam
```

### Respuesta esperada

```json
{
  "return": [{
    "token": "34a6b7db0b1cb6b0a7549f266a9add106d42ee2d",
    "expire": 1773371860,
    "start": 1773328660,
    "user": "root",
    "eauth": "pam",
    "perms": [".*", "@events", "@jobs", "@runner", "@wheel"]
  }]
}
```

> **Nota:** El token dura 12 horas por defecto. Guárdalo para usarlo en otras peticiones.

---

## 2. Ping a minions

### Opción A: Con credenciales directas (más simple)

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=test.ping
```

### Opción B: Con token (para scripts)

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -H "X-Auth-Token: 34a6b7db0b1cb6b0a7549f266a9add106d42ee2d" \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=test.ping
```

### Parámetros

| Parámetro | Descripción |
|-----------|-------------|
| `client` | Tipo de cliente: `local`, `runner`, `wheel`, `local_async` |
| `tgt` | Minion objetivo: `QWEN1`, `'*'`, `'web*'` |
| `fun` | Función a ejecutar: `test.ping`, `cmd.run`, `pkg.install` |

### Respuesta esperada

```json
{"return": [{"QWEN1": true}]}
```

---

## 3. Ejecutar comandos shell

### Comando básico

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=cmd.run \
  -d arg='whoami'
```

### Con múltiples argumentos

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=cmd.run \
  -d arg='echo "Hola"' \
  -d kwarg='{"cwd": "/tmp"}'
```

### Ejemplos útiles

```bash
# Ver información del sistema
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root -d password=Asdqwe123 -d eauth=pam \
  -d client=local -d tgt='QWEN1' \
  -d fun=cmd.run -d arg='uname -a'

# Ver espacio en disco
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root -d password=Asdqwe123 -d eauth=pam \
  -d client=local -d tgt='QWEN1' \
  -d fun=cmd.run -d arg='df -h'

# Reiniciar servicio
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root -d password=Asdqwe123 -d eauth=pam \
  -d client=local -d tgt='QWEN1' \
  -d fun=cmd.run -d arg='systemctl restart nginx'
```

---

## 4. Obtener Pillar data

### Opción A: pillar.items (todos los datos)

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=pillar.items
```

### Opción B: pillar.get (una clave específica)

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=pillar.get \
  -d arg='pkica:webserver:port'
```

### Ejemplo de respuesta (pillar.items)

```json
{
  "return": [{
    "QWEN1": {
      "pkica": {
        "base_dir": "/etc/pki/ca",
        "ca": {
          "country": "ES",
          "state": "Madrid",
          "locality": "Madrid",
          "organization": "MiOrg",
          "organizational_unit": "IT",
          "common_name": "mi-ca",
          "days_valid": 3650,
          "key_size": 4096,
          "digest": "sha256"
        },
        "webserver": {
          "port": 80,
          "ssl_port": 443,
          "ssl": {
            "enabled": true
          }
        }
      }
    }
  }]
}
```

---

## 5. Ejecutar estados (state.apply)

### Aplicar todos los estados del top.sls

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=state.apply
```

### Aplicar un estado específico

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=state.apply \
  -d arg='webserver'
```

### Aplicar con test=True (dry-run / simulación)

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root \
  -d password=Asdqwe123 \
  -d eauth=pam \
  -d client=local \
  -d tgt='QWEN1' \
  -d fun=state.apply \
  -d arg='webserver' \
  -d kwarg='{"test": true}'
```

### Ejemplo de respuesta

```json
{
  "return": [{
    "QWEN1": {
      "pkg_|-instalar_servicios_|-instalar_servicios_|-installed": {
        "name": "instalar_servicios",
        "changes": {
          "nginx": {"old": "", "new": "1.22.1-9+deb12u4"}
        },
        "result": true,
        "comment": "The following packages were installed/updated: nginx",
        "__sls__": "webserver",
        "__run_num__": 0
      },
      "service_|-nginx_|-nginx_|-running": {
        "name": "nginx",
        "changes": {},
        "result": true,
        "comment": "The service nginx is already running",
        "__sls__": "webserver",
        "__run_num__": 1
      }
    }
  }]
}
```

---

## 6. Otros endpoints útiles

### Obtener información detallada de minions (grains)

```bash
curl -s http://10.1.105.56:8000/minions/QWEN1 \
  -H "Accept: application/json" \
  -H "X-Auth-Token: TU_TOKEN"
```

### Ver lista de jobs ejecutados

```bash
curl -s http://10.1.105.56:8000/jobs \
  -H "Accept: application/json" \
  -H "X-Auth-Token: TU_TOKEN"
```

### Ver detalles de un job específico

```bash
curl -s http://10.1.105.56:8000/jobs/20260312161951589671 \
  -H "Accept: application/json" \
  -H "X-Auth-Token: TU_TOKEN"
```

### Escuchar eventos en tiempo real (Event Stream)

```bash
curl -s http://10.1.105.56:8000/events \
  -H "Accept: application/json" \
  -H "X-Auth-Token: TU_TOKEN"
```

### Ver keys de minions (salt-key)

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root -d password=Asdqwe123 -d eauth=pam \
  -d client=wheel -d fun=key.list_all
```

### Aceptar key de un minion

```bash
curl -s http://10.1.105.56:8000/run \
  -H "Accept: application/json" \
  -d username=root -d password=Asdqwe123 -d eauth=pam \
  -d client=wheel -d fun=key.accept -d match='QWEN1'
```

---

## 7. Ejemplos desde Python

### Script básico con requests

```python
import requests
import json

BASE_URL = "http://10.1.105.56:8000"

# Login
resp = requests.post(f"{BASE_URL}/login", json={
    "username": "root",
    "password": "Asdqwe123",
    "eauth": "pam"
})
token = resp.json()["return"][0]["token"]
print(f"Token: {token}")

# Headers para siguientes peticiones
headers = {"X-Auth-Token": token, "Accept": "application/json"}

# Ping
resp = requests.post(f"{BASE_URL}/run", json={
    "client": "local",
    "tgt": "QWEN1",
    "fun": "test.ping"
}, headers=headers)
print(f"Ping: {resp.json()}")

# Ejecutar comando
resp = requests.post(f"{BASE_URL}/run", json={
    "client": "local",
    "tgt": "QWEN1",
    "fun": "cmd.run",
    "arg": "whoami"
}, headers=headers)
print(f"Whoami: {resp.json()}")

# Ejecutar estado
resp = requests.post(f"{BASE_URL}/run", json={
    "client": "local",
    "tgt": "QWEN1",
    "fun": "state.apply",
    "arg": ["webserver"]
}, headers=headers)
print(f"State apply: {json.dumps(resp.json(), indent=2)}")
```

### Clase reutilizable para Salt API

```python
import requests

class SaltAPI:
    def __init__(self, base_url, username, password, eauth='pam'):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.eauth = eauth
        self.token = None
        self.headers = None
        self.login()
    
    def login(self):
        resp = requests.post(f"{self.base_url}/login", json={
            "username": self.username,
            "password": self.password,
            "eauth": self.eauth
        })
        data = resp.json()
        self.token = data["return"][0]["token"]
        self.headers = {
            "X-Auth-Token": self.token,
            "Accept": "application/json"
        }
    
    def run(self, tgt, fun, arg=None, kwarg=None, client='local'):
        payload = {
            "client": client,
            "tgt": tgt,
            "fun": fun
        }
        if arg:
            payload["arg"] = arg if isinstance(arg, list) else [arg]
        if kwarg:
            payload["kwarg"] = kwarg
        resp = requests.post(f"{self.base_url}/run", json=payload, headers=self.headers)
        return resp.json()
    
    def ping(self, tgt):
        return self.run(tgt, 'test.ping')
    
    def cmd(self, tgt, command):
        return self.run(tgt, 'cmd.run', arg=command)
    
    def state_apply(self, tgt, state=None):
        arg = [state] if state else []
        return self.run(tgt, 'state.apply', arg=arg)
    
    def pillar_items(self, tgt):
        return self.run(tgt, 'pillar.items')
    
    def minions(self):
        resp = requests.get(f"{self.base_url}/minions", headers=self.headers)
        return resp.json()

# Uso
api = SaltAPI("http://10.1.105.56:8000", "root", "Asdqwe123")
print(api.ping("QWEN1"))
print(api.cmd("QWEN1", "uptime"))
print(api.state_apply("QWEN1", "webserver"))
```

---

## 8. Ejemplos desde PowerShell

### Login y ejecutar comando

```powershell
$BASE_URL = "http://10.1.105.56:8000"

# Login
$loginBody = @{
    username = "root"
    password = "Asdqwe123"
    eauth = "pam"
} | ConvertTo-Json

$loginResp = Invoke-RestMethod -Uri "$BASE_URL/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginResp.return[0].token

# Headers
$headers = @{
    "X-Auth-Token" = $token
    "Accept" = "application/json"
}

# Ping
$pingBody = @{
    client = "local"
    tgt = "QWEN1"
    fun = "test.ping"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$BASE_URL/run" -Method Post -Body $pingBody -Headers $headers -ContentType "application/json"
```

---

## 9. Tabla de referencia rápida

### Parámetros comunes

| Parámetro | Valores típicos | Descripción |
|-----------|-----------------|-------------|
| `client` | `local`, `runner`, `wheel`, `local_async` | Tipo de operación |
| `tgt` | `QWEN1`, `'*'`, `'web*'` | Minion(s) objetivo |
| `fun` | `test.ping`, `cmd.run`, `state.apply`, `pillar.items` | Función a ejecutar |
| `arg` | `['arg1', 'arg2']` | Argumentos posicionales |
| `kwarg` | `{"key": "value"}` | Argumentos con nombre |
| `eauth` | `pam`, `ldap`, `sharedsecret` | Sistema de autenticación |

### Funciones más usadas

| Función | Descripción | Ejemplo |
|---------|-------------|---------|
| `test.ping` | Verificar conectividad | `fun=test.ping` |
| `cmd.run` | Ejecutar comando shell | `fun=cmd.run`, `arg='ls -la'` |
| `state.apply` | Aplicar estados | `fun=state.apply`, `arg='webserver'` |
| `state.highstate` | Aplicar highstate | `fun=state.highstate` |
| `pillar.items` | Obtener pillar data | `fun=pillar.items` |
| `pillar.get` | Obtener clave específica | `fun=pillar.get`, `arg='key:subkey'` |
| `pkg.install` | Instalar paquete | `fun=pkg.install`, `arg='nginx'` |
| `service.start` | Iniciar servicio | `fun=service.start`, `arg='nginx'` |
| `file.managed` | Gestionar archivo | `fun=file.managed` |
| `grains.items` | Obtener grains | `fun=grains.items` |

### Endpoints de la API

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/login` | POST | Autenticar y obtener token |
| `/run` | POST | Ejecutar funciones de Salt |
| `/minions` | GET | Listar minions |
| `/minions/<id>` | GET | Información de un minion |
| `/jobs` | GET | Lista de jobs ejecutados |
| `/jobs/<jid>` | GET | Detalles de un job |
| `/events` | GET | Stream de eventos en tiempo real |
| `/keys` | GET | Listar keys de minions |

---

## 10. Solución de problemas

### Error 401 Unauthorized

```json
{"return": [{"error": "No authentication credentials given"}]}
```

**Causa:** Token expirado o no enviado correctamente.

**Solución:**
1. Obtener nuevo token con `/login`
2. Asegurar que el header `X-Auth-Token` se envía correctamente
3. Verificar que el usuario tiene permisos en `/etc/salt/master.d/api.conf`

### Error de parsing YAML en configuración

**Causa:** Caracteres especiales como `@` sin comillas en YAML.

**Solución:** Usar comillas simples para `@wheel`, `@runner`, etc.:

```yaml
external_auth:
  pam:
    root:
      - '.*'
      - '@wheel'
      - '@runner'
      - '@jobs'
      - '@events'
```

### Minion no responde

**Causas posibles:**
1. Minion apagado o sin conexión
2. Key del minion no aceptada
3. Firewall bloqueando comunicación

**Solución:**
```bash
# Verificar estado del minion
salt 'QWEN1' test.ping

# Verificar keys
salt-key -L

# Aceptar key si está pendiente
salt-key -A -y
```

---

## 11. Configuración del servidor (referencia)

### Archivo: `/etc/salt/master.d/api.conf`

```yaml
external_auth:
  pam:
    root:
      - '.*'
      - '@wheel'
      - '@runner'
      - '@jobs'
      - '@events'

netapi_enable_clients:
  - local
  - runner
  - wheel

rest_cherrypy:
  port: 8000
  host: 0.0.0.0
  debug: True
  disable_ssl: True
```

### Reiniciar servicios

```bash
systemctl restart salt-master
systemctl restart salt-api
```

### Verificar estado

```bash
systemctl status salt-api
curl -s http://localhost:8000/login -d username=root -d password=Asdqwe123 -d eauth=pam
```

---

## 12. Seguridad

### Recomendaciones

1. **Usar HTTPS en producción:**
   ```yaml
   rest_cherrypy:
     port: 8000
     ssl_crt: /etc/pki/tls/certs/localhost.crt
     ssl_key: /etc/pki/tls/private/localhost.key
   ```

2. **Restringir permisos por usuario:**
   ```yaml
   external_auth:
     pam:
       admin:
         - '.*'
         - '@wheel'
         - '@runner'
       operator:
         - 'test.*'
         - 'pkg.*'
         - 'service.*'
   ```

3. **No exponer la API directamente a Internet**
4. **Usar firewall para restringir acceso al puerto 8000**
5. **Rotar tokens periódicamente**

---

*Documento generado: 2026-03-12*
*Versión de Salt: 3007.11*
