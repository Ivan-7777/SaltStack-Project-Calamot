base:
  'minion-05':
    - firewall
    - dns
  'minion-04':
    - proxy
  'minion-02':
    - BDD
    - dhcp
    - pkica
    - wireguard
    - webserver
