# Ejemplo de pillar que DEPENDE de pkica
# Un servicio web que necesita certificados SSL firmados por la CA

webserver:
  # Configuración básica del webserver
  port: 80
  ssl_port: 443
  document_root: /var/www/html
  
  # Configuración SSL que depende de la CA
  ssl:
    enabled: True
    # Usa la CA del pillar pkica
    ca_cert: {{ pillar.get('pkica', {}).get('files', {}).get('root_cert', '/etc/pki/ca/certs/ca.cert.pem') }}
    ca_dir: {{ pillar.get('pkica', {}).get('base_dir', '/etc/pki/ca') }}
    
    # Certificado del servidor (se generará usando la CA)
    server_cert: /etc/ssl/certs/server.crt
    server_key: /etc/ssl/private/server.key
    cn: "{{ grains['fqdn'] }}"
    days_valid: 365
