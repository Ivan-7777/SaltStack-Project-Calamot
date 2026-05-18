<?php
// require_once "auth.php";
// check_auth();

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    die("POST requerido");
}

function sanitize_name($value) {
    return preg_replace('/[^a-zA-Z0-9_]/', '_', strtolower(trim((string)$value)));
}

function post_bool($value) {
    return in_array(strtolower((string)$value), ["1", "true", "yes", "on"], true);
}

function yaml_scalar($value) {
    if (is_bool($value)) return $value ? "true" : "false";
    if (is_int($value) || is_float($value)) return (string)$value;
    if ($value === null) return "null";
    $string = (string)$value;
    if ($string === "" || preg_match('/[:#\\-\\{\\}\\[\\],&\\*\\?\\|><=!%@]/', $string) || preg_match('/\\s/', $string)) {
        return '"' . str_replace('"', '\\"', $string) . '"';
    }
    return $string;
}

function yaml_key($key) {
    $string = (string)$key;
    if ($string === "" || preg_match('/^[*&#?!%@`]|[:{}\\[\\],]|^\s|\s$/', $string) || preg_match('/\\s/', $string)) {
        return '"' . str_replace('"', '\\"', $string) . '"';
    }
    return $string;
}

function array_to_yaml($data, $indent = 0) {
    $yaml = "";
    $prefix = str_repeat("  ", $indent);
    $is_list = array_keys($data) === range(0, count($data) - 1);
    foreach ($data as $key => $value) {
        if ($is_list) {
            if (is_array($value)) {
                $yaml .= $prefix . "-" . PHP_EOL . array_to_yaml($value, $indent + 1);
            } else {
                $yaml .= $prefix . "- " . yaml_scalar($value) . PHP_EOL;
            }
            continue;
        }
        if (is_array($value)) {
            if ($value === []) {
                $yaml .= $prefix . yaml_key($key) . ": {}" . PHP_EOL;
            } else {
                $yaml .= $prefix . yaml_key($key) . ":" . PHP_EOL . array_to_yaml($value, $indent + 1);
            }
        } else {
            $yaml .= $prefix . yaml_key($key) . ": " . yaml_scalar($value) . PHP_EOL;
        }
    }
    return $yaml;
}

function write_yaml_file($path, $data) {
    $result = file_put_contents($path, array_to_yaml($data));
    if ($result === false) {
        throw new RuntimeException("No se pudo escribir el archivo: " . $path);
    }
}

function accepted_minions() {
    $json = @shell_exec("salt-key -l acc --out=json 2>/dev/null");
    $data = json_decode((string)$json, true);
    if (isset($data["minions"]) && is_array($data["minions"])) {
        $minions = array_values(array_filter($data["minions"], fn($m) => is_string($m) && preg_match('/^[A-Za-z0-9_.-]+$/', $m)));
        sort($minions);
        return $minions ?: ["minion-02", "minion-04", "minion-05", "minion-08"];
    }
    $output = [];
    @exec("salt-key -l acc 2>/dev/null", $output);
    $minions = [];
    foreach ($output as $line) {
        $line = trim($line);
        if ($line === "" || str_ends_with($line, ":")) {
            continue;
        }
        if (preg_match('/^[A-Za-z0-9_.-]+$/', $line)) {
            $minions[] = $line;
        }
    }
    $minions = array_values(array_unique($minions));
    sort($minions);
    return $minions ?: ["minion-02", "minion-04", "minion-05", "minion-08"];
}

function minion_ip_map() {
    $json = @shell_exec("salt '*' network.ip_addrs --out=json --static 2>/dev/null");
    $data = json_decode((string)$json, true);
    $ips = [];
    if (is_array($data)) {
        foreach ($data as $minion => $addr_list) {
            if (!is_array($addr_list)) {
                continue;
            }
            foreach ($addr_list as $addr) {
                if (is_string($addr) && filter_var($addr, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) && $addr !== "127.0.0.1") {
                    $ips[$minion] = $addr;
                    break;
                }
            }
        }
    }
    return $ips;
}

function minion_master_map() {
    $json = @shell_exec("salt '*' config.get master --out=json --static 2>/dev/null");
    $data = json_decode((string)$json, true);
    $masters = [];
    if (is_array($data)) {
        foreach ($data as $minion => $master) {
            if (is_string($master) && $master !== "") {
                $masters[$minion] = $master;
            }
        }
    }
    return $masters;
}

