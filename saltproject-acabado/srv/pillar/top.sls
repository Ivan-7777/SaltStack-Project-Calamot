base:
  "minion-05":
    - customers.aitor.main
    - customers.aitor.firewall
    - customers.aitor.dns
    - customers.aitor.dhcp
    - customers.aitor.wireguard
  "minion-04":
    - customers.aitor.main
    - customers.aitor.webserver
  "minion-02":
    - customers.aitor.main
    - customers.aitor.webserver
    - customers.aitor.pkica
    - customers.aitor.wireguard
    - customers.aitor.dhcp
