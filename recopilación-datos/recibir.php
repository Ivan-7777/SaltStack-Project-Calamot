<?php
// Función para convertir array PHP a YAML
function array_to_yaml($array, $indent = 0) {
    $yaml = '';
    foreach ($array as $key => $value) {
        $spaces = str_repeat('  ', $indent);
        if (is_array($value)) {
            $yaml .= "$spaces$key:\n";
            $yaml .= array_to_yaml($value, $indent + 1);
        } else {
            $yaml .= "$spaces$key: $value\n";
        }
    }
    return $yaml;
}

// --------------------------
// 1. Recoger datos del formulario
// --------------------------
$empresa = trim($_POST['empresa'] ?? '');
$services = $_POST['services'] ?? [];
$wireguard_data = $_POST['wireguard'] ?? [];
$firewall_data = $_POST['firewall'] ?? [];

if ($empresa === '') {
    die("Debe introducir el nombre de la empresa.");
}

// Limpiar nombre para archivo
$empresa_file = preg_replace('/[^a-zA-Z0-9_\-]/', '_', strtolower($empresa));

// --------------------------
// 2. Preparar contenido SLS
// --------------------------
$pillar_data = [];

if (in_array('wireguard', $services)) {
    $pillar_data['wireguard'] = [
        'port' => $wireguard_data['port'] ?? 51820,
        'address' => $wireguard_data['address'] ?? '',
        'static_lan_ip' => $wireguard_data['static_lan_ip'] ?? '',
        'wan_interface' => $wireguard_data['wan_interface'] ?? '',
    ];
}

if (in_array('firewall', $services)) {
    $pillar_data['firewall'] = [
        'wan' => [
            'ip' => $firewall_data['wan_ip'] ?? '',
            'mask' => $firewall_data['wan_mask'] ?? '',
            'gateway' => $firewall_data['wan_gateway'] ?? '',
            'interface' => $firewall_data['wan_interface'] ?? '',
        ],
        'lan' => [
            'ip' => $firewall_data['lan_ip'] ?? '',
            'mask' => $firewall_data['lan_mask'] ?? '',
            'interface' => $firewall_data['lan_interface'] ?? '',
        ],
        'dmz' => [
            'ip' => $firewall_data['dmz_ip'] ?? '',
            'mask' => $firewall_data['dmz_mask'] ?? '',
            'interface' => $firewall_data['dmz_interface'] ?? '',
        ],
    ];
}

// --------------------------
// 3. Guardar en archivo SLS
// --------------------------
$pillar_dir = '/srv/pillar/customers';
if (!is_dir($pillar_dir)) mkdir($pillar_dir, 0755, true);

$sls_path = "$pillar_dir/{$empresa_file}.sls";
$yaml_content = array_to_yaml($pillar_data);

if (file_put_contents($sls_path, $yaml_content) === false) {
    die("Error al guardar el archivo pillar.");
}
chmod($sls_path, 0644);

// --------------------------
// 4. Mensaje de éxito
// --------------------------
echo "<h2>Datos recibidos y guardados en pillar/{$empresa_file}.sls</h2>";
echo "<pre>" . htmlspecialchars($yaml_content) . "</pre>";