function valid_minion($value, $default) {
    $allowed = accepted_minions();
    $value = trim((string)$value);
    return in_array($value, $allowed, true) ? $value : $default;
}

function add_state(&$map, $minion, $state) {
    if (!isset($map[$minion])) {
        $map[$minion] = [];
    }
    if (!in_array($state, $map[$minion], true)) {
        $map[$minion][] = $state;
    }
}

function deep_merge_array($base, $override) {
    if (!is_array($override)) {
        return $base;
    }
    foreach ($override as $key => $value) {
        if (is_array($value) && isset($base[$key]) && is_array($base[$key])) {
            $base[$key] = deep_merge_array($base[$key], $value);
        } else {
            $base[$key] = $value;
        }
    }
    return $base;
}

function to_int_fields(&$data, $fields) {
    foreach ($fields as $field) {
        if (isset($data[$field]) && is_numeric($data[$field])) {
            $data[$field] = (int)$data[$field];
        }
    }
}

function ip_host($gateway_ip, $host_octet) {
    $long = ip2long((string)$gateway_ip);
    if ($long === false) {
        return $gateway_ip;
    }
    $network = $long & 0xFFFFFF00;
    return long2ip($network + (int)$host_octet);
}

function cidr_net($ip, $mask) {
    $long = ip2long((string)$ip);
    if ($long === false) {
        return $ip . "/" . (int)$mask;
    }
    $mask = (int)$mask;
    $mask_long = $mask === 0 ? 0 : ((0xFFFFFFFF << (32 - $mask)) & 0xFFFFFFFF);
    return long2ip($long & $mask_long) . "/" . $mask;
}

function cidr_netmask($mask) {
    $mask = (int)$mask;
    $mask_long = $mask === 0 ? 0 : ((0xFFFFFFFF << (32 - $mask)) & 0xFFFFFFFF);
    return long2ip($mask_long);
}

function replace_legacy_ip($current, $legacy, $replacement) {
    $current = trim((string)$current);
    return ($current === "" || $current === $legacy) ? $replacement : $current;
}

function first_matching_service($states, $priority) {
    foreach ($priority as $state) {
        if (in_array($state, $states, true)) {
            return $state;
        }
    }
    return $states[0] ?? null;
}

$company = sanitize_name($_POST["company"] ?? "aitor");
$states = $_POST["states"] ?? [];
$selected = array_flip($states);
$targets_post = $_POST["targets"] ?? [];
$targets = [
    "firewall" => valid_minion($targets_post["firewall"] ?? null, "minion-05"),
    "dns" => valid_minion($targets_post["dns"] ?? null, "minion-05"),
    "proxy" => valid_minion($targets_post["proxy"] ?? null, "minion-04"),
    "BDD" => valid_minion($targets_post["BDD"] ?? null, "minion-02"),
    "dhcp" => valid_minion($targets_post["dhcp"] ?? null, "minion-04"),
    "pkica" => valid_minion($targets_post["pkica"] ?? null, "minion-02"),
    "wireguard" => valid_minion($targets_post["wireguard"] ?? null, "minion-08"),
    "webserver" => valid_minion($targets_post["webserver"] ?? null, "minion-02"),
    "zabbix-server" => valid_minion($targets_post["zabbix-server"] ?? null, "minion-08"),
    "restic-server" => valid_minion($targets_post["restic-server"] ?? null, "minion-08"),
];
if (isset($selected["zabbix-server"]) || isset($selected["restic-server"])) {
    $selected["BDD"] = true;
}
$enabled_services = [
    "firewall" => isset($selected["firewall"]) || isset($selected["dhcp"]) || isset($selected["proxy"]),
    "dns" => isset($selected["dns"]),
    "proxy" => isset($selected["proxy"]),
    "bdd" => isset($selected["BDD"]),
    "dhcp" => isset($selected["dhcp"]),
    "pkica" => isset($selected["pkica"]),
    "wireguard" => isset($selected["wireguard"]),
    "webserver" => isset($selected["webserver"]),
    "zabbix" => isset($selected["zabbix-server"]),
    "restic" => isset($selected["restic-server"])
];

