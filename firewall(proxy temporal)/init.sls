# SaltStack State for Firewall Configuration
# Includes: nftables, Bind9 DNS, Network Configuration

# Update system packages
firewall_packages:
  pkg.installed:
    - pkgs:
      - nftables
      - bind9
      - bind9-utils
      - isc-dhcp-server

# Enable IP forwarding
net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

# Configure network interfaces
/etc/network/interfaces:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/interfaces
    - user: root
    - group: root
    - mode: 644

# Configure nftables
/etc/nftables.conf:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/nftables.conf
    - user: root
    - group: root
    - mode: 644

# Enable and start nftables
nftables:
  service.running:
    - enable: True

# Configure Bind9 - named.conf.local
/etc/bind/named.conf.local:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/named.conf.local
    - user: root
    - group: root
    - mode: 644

# Configure Bind9 - named.conf.options
/etc/bind/named.conf.options:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/named.conf.options
    - user: root
    - group: root
    - mode: 644

# Create DNS zone - server (directa)
/etc/bind/db.server:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/db.server
    - user: root
    - group: bind
    - mode: 644

# Create DNS zone - 1.168.192 (inversa LAN)
/etc/bind/db.1.168.192:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/db.1.168.192
    - user: root
    - group: bind
    - mode: 644

# Create DNS zone - 2.168.192 (inversa DMZ)
/etc/bind/db.2.168.192:
  file.managed:
    - source: salt://'firewall(proxy temporal)'/db.2.168.192
    - user: root
    - group: bind
    - mode: 644

# Enable and start Bind9
bind9:
  service.running:
    - enable: True
