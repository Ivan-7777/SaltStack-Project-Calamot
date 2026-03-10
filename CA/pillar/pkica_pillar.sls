# Pillar data para PKI CA
# Estructura similar a firewall: pillar['pkica']['...']

pkica:
  base_dir: /etc/pki/ca
  
  # Configuración de la CA
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
  
  # Paths de archivos
  files:
    index: /etc/pki/ca/index.txt
    serial: /etc/pki/ca/serial
    serial_start: 1000
    openssl_config: /etc/pki/ca/openssl.cnf
    private_key: /etc/pki/ca/private/ca.key.pem
    root_cert: /etc/pki/ca/certs/ca.cert.pem
  
  # Permisos
  permissions:
    dir_mode: 750
    config_mode: 640
    private_mode: 600
    index_mode: 600
    serial_mode: 600