// Default structure to avoid Jinja errors
$firewall = [
    "wan" => ["ip" => "10.1.105.47", "mask" => 24, "gateway" => "10.1.105.1", "interface" => "enp0s3"],
    "lan" => ["ip" => "192.168.0.1", "mask" => 24, "interface" => "enp0s8"],
    "dmz" => ["ip" => "192.168.1.1", "mask" => 24, "interface" => "enp0s9"]
];
$firewall = deep_merge_array($firewall, $_POST["firewall"] ?? []);
foreach (["wan", "lan", "dmz"] as $zone) {
    to_int_fields($firewall[$zone], ["mask"]);
}

$proxy = ["ip" => "192.168.1.10", "puerto_customizado" => 80, "interface" => "enp0s3", "mask" => 24];
$proxy = deep_merge_array($proxy, $_POST["proxy"] ?? []);
to_int_fields($proxy, ["puerto_customizado", "mask"]);

$web = [
    "hostname" => "serv-web",
    "domain" => "server.es",
    "webroot" => "/var/www/user/server/html",
    "network" => ["address" => "192.168.0.10", "mask" => 24, "gateway" => "192.168.0.1", "dns" => "192.168.0.1", "interface" => "enp0s3"]
];
$web = deep_merge_array($web, $_POST["web-server"] ?? []);
to_int_fields($web["network"], ["mask"]);
to_int_fields($web["ssh"], ["port"]);

$dhcp = [
    "server_ip" => "192.168.0.20",
    "server_interface" => "enp0s3",
    "log" => true,
    "interfaces" => [
        "lan" => ["name" => "enp0s3", "range_start" => "192.168.0.50", "range_end" => "192.168.0.200", "netmask" => "255.255.255.0", "lease_time" => "24h"],
        "dmz" => ["name" => "enp0s3", "range_start" => "192.168.1.50", "range_end" => "192.168.1.200", "netmask" => "255.255.255.0", "lease_time" => "24h"]
    ],
    "options" => [
        "gateway" => ["lan" => "192.168.0.1", "dmz" => "192.168.1.1"],
        "dns" => ["lan" => "192.168.0.1", "dmz" => "192.168.1.1"]
    ]
];
$dhcp = deep_merge_array($dhcp, $_POST["dhcp"] ?? []);
if (isset($dhcp["log"])) {
    $dhcp["log"] = post_bool($dhcp["log"]);
}

$pkica = [
    "base_dir" => "/etc/pki/ca",
    "ca" => ["country" => "ES", "state" => "Girona", "locality" => "Salt", "organization" => "SaltStack Lab", "organizational_unit" => "IT", "common_name" => "Salt-CA", "days_valid" => 3650, "key_size" => 4096, "digest" => "sha256"],
    "files" => [
        "private_key" => "/etc/pki/ca/private/ca.key.pem", "root_cert" => "/etc/pki/ca/certs/ca.cert.pem", "openssl_config" => "/etc/pki/ca/openssl.cnf",
        "index" => "/etc/pki/ca/index.txt", "serial" => "/etc/pki/ca/serial", "serial_start" => "1000"
    ]
];
$pkica = deep_merge_array($pkica, $_POST["pkica"] ?? []);
to_int_fields($pkica["ca"], ["days_valid", "key_size"]);
to_int_fields($pkica["files"], ["serial_start"]);

$wireguard = ["port" => 51820, "address" => "10.66.66.1/24", "static_lan_ip" => "192.168.0.151/24", "wan_interface" => "enp0s3", "client_allowed_ips" => "10.66.66.0/24,192.168.0.0/24", "client_web_host" => "server.es", "peers" => []];
if (isset($_POST["wireguard"]) && is_array($_POST["wireguard"])) {
    $wg_post = $_POST["wireguard"];
    if (isset($wg_post["port"]) && is_numeric($wg_post["port"])) {
        $wireguard["port"] = (int)$wg_post["port"];
    }
    foreach (["address", "wan_interface", "client_allowed_ips", "client_web_host"] as $wg_key) {
        if (isset($wg_post[$wg_key]) && trim((string)$wg_post[$wg_key]) !== "") {
            $wireguard[$wg_key] = trim((string)$wg_post[$wg_key]);
        }
    }
}
to_int_fields($wireguard, ["port"]);

