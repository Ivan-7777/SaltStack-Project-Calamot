# PKI CA Server Salt State

Este estado de **SaltStack** despliega una **Autoridad Certificadora (CA)** local utilizando **OpenSSL**.  
Está diseñado para ser totalmente parametrizable mediante **pillars**, de modo que se puedan definir todos los datos de la CA (nombre, organización, días de validez, tamaño de clave, etc.) sin modificar el código del estado.

---

## Estructura del estado

### `pkica/init.sls`

1. **Instalación de OpenSSL**
   - Se asegura de que `openssl` esté instalado en el sistema.

2. **Creación de directorios base de la CA**
   - Directorios gestionados:
     - `base_dir` (raíz de la CA)
     - `private` (clave privada de la CA)
     - `newcerts` (certificados generados)
     - `certs` (certificados emitidos)
     - `crl` (listas de revocación)
   - Todos estos paths se definen en el pillar `pkica.base_dir`.

3. **Archivos de gestión de la CA**
   - `index.txt` → fichero de índice de certificados emitidos.
   - `serial` → fichero que mantiene el siguiente número de serie.
   - Ambos se crean automáticamente y se inicializan desde los valores del pillar.

4. **OpenSSL configuration**
   - Se genera `/etc/pki/ca/openssl.cnf` desde `openssl.cnf.jinja`.
   - Configuración parametrizada vía pillar (`pkica.files.openssl_config`).

5. **Generación de la clave privada de la CA**
   - Se genera usando `openssl genrsa`.
   - Tamaño definido en `pillar['pkica']['ca']['key_size']`.
   - Permisos fijos a `600` y propiedad root.

6. **Generación del certificado raíz de la CA**
   - Se genera el certificado auto-firmado usando:
     - Clave privada de la CA
     - Digest definido en el pillar (`sha256`, por ejemplo)
     - Días de validez desde `pillar['pkica']['ca']['days_valid']`
     - Configuración desde el archivo `openssl.cnf.jinja`
     - Datos de la CA (`C`, `ST`, `L`, `O`, `OU`, `CN`) obtenidos del pillar
   - Resultado: `root_cert` en el path definido en pillar.

---

## Ejemplo de pillar `pkica`

```yaml
pkica:
  base_dir: /etc/pki/ca
  
  ca:
    country: ES
    state: Madrid
    locality: Madrid
    organization: MiOrg
    organizational_unit: IT
    common_name: mi-ca
    days_valid: 3650
    key_size: 4096
    digest: sha256

  files:
    index: /etc/pki/ca/index.txt
    serial: /etc/pki/ca/serial
    serial_start: 1000
    openssl_config: /etc/pki/ca/openssl.cnf
    private_key: /etc/pki/ca/private/ca.key.pem
    root_cert: /etc/pki/ca/certs/ca.cert.pem

Todos los valores de la CA son parametrizables mediante pillar.

Permite desplegar la misma configuración de CA en distintos entornos sin tocar el código del estado.

Archivos Jinja

openssl.cnf.jinja → plantilla de configuración de OpenSSL que recoge los valores de pillar (pkica.ca.*) y genera un fichero listo para la CA.

Uso

Definir los valores de la CA en el pillar pkica.

Ejecutar el estado sobre el minion correspondiente:

salt <minion> state.apply pkica

El minion creará la estructura de directorios, generará la clave privada y el certificado raíz de la CA.

Notas

El estado asegura la integridad de los archivos críticos: no sobreescribe la clave privada si ya existe y fija permisos seguros (600).

Todo está diseñado para automatizar la creación de una CA local completa, lista para emitir certificados a servidores o clientes dentro de la infraestructura.
