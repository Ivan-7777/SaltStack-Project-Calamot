pki_ca_directories:
  file.directory:
    - names:
      - /etc/pki/ca
      - /etc/pki/ca/private
      - /etc/pki/ca/newcerts
      - /etc/pki/ca/certs
      - /etc/pki/ca/crl
    - mode: 750
    - user: root
    - group: root
    - makedirs: True

pki_ca_index_file:
  file.managed:
    - name: /etc/pki/ca/index.txt
    - contents: ''
    - user: root
    - group: root
    - mode: 600

    - user: root
    - group: root
    - mode: 600

pki_ca_serial_file:
  file.managed:
    - name: /etc/pki/ca/serial
    - contents: '1000'
    - user: root
    - group: root
    - mode: 600

pki_ca_openssl_config:
  file.managed:
    - name: /etc/pki/ca/openssl.cnf
    - source: salt://pkica/files/openssl.cnf
    - user: root
    - group: root
    - mode: 640

pki_ca_private_key:
  cmd.run:
    - name: openssl genrsa -out /etc/pki/ca/private/ca.key.pem 4096
    - creates: /etc/pki/ca/private/ca.key.pem
    - require:
      - file: pki_ca_directories

pki_ca_root_cert:
  cmd.run:
    - name: >
        openssl req -x509 -new -nodes
        -key /etc/pki/ca/private/ca.key.pem
        -sha256 -days 3650
        -config /etc/pki/ca/openssl.cnf
        -out /etc/pki/ca/certs/ca.cert.pem
        -subj "/C=ES/ST=Madrid/L=Madrid/O=MiOrg/OU=IT/CN=mi-ca"
    - creates: /etc/pki/ca/certs/ca.cert.pem
    - require:
      - cmd: pki_ca_private_key
      - file: pki_ca_openssl_config