$zabbix = [
    "db_host" => "192.168.0.10", "db_port" => 3306, "db_name" => "zabbix", "db_user" => "zabbix", "db_pass" => "Z@bb1x_2026!", "db_root" => "M@r1aDB_R00t_2026!",
    "server_ip" => "192.168.0.151", "agent_port" => 10050, "discovery_network" => "192.168.0.0/24"
];
$zabbix = deep_merge_array($zabbix, $_POST["zabbix"] ?? []);
to_int_fields($zabbix, ["db_port", "agent_port"]);

$restic = [
    "password" => "R3st1c_Backup_2026!", "repository" => "rest:http://192.168.0.151:8000/", "port" => 8000, "backup_paths" => ["/etc"],
    "mysql" => ["user" => "saltlogger", "password" => "S@ltL0gg3r_2026!", "host" => "192.168.0.10", "database" => "salt_logs", "port" => 3306, "root_password" => "M@r1aDB_R00t_2026!"]
];
$restic = deep_merge_array($restic, $_POST["restic"] ?? []);
to_int_fields($restic, ["port"]);
if (isset($restic["mysql"])) {
    to_int_fields($restic["mysql"], ["port"]);
}
if (isset($restic["backup_paths"])) {
    if (is_string($restic["backup_paths"])) {
        $restic["backup_paths"] = array_values(array_filter(array_map("trim", explode(",", $restic["backup_paths"]))));
    } elseif (is_array($restic["backup_paths"])) {
        $restic["backup_paths"] = array_values(array_filter(array_map("trim", $restic["backup_paths"])));
    }
}
if (empty($restic["backup_paths"])) {
    $restic["backup_paths"] = ["/etc"];
}

$mysql = ["root_password" => "M@r1aDB_R00t_2026!"];
$mysql = deep_merge_array($mysql, $_POST["mysql"] ?? []);

$wordpress_post = $_POST["wordpress"] ?? [];

$lan_gateway = $firewall["lan"]["ip"];
$dmz_gateway = $firewall["dmz"]["ip"];
$lan_mask = (int)$firewall["lan"]["mask"];
$dmz_mask = (int)$firewall["dmz"]["mask"];
$wan_mask = (int)$firewall["wan"]["mask"];
$lan_net = cidr_net($lan_gateway, $lan_mask);
$dmz_net = cidr_net($dmz_gateway, $dmz_mask);
$wan_net = cidr_net($firewall["wan"]["ip"], $wan_mask);
$default_web_ip = ip_host($lan_gateway, 10);
$default_dhcp_ip = ip_host($lan_gateway, 10);
$default_proxy_ip = ip_host($dmz_gateway, 10);
$default_wg_ip = ip_host($lan_gateway, 151);
$default_lan_range_start = ip_host($lan_gateway, 50);
$default_lan_range_end = ip_host($lan_gateway, 200);
$default_dmz_range_start = ip_host($dmz_gateway, 50);
$default_dmz_range_end = ip_host($dmz_gateway, 200);

