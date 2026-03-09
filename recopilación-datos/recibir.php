<?php
// Asegurarnos de que recibimos una petición POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die('Método no permitido.');
}

// 1. Sanitizar el nombre de la empresa para usarlo como nombre de archivo seguro
$companyRaw = $_POST['company'] ?? 'default_company';
// Reemplaza espacios y caracteres raros por guiones bajos
$companySafe = preg_replace('/[^a-zA-Z0-9_-]/', '_', strtolower(trim($companyRaw)));

if (empty($companySafe)) {
    die('El nombre de la empresa no es válido.');
}

// 2. Estructurar los datos
$services = $_POST['services'] ?? [];
$pillar = [];

// Información base
$pillar['empresa'] = $companyRaw;
$pillar['servicios_activos'] = $services;

// Procesar WireGuard (solo si fue seleccionado)
if (in_array('wireguard', $services) && isset($_POST['wireguard'])) {
    $pillar['wireguard'] = $_POST['wireguard'];
    // Forzar el puerto a número entero
    $pillar['wireguard']['port'] = (int)$pillar['wireguard']['port'];
}

// Procesar Firewall (solo si fue seleccionado)
if (in_array('firewall', $services) && isset($_POST['firewall'])) {
    $pillar['firewall'] = $_POST['firewall'];
}

// Procesar DHCP (solo si fue seleccionado)
if (in_array('dhcp', $services) && isset($_POST['dhcp'])) {
    $dhcp = $_POST['dhcp'];
   
    // Los checkboxes HTML no se envían si no están marcados
    $dhcp['log'] = isset($dhcp['log']) ? true : false;
   
    // Convertir los strings separados por coma en listas (arrays) para YAML
    if (!empty($dhcp['options']['gateway'])) {
        $dhcp['options']['gateway'] = array_map('trim', explode(',', $dhcp['options']['gateway']));
    }
    if (!empty($dhcp['options']['dns'])) {
        $dhcp['options']['dns'] = array_map('trim', explode(',', $dhcp['options']['dns']));
    }
   
    $pillar['dhcp'] = $dhcp;
}

// 3. Función para convertir Array de PHP a formato YAML
function arrayToYaml($data, $indent = 0) {
    $yaml = '';
    $prefix = str_repeat('  ', $indent);
   
    foreach ($data as $key => $value) {
        if (is_array($value)) {
            // Detectar si es una lista (índices numéricos secuenciales) o un diccionario
            $isList = array_keys($value) === range(0, count($value) - 1);
           
            if ($isList) {
                $yaml .= $prefix . $key . ":\n";
                foreach ($value as $item) {
                    $yaml .= $prefix . "  - " . $item . "\n";
                }
            } else {
                $yaml .= $prefix . $key . ":\n";
                $yaml .= arrayToYaml($value, $indent + 1);
            }
        } else {
            // Manejar booleanos para YAML
            if (is_bool($value)) {
                $valStr = $value ? 'true' : 'false';
            } else {
                $valStr = $value;
            }
            $yaml .= $prefix . $key . ': ' . $valStr . "\n";
        }
    }
    return $yaml;
}

// 4. Generar el contenido y guardar el archivo
$yamlContent = arrayToYaml($pillar);

$directory = '/srv/pillar/customers';
$filepath = $directory . '/' . $companySafe . '.sls';

// Intentar guardar el archivo
if (file_put_contents($filepath, $yamlContent) !== false) {
    echo "<h2>¡Configuración guardada con éxito!</h2>";
    echo "<p>Archivo creado: <code>$filepath</code></p>";
    echo "<h3>Contenido del Pillar:</h3>";
    echo "<pre style='background:#f4f4f4; padding:15px; border-radius:5px; max-width: 700px;'>" . htmlspecialchars($yamlContent) . "</pre>";
    echo "<br><a href='javascript:history.back()'>Volver al formulario</a>";
} else {
    echo "<h2>Error al guardar</h2>";
    echo "<p>No se pudo escribir en <code>$filepath</code>. Por favor, verifica los permisos del directorio.</p>";
}
?>
