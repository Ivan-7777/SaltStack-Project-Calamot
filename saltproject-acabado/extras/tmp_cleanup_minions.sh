#!/bin/bash
set +e
export DEBIAN_FRONTEND=noninteractive

systemctl stop zabbix-agent zabbix-server apache2 nginx mariadb mysql dnsmasq bind9 nftables isc-dhcp-server isc-dhcp-relay wg-quick@wg0 restic-rest-server zabbix-register-host.timer zabbix-register-host.service 2>/dev/null || true
systemctl disable zabbix-agent zabbix-server apache2 nginx mariadb mysql dnsmasq bind9 nftables isc-dhcp-server isc-dhcp-relay wg-quick@wg0 restic-rest-server zabbix-register-host.timer zabbix-register-host.service 2>/dev/null || true

wg-quick down wg0 2>/dev/null || true
ip link set wg0 down 2>/dev/null || true
ip link delete wg0 2>/dev/null || true
ip route flush dev wg0 2>/dev/null || true

crontab -l 2>/dev/null | grep -v -E "restic_backup|restic_maintenance" | crontab - 2>/dev/null || true

apt-get purge -y \
  zabbix-agent zabbix-server-mysql zabbix-frontend-php zabbix-sql-scripts zabbix-apache-conf \
  restic restic-rest-server \
  mariadb-server mariadb-server-* mariadb-client mariadb-client-* mariadb-common default-mysql-client mysql-common \
  apache2 apache2-* libapache2-mod-php* nginx dnsmasq bind9 nftables isc-dhcp-server isc-dhcp-relay wireguard wireguard-tools \
  2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
apt-get autoclean -y 2>/dev/null || true

rm -rf \
  /etc/zabbix /var/log/zabbix /var/lib/zabbix \
  /usr/local/bin/zabbix_verify.sh /usr/local/bin/zabbix_agent_verify.sh /usr/local/bin/zabbix_register_host.py \
  /etc/systemd/system/zabbix-register-host.service /etc/systemd/system/zabbix-register-host.timer \
  /root/.restic_env /usr/local/bin/restic_backup.sh /usr/local/bin/restic_maintenance.sh \
  /var/log/restic_backup.log /var/log/restic_maintenance.log /backups \
  /etc/mysql /var/lib/mysql /var/log/mysql /var/log/mysql* \
  /etc/dnsmasq.conf /etc/bind/zones /etc/bind/named.conf.options /etc/bind/named.conf.local \
  /etc/nftables.conf /etc/default/isc-dhcp-relay /etc/wireguard \
  /var/www/user /var/www/html/wordpress /var/www/html/index.php /etc/apache2/sites-available/wordpress.conf \
  /etc/pki/ca \
  2>/dev/null || true

systemctl daemon-reload 2>/dev/null || true
dpkg --configure -a 2>/dev/null || true

systemctl stop zabbix-agent zabbix-server apache2 nginx mariadb mysql dnsmasq bind9 nftables isc-dhcp-server isc-dhcp-relay wg-quick@wg0 restic-rest-server zabbix-register-host.timer zabbix-register-host.service 2>/dev/null || true
wg-quick down wg0 2>/dev/null || true
ip link set wg0 down 2>/dev/null || true
ip link delete wg0 2>/dev/null || true
ip route flush dev wg0 2>/dev/null || true

echo CLEANED