$proxy["ip"] = replace_legacy_ip($proxy["ip"] ?? "", "192.168.1.10", $default_proxy_ip);
$web["network"]["address"] = replace_legacy_ip($web["network"]["address"] ?? "", "192.168.0.10", $default_web_ip);
$web["network"]["gateway"] = replace_legacy_ip($web["network"]["gateway"] ?? "", "192.168.0.1", $lan_gateway);
$web["network"]["dns"] = replace_legacy_ip($web["network"]["dns"] ?? "", "192.168.0.1", $lan_gateway);
$web["network"]["mask"] = (int)($web["network"]["mask"] ?? $lan_mask);
$dhcp["server_ip"] = replace_legacy_ip($dhcp["server_ip"] ?? "", "192.168.0.10", $default_dhcp_ip);
$dhcp["interfaces"]["lan"]["range_start"] = replace_legacy_ip($dhcp["interfaces"]["lan"]["range_start"] ?? "", "192.168.0.50", $default_lan_range_start);
$dhcp["interfaces"]["lan"]["range_end"] = replace_legacy_ip($dhcp["interfaces"]["lan"]["range_end"] ?? "", "192.168.0.200", $default_lan_range_end);
$dhcp["interfaces"]["lan"]["netmask"] = replace_legacy_ip($dhcp["interfaces"]["lan"]["netmask"] ?? "", "255.255.255.0", cidr_netmask($lan_mask));
$dhcp["interfaces"]["dmz"]["range_start"] = replace_legacy_ip($dhcp["interfaces"]["dmz"]["range_start"] ?? "", "192.168.1.50", $default_dmz_range_start);
$dhcp["interfaces"]["dmz"]["range_end"] = replace_legacy_ip($dhcp["interfaces"]["dmz"]["range_end"] ?? "", "192.168.1.200", $default_dmz_range_end);
$dhcp["interfaces"]["dmz"]["netmask"] = replace_legacy_ip($dhcp["interfaces"]["dmz"]["netmask"] ?? "", "255.255.255.0", cidr_netmask($dmz_mask));
$dhcp["options"]["gateway"] = ["lan" => $lan_gateway, "dmz" => $dmz_gateway];
$dhcp["options"]["dns"] = ["lan" => $lan_gateway, "dmz" => $dmz_gateway];
$wireguard["static_lan_ip"] = replace_legacy_ip(str_replace("/24", "", $wireguard["static_lan_ip"] ?? ""), "192.168.0.151", $default_wg_ip) . "/" . $lan_mask;
$wireguard["client_allowed_ips"] = replace_legacy_ip($wireguard["client_allowed_ips"] ?? "", "10.66.66.0/24,192.168.0.0/24", "10.66.66.0/24," . $lan_net);
$zabbix["server_ip"] = replace_legacy_ip($zabbix["server_ip"] ?? "", "192.168.0.151", $default_wg_ip);
$zabbix["discovery_network"] = replace_legacy_ip($zabbix["discovery_network"] ?? "", "192.168.0.0/24", $lan_net);
$restic["repository"] = "rest:http://" . replace_legacy_ip(parse_url(str_replace("rest:", "", $restic["repository"] ?? ""), PHP_URL_HOST) ?: "", "192.168.0.151", $default_wg_ip) . ":" . ($restic["port"] ?? 8000) . "/";
$restic["mysql"]["host"] = replace_legacy_ip($restic["mysql"]["host"] ?? "", "192.168.0.10", $default_web_ip);

// Mapping. Defaults match the lab, but every state follows targets[] from the form.
$minion_states = [];
foreach (accepted_minions() as $accepted_minion) {
    $minion_states[$accepted_minion] = [];
}

if (isset($selected["firewall"]) || isset($selected["dhcp"]) || isset($selected["proxy"])) { add_state($minion_states, $targets["firewall"], "firewall"); }
if (isset($selected["dns"])) { add_state($minion_states, $targets["dns"], "dns"); }
if (isset($selected["proxy"])) { add_state($minion_states, $targets["proxy"], "proxy"); }
if (isset($selected["BDD"])) { add_state($minion_states, $targets["BDD"], "BDD"); }
if (isset($selected["dhcp"])) { add_state($minion_states, $targets["dhcp"], "dhcp"); }
if (isset($selected["pkica"])) { add_state($minion_states, $targets["pkica"], "pkica"); }
if (isset($selected["wireguard"])) { add_state($minion_states, $targets["wireguard"], "wireguard"); }
if (isset($selected["webserver"])) { add_state($minion_states, $targets["webserver"], "webserver"); }
if (isset($selected["zabbix-server"])) { add_state($minion_states, $targets["zabbix-server"], "zabbix.server"); }
if (isset($selected["restic-server"])) { add_state($minion_states, $targets["restic-server"], "restic.server"); }

$active_service_minions = array_keys(array_filter($minion_states, fn($s) => !empty($s)));
if (isset($selected["zabbix-server"])) {
    foreach ($active_service_minions as $m) {
        add_state($minion_states, $m, "zabbix.agent");
    }
}
if (isset($selected["restic-server"])) {
    foreach ($active_service_minions as $m) {
        if ($m !== $targets["restic-server"]) {
            add_state($minion_states, $m, "restic.client");
        }
    }
}

$active_minions = array_filter($minion_states, fn($s) => !empty($s));

