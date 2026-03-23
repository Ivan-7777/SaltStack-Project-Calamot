<?php

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    die("Acceso no permitido");
}

$empresa = trim($_POST['company'] ?? '');

if (empty($empresa)) {
    die("Nombre de empresa inválido");
}

// Sanitizar nombre carpeta
$empresa = preg_replace('/[^a-zA-Z0-9_-]/', '_', $empresa);

$services = $_POST['services'] ?? [];

$base_dir = "/srv/pillar/customers/$empresa";

// Crear directorio si no existe
if (!is_dir($base_dir)) {
    mkdir($base_dir, 0755, true);
}

// Función para guardar YAML manual (evitamos yaml_emit por compatibilidad)
function save_yaml($file, $array) {
    $yaml = yaml_encode($array);
    file_put_contents($file, $yaml);
}

// Encoder simple YAML (compatible con tu estructura)
function yaml_encode($data, $indent = 0) {
    $yaml = '';
    foreach ($data as $key => $value) {
        $spaces = str_repeat("  ", $indent);

        if (is_array($value)) {
            $yaml .= "{$spaces}{$key}:\n";
            $yaml .= yaml_encode($value, $indent + 1);
        } else {
            // boolean
            if ($value === "true") $value = "true";
            if ($value === "false") $value = "false";

            $yaml .= "{$spaces}{$key}: {$value}\n";
        }
    }
    return $yaml;
}

//////////////////////////////
// GENERACIÓN POR SERVICIO
//////////////////////////////

// 🔹 WIREGUARD
if (in_array("wireguard", $services) && isset($_POST['wireguard'])) {

    $data = [
        "wireguard" => $_POST['wireguard']
    ];

    save_yaml("$base_dir/wireguard.sls", $data);
}

// 🔹 FIREWALL
if (in_array("firewall", $services) && isset($_POST['firewall'])) {

    $data = [
        "firewall" => $_POST['firewall']
    ];

    save_yaml("$base_dir/firewall.sls", $data);
}

// 🔹 DHCP
if (in_array("dhcp", $services) && isset($_POST['dhcp'])) {

    $data = [
        "dhcp" => $_POST['dhcp']
    ];

    save_yaml("$base_dir/dhcp.sls", $data);
}

// 🔹 WEB SERVER
if (in_array("web", $services) && isset($_POST['web-server'])) {

    $data = [
        "web-server" => $_POST['web-server']
    ];

    save_yaml("$base_dir/web-server.sls", $data);
}

// 🔹 PKI CA
if (in_array("pkica", $services) && isset($_POST['pkica'])) {

    $data = [
        "pkica" => $_POST['pkica']
    ];

    save_yaml("$base_dir/pkica.sls", $data);
}

// 🔹 DNS
if (in_array("dns", $services) && isset($_POST['dns'])) {

    $data = [
        "dns" => $_POST['dns']
    ];

    save_yaml("$base_dir/dns.sls", $data);
}

//////////////////////////////
// GENERAR TOP.SLS
//////////////////////////////

$top = "base:\n  '*':\n";

$map = [
    "web" => "web-server"
];

foreach ($services as $s) {
    $name = $map[$s] ?? $s;
    $top .= "    - customers.$empresa.$name\n";
}

file_put_contents("$base_dir/top.sls", $top);

//////////////////////////////

echo "Configuración guardada correctamente para la empresa: $empresa";

?>
