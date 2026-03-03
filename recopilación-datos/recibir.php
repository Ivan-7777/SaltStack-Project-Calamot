<?php
// Función para convertir array PHP a YAML simple
function array_to_yaml($array, $indent = 0) {
    $yaml = '';
    foreach ($array as $key => $value) {
        $spaces = str_repeat('  ', $indent);
        if (is_array($value)) {
            $yaml .= "$spaces$key:\n";
            $yaml .= array_to_yaml($value, $indent + 1);
        } else {
            if ($value === true) $value = 'true';
            if ($value === false) $value = 'false';
            $yaml .= "$spaces$key: $value\n";
        }
    }
    return $yaml;
}

// Datos recibidos
$data = $_POST;

// Nombre de empresa
if (empty($data['company'])) die("Debe introducir nombre de empresa.");
$company = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['company']);

// Servicios seleccionados
$services = $data['services'] ?? [];
$pillar = [];

// WireGuard
if (in_array('wireguard', $services)) {
    $pillar['wireguard'] = $data['wireguard'];
}

// Firewall
if (in_array('firewall', $services)) {
    $pillar['firewall'] = $data['firewall'];
}

// DHCP
if (in_array('dhcp', $services)) {
    $pillar['dhcp'] = $data['dhcp'];

    // Convertir gateways y dns a array
    $pillar['dhcp']['options']['gateway'] = array_map('trim', explode(',', $pillar['dhcp']['options']['gateway']));
    $pillar['dhcp']['options']['dns'] = array_map('trim', explode(',', $pillar['dhcp']['options']['dns']));
}

// Guardar en SLS
$pillar_dir = "/srv/pillar/customers";
if (!is_dir($pillar_dir)) mkdir($pillar_dir, 0755, true);

$pillar_file = "$pillar_dir/{$company}.sls";
file_put_contents($pillar_file, array_to_yaml($pillar));
chmod($pillar_file, 0644);

echo "<h2>Pillar guardado en customers/{$company}.sls</h2>";
echo "<pre>" . array_to_yaml($pillar) . "</pre>";
?>