$master_ips = array_merge([
    "minion-02" => "192.168.0.3",
    "minion-04" => "192.168.0.3",
    "minion-05" => "192.168.0.3",
    "minion-08" => "192.168.0.3"
], minion_master_map());

$service_ip = [
    "webserver" => ip_host($lan_gateway, 10),
    "BDD" => ip_host($lan_gateway, 20),
    "dhcp" => ip_host($lan_gateway, 30),
    "dns" => ip_host($lan_gateway, 53),
    "pkica" => ip_host($lan_gateway, 40),
    "wireguard" => ip_host($lan_gateway, 151),
    "zabbix.server" => ip_host($lan_gateway, 152),
    "restic.server" => ip_host($lan_gateway, 153),
    "zabbix.agent" => ip_host($lan_gateway, 154),
    "restic.client" => ip_host($lan_gateway, 155),
];
$lan_priority = ["webserver", "BDD", "dhcp", "dns", "pkica", "wireguard", "zabbix.server", "restic.server", "zabbix.agent", "restic.client"];
$network_nodes = [];
foreach ($active_minions as $minion => $states_for_minion) {
    $master_ip = $master_ips[$minion] ?? "192.168.0.3";
    if (in_array("firewall", $states_for_minion, true)) {
        $network_nodes[$minion] = ["interfaces" => [
            ["ip" => $firewall["wan"]["ip"], "mask" => $firewall["wan"]["mask"], "gateway" => $firewall["wan"]["gateway"], "name" => $firewall["wan"]["interface"], "dns" => "8.8.8.8"],
            ["ip" => $firewall["lan"]["ip"], "mask" => $firewall["lan"]["mask"], "name" => $firewall["lan"]["interface"]],
            ["ip" => $firewall["dmz"]["ip"], "mask" => $firewall["dmz"]["mask"], "name" => $firewall["dmz"]["interface"]]
        ], "salt_master_ip" => $master_ip];
        continue;
    }

    $only_proxy = in_array("proxy", $states_for_minion, true) && count(array_diff($states_for_minion, ["proxy", "zabbix.agent", "restic.client"])) === 0;
    if ($only_proxy) {
        $network_nodes[$minion] = ["interfaces" => [[
            "ip" => $proxy["ip"],
            "mask" => $proxy["mask"],
            "gateway" => $dmz_gateway,
            "name" => $proxy["interface"],
            "dns" => "8.8.8.8"
        ]], "salt_master_ip" => $master_ip];
        continue;
    }

    $primary_state = first_matching_service($states_for_minion, $lan_priority);
    $network_nodes[$minion] = ["interfaces" => [[
        "ip" => $service_ip[$primary_state] ?? ip_host($lan_gateway, 200),
        "mask" => $lan_mask,
        "gateway" => $lan_gateway,
        "name" => $web["network"]["interface"] ?? "enp0s3",
        "dns" => "8.8.8.8"
    ]], "salt_master_ip" => $master_ip];
}

$bdd_ip = $network_nodes[$targets["BDD"]]["interfaces"][0]["ip"] ?? "127.0.0.1";
$wordpress_db_host = "127.0.0.1";
$target_ip = function($service) use ($targets, $network_nodes, $firewall) {
    $minion = $targets[$service] ?? null;
    if ($minion === "minion-05") {
        return $firewall["lan"]["ip"];
    }
    return $network_nodes[$minion]["interfaces"][0]["ip"] ?? "127.0.0.1";
};

$web["network"]["address"] = $target_ip("webserver");
$dhcp["server_ip"] = $target_ip("dhcp");
$proxy["ip"] = $target_ip("proxy");
$wireguard["static_lan_ip"] = $target_ip("wireguard") . "/24";
$wireguard["client_web_ip"] = isset($selected["webserver"]) ? $target_ip("webserver") : "192.168.0.10";
$zabbix["server_ip"] = $target_ip("zabbix-server");
$zabbix["db_host"] = $bdd_ip;
$restic["repository"] = "rest:http://" . $target_ip("restic-server") . ":" . $restic["port"] . "/";
$restic["mysql"]["host"] = $bdd_ip;

$main = [
    "enabled_services" => $enabled_services,
    "firewall" => $firewall,
    "service_targets" => $targets,
    "service_mapping" => $active_minions,
    "network_nodes" => $network_nodes
];

