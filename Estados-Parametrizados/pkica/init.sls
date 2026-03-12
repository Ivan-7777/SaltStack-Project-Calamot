# pkica/init.sls - CA Server State
# Uses Jinja template for openssl.cnf configuration

# Install OpenSSL if not present
pki_openssl:
  pkg.installed:
    - name: openssl


# Create CA base directories
pki_ca_directories:
  file.directory:
    - names:
        - {{ pillar['pkica']['base_dir'] }}
        - {{ pillar['pkica']['base_dir'] }}/private
        - {{ pillar['pkica']['base_dir'] }}/newcerts
        - {{ pillar['pkica']['base_dir'] }}/certs
        - {{ pillar['pkica']['base_dir'] }}/crl
    - mode: 750
    - user: root
    - group: root
    - makedirs: True
    - require:
        - pkg: pki_openssl


# CA index.txt file
pki_ca_index_file:
  file.managed:
    - name: {{ pillar['pkica']['files']['index'] }}
    - contents: ''
    - user: root
    - group: root
    - mode: 600
    - require:
        - file: pki_ca_directories


# CA serial file
pki_ca_serial_file:
  file.managed:
    - name: {{ pillar['pkica']['files']['serial'] }}
    - contents: '{{ pillar['pkica']['files']['serial_start'] }}'
    - user: root
    - group: root
    - mode: 600
    - require:
        - file: pki_ca_directories


# OpenSSL configuration from Jinja template
pki_ca_openssl_config:
  file.managed:
    - name: {{ pillar['pkica']['files']['openssl_config'] }}
    - source: salt://pkica/files/openssl.cnf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
    - require:
        - file: pki_ca_directories


# Generate CA private key
pki_ca_private_key:
  cmd.run:
    - name: openssl genrsa -out {{ pillar['pkica']['files']['private_key'] }} {{ pillar['pkica']['ca']['key_size'] }}
    - creates: {{ pillar['pkica']['files']['private_key'] }}
    - require:
        - file: pki_ca_directories
        - pkg: pki_openssl


# Ensure correct permissions on private key
pki_ca_private_key_permissions:
  file.managed:
    - name: {{ pillar['pkica']['files']['private_key'] }}
    - user: root
    - group: root
    - mode: 600
    - replace: False
    - require:
        - cmd: pki_ca_private_key


# Generate CA root certificate
pki_ca_root_cert:
  cmd.run:
    - name: >
        openssl req -x509 -new -nodes
        -key {{ pillar['pkica']['files']['private_key'] }}
        -{{ pillar['pkica']['ca']['digest'] }} -days {{ pillar['pkica']['ca']['days_valid'] }}
        -config {{ pillar['pkica']['files']['openssl_config'] }}
        -out {{ pillar['pkica']['files']['root_cert'] }}
        -subj "/C={{ pillar['pkica']['ca']['country'] }}/ST={{ pillar['pkica']['ca']['state'] }}/L={{ pillar['pkica']['ca']['locality'] }}/O={{ pillar['pkica']['ca']['organization'] }}/OU={{ pillar['pkica']['ca']['organizational_unit'] }}/CN={{ pillar['pkica']['ca']['common_name'] }}"
    - creates: {{ pillar['pkica']['files']['root_cert'] }}
    - require:
        - cmd: pki_ca_private_key
        - file: pki_ca_openssl_config
