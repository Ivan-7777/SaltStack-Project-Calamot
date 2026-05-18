#!/usr/bin/env python3
import json
import socket
import sys
import time
import urllib.error
import urllib.request
import urllib.parse

API_URL = "http://{{ salt['pillar.get']('zabbix:server_ip', '192.168.0.151') }}/zabbix/api_jsonrpc.php"
API_USER = "{{ salt['pillar.get']('zabbix:api_user', 'Admin') }}"
API_PASS = "{{ salt['pillar.get']('zabbix:api_pass', 'zabbix') }}"
HOSTNAME = "{{ salt['grains.get']('id') }}"
AGENT_PORT = "{{ salt['pillar.get']('zabbix:agent_port', '10050') }}"
GROUP_NAME = "{{ salt['pillar.get']('zabbix:host_group', 'Linux servers') }}"
TEMPLATE_NAME = "{{ salt['pillar.get']('zabbix:template', 'Linux by Zabbix agent active') }}"
RETRIES = int("{{ salt['pillar.get']('zabbix:register_retries', '90') }}")
SLEEP = int("{{ salt['pillar.get']('zabbix:register_sleep', '5') }}")
{% set zabbix_hostname = salt['grains.get']('id') %}
{% set minion_states = salt['pillar.get']('service_mapping:' ~ zabbix_hostname, []) %}
{% set enabled_services = salt['pillar.get']('enabled_services', {}) %}
{% set state_services = {
  "BDD": ["mariadb"],
  "dhcp": ["dnsmasq"],
  "dns": ["named"],
  "firewall": ["nftables"],
  "proxy": ["nginx"],
  "wordpress": ["apache2"],
  "webserver": ["apache2"],
  "wireguard": ["wg-quick@wg0", "nftables"],
  "zabbix.server": ["zabbix-server", "apache2"],
  "zabbix.agent": ["zabbix-agent"],
  "restic.server": ["restic-rest-server"]
} %}
{% set monitored_services = [] %}
{% for state in minion_states %}
{% for service_name in state_services.get(state, []) %}
{% if service_name not in monitored_services %}
{% do monitored_services.append(service_name) %}
{% endif %}
{% endfor %}
{% endfor %}
{% if "firewall" in minion_states and (enabled_services.get("dhcp", False) or enabled_services.get("proxy", False)) and "isc-dhcp-relay" not in monitored_services %}
{% do monitored_services.append("isc-dhcp-relay") %}
{% endif %}
SERVICE_CHECKS = [
{% for service_name in monitored_services %}
    {"service": "{{ service_name }}", "key": "service.status[{{ service_name }}]", "name": "Service {{ service_name }} is running"},
{% endfor %}
]


def local_ip():
    try:
        ips = [ip for ip in socket.gethostbyname_ex(socket.gethostname())[2] if not ip.startswith("127.")]
        if ips:
            return ips[0]
    except socket.gaierror:
        pass

    server_host = urllib.parse.urlparse(API_URL).hostname
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect((server_host, 10051))
        return sock.getsockname()[0]
    finally:
        sock.close()


def api(method, params=None, auth=None, request_id=1):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params or {},
        "id": request_id
    }
    if auth is not None:
        payload["auth"] = auth

    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        data = json.loads(response.read().decode("utf-8"))

    if "error" in data:
        raise RuntimeError(f"{method}: {data['error']}")
    return data["result"]


def first_id(method, params, key, auth, request_id):
    result = api(method, params, auth, request_id)
    if not result:
        return None
    return result[0][key]


def ensure_service_item(host_id, interface_id, check, auth, request_id):
    item_id = first_id(
        "item.get",
        {
            "output": ["itemid"],
            "hostids": host_id,
            "filter": {"key_": [check["key"]]}
        },
        "itemid",
        auth,
        request_id
    )
    params = {
        "name": check["name"],
        "key_": check["key"],
        "type": 0,
        "value_type": 3,
        "delay": "30s",
        "history": "7d",
        "trends": "30d",
        "status": 0,
        "interfaceid": interface_id,
        "description": "Managed by Salt. Created only when the related Salt state is selected."
    }
    if item_id is None:
        params["hostid"] = host_id
        return api("item.create", params, auth, request_id + 1)["itemids"][0]

    params["itemid"] = item_id
    api("item.update", params, auth, request_id + 1)
    return item_id