// Conditionally add blocks to $main ONLY if selected
if (isset($selected["proxy"])) { $main["proxy"] = $proxy; }
if (isset($selected["dns"])) {
    $main["dns"] = ["recursion" => true, "allow_query" => "127.0.0.1; localhost; " . $lan_net . "; " . $dmz_net . "; " . $wan_net . "; 10.66.66.0/24", "forwarders" => ["8.8.8.8"]];
}
if (isset($selected["webserver"])) {
    $main["web-server"] = $web;
    $main["mysql"] = $mysql;
    $main["wordpress"] = deep_merge_array(["db_name" => "wordpress", "db_user" => "wpuser", "db_pass" => "Wp@2026!", "db_host" => $wordpress_db_host, "title" => "Lab SaltStack", "admin_user" => "admin", "admin_pass" => "Admin@2026!", "admin_email" => "admin@server.es", "site_url" => "http://" . $firewall["wan"]["ip"]], $wordpress_post);
    $main["wordpress"]["db_host"] = $wordpress_db_host;
}
if (isset($selected["dhcp"])) { $main["dhcp"] = $dhcp; }
if (isset($selected["pkica"])) { $main["pkica"] = $pkica; }
if (isset($selected["wireguard"])) { $main["wireguard"] = $wireguard; }
if (isset($selected["BDD"])) { $main["mysql"] = $mysql; }
if (isset($selected["zabbix-server"])) { $main["zabbix"] = $zabbix; }
if (isset($selected["restic-server"])) { $main["restic"] = $restic; }

$base_dir = "/srv/pillar/customers/" . $company;
if (!is_dir($base_dir)) mkdir($base_dir, 0755, true);
write_yaml_file($base_dir . "/main.sls", $main);

$pillar_top = ["base" => []];
foreach (array_keys($active_minions) as $m) $pillar_top["base"][$m] = ["customers.$company.main"];
write_yaml_file("/srv/pillar/top.sls", $pillar_top);

$salt_top = ["base" => ["*" => ["common"]]];
foreach ($active_minions as $m => $mstates) $salt_top["base"][$m] = $mstates;
write_yaml_file("/srv/salt/top.sls", $salt_top);
$main_yaml    = file_get_contents($base_dir . "/main.sls");
$pillar_top_yaml = file_get_contents("/srv/pillar/top.sls");
$salt_top_yaml   = file_get_contents("/srv/salt/top.sls");
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Configuración Generada</title>
    <style>
        body { font-family: sans-serif; background: #0f172a; color: #f8fafc; padding: 20px; }
        pre { background: #0b1220; padding: 15px; border-radius: 8px; border: 1px solid #334155; overflow: auto; font-size: 13px; }
        .card { max-width: 900px; margin: auto; background: #111827; padding: 24px; border-radius: 12px; }
        h1 { color: #38bdf8; margin-bottom: 4px; }
        h3 { color: #7dd3fc; margin: 20px 0 6px; }
        p  { color: #94a3b8; margin-top: 0; }
        .btn { display: inline-block; padding: 10px 20px; background: #38bdf8; color: #082f49; text-decoration: none; border-radius: 6px; font-weight: bold; margin-top: 20px; }
        .badge { display: inline-block; background: #1e3a5f; color: #7dd3fc; border-radius: 4px; padding: 2px 8px; font-size: 12px; margin-left: 8px; vertical-align: middle; }
    </style>
</head>
<body>
<div class="card">
    <h1>✓ Configuración Generada</h1>
    <p>Archivos generados y escritos en el Salt Master.</p>

    <h3>Pillar: <code>customers/<?php echo htmlspecialchars($company); ?>/main.sls</code> <span class="badge"><?php echo count($active_minions); ?> minions</span></h3>
    <pre><?php echo htmlspecialchars($main_yaml); ?></pre>

    <h3>Pillar Top: <code>/srv/pillar/top.sls</code></h3>
    <pre><?php echo htmlspecialchars($pillar_top_yaml); ?></pre>

    <h3>Salt Top: <code>/srv/salt/top.sls</code></h3>
    <pre><?php echo htmlspecialchars($salt_top_yaml); ?></pre>

    <a href="index.php" class="btn">Volver</a>
</div>
</body>
</html>