def ensure_service_trigger(check, auth, request_id):
    description = f"{HOSTNAME}: service {check['service']} is inactive"
    trigger_id = first_id(
        "trigger.get",
        {
            "output": ["triggerid"],
            "filter": {"description": [description]}
        },
        "triggerid",
        auth,
        request_id
    )
    expression = f"last(/{HOSTNAME}/{check['key']})=0"
    params = {
        "description": description,
        "expression": expression,
        "priority": 4,
        "status": 0,
        "comments": "Managed by Salt. Alert exists only for services selected in the generated pillar."
    }
    if trigger_id is None:
        api("trigger.create", params, auth, request_id + 1)
        return

    params["triggerid"] = trigger_id
    api("trigger.update", params, auth, request_id + 1)


def main():
    auth = api("user.login", {"username": API_USER, "password": API_PASS}, request_id=1)

    group_id = first_id(
        "hostgroup.get",
        {"output": ["groupid"], "filter": {"name": [GROUP_NAME]}},
        "groupid",
        auth,
        2
    )
    if group_id is None:
        group_id = api("hostgroup.create", {"name": GROUP_NAME}, auth, 3)["groupids"][0]

    template_id = first_id(
        "template.get",
        {"output": ["templateid"], "filter": {"host": [TEMPLATE_NAME]}},
        "templateid",
        auth,
        4
    )
    if template_id is None:
        raise RuntimeError(f"Template not found: {TEMPLATE_NAME}")

    host_id = first_id(
        "host.get",
        {"output": ["hostid"], "filter": {"host": [HOSTNAME]}},
        "hostid",
        auth,
        5
    )

    interface = {
        "type": 1,
        "main": 1,
        "useip": 1,
        "ip": local_ip(),
        "dns": "",
        "port": AGENT_PORT
    }

    if host_id is None:
        result = api(
            "host.create",
            {
                "host": HOSTNAME,
                "name": HOSTNAME,
                "status": 0,
                "groups": [{"groupid": group_id}],
                "templates": [{"templateid": template_id}],
                "interfaces": [interface]
            },
            auth,
            6
        )
        host_id = result["hostids"][0]
        interface_id = first_id(
            "hostinterface.get",
            {"output": ["interfaceid"], "hostids": host_id, "filter": {"type": 1, "main": 1}},
            "interfaceid",
            auth,
            7
        )
        for index, check in enumerate(SERVICE_CHECKS):
            ensure_service_item(host_id, interface_id, check, auth, 20 + index * 4)
            ensure_service_trigger(check, auth, 22 + index * 4)
        print(f"Created Zabbix host: {HOSTNAME}")
        return 0

    interface_id = first_id(
        "hostinterface.get",
        {"output": ["interfaceid"], "hostids": host_id, "filter": {"type": 1, "main": 1}},
        "interfaceid",
        auth,
        7
    )
    if interface_id is None:
        api(
            "hostinterface.create",
            {"hostid": host_id, **interface},
            auth,
            8
        )
    else:
        api(
            "hostinterface.update",
            {"interfaceid": interface_id, **interface},
            auth,
            8
        )

    api(
        "host.update",
        {
            "hostid": host_id,
            "status": 0,
            "groups": [{"groupid": group_id}],
            "templates": [{"templateid": template_id}]
        },
        auth,
        9
    )
    for index, check in enumerate(SERVICE_CHECKS):
        ensure_service_item(host_id, interface_id, check, auth, 20 + index * 4)
        ensure_service_trigger(check, auth, 22 + index * 4)
    print(f"Updated Zabbix host: {HOSTNAME}")
    return 0


if __name__ == "__main__":
    last_error = None
    for attempt in range(1, RETRIES + 1):
        try:
            sys.exit(main())
        except (urllib.error.URLError, TimeoutError, RuntimeError, OSError) as exc:
            last_error = exc
            print(f"Attempt {attempt}/{RETRIES} failed: {exc}", file=sys.stderr)
            if attempt < RETRIES:
                time.sleep(SLEEP)
    print(f"Zabbix host registration failed: {last_error}", file=sys.stderr)
    sys.exit(1)
