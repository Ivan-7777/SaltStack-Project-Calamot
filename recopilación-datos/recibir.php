<?php
require_once 'auth.php';
check_auth();

// CONFIGURACIÓN COOLDOWN (Segundos)
$COOLDOWN = 60;
$user = $_SESSION['username'];
$cooldown_file = "/tmp/salt_cooldown_" . md5($user) . ".txt";

// Comprobar Cooldown si no es admin
if ($user !== 'admin') {
    if (file_exists($cooldown_file)) {
        $last_time = (int)file_get_contents($cooldown_file);
        $diff = time() - $last_time;
        if ($diff < $COOLDOWN) {
            $wait = $COOLDOWN - $diff;
            die("<h1>Control de Flujo Activo</h1><p>Por favor, espera <b>$wait segundos</b> antes de generar otra configuración.</p><br><a href='index.php'>Volver</a>");
        }
    }
}

// ------------------------------------------
// LÓGICA DE GENERACIÓN (Mismo que antes)
// ------------------------------------------

if ($_SERVER['REQUEST_METHOD'] !== 'POST') die('POST requerido.');

$companyRaw = $_POST['company'] ?? '';
$companySafe = preg_replace('/[^a-zA-Z0-9_-]/', '_', strtolower(trim($companyRaw)));
if (empty($companySafe)) die('ID empresa inválido.');

$services = $_POST['services'] ?? [];
$pillar = [];
$allowedServices = ['wireguard', 'firewall', 'dhcp', 'web', 'pkica', 'dns'];

foreach ($allowedServices as $srv) {
    if (in_array($srv, $services)) {
        $postKey = ($srv === 'web') ? 'web-server' : $srv;
        if (isset($_POST[$postKey])) {
            $data = $_POST[$postKey];
            // Sanitización básica de tipos (int)
            if (isset($data['port'])) $data['port'] = (int)$data['port'];
            if (isset($data['mask'])) $data['mask'] = (int)$data['mask'];
            $pillar[$postKey] = $data;
        }
    }
}

function arrayToYaml($data, $indent = 0) {
    $yaml = '';
    $prefix = str_repeat('  ', $indent);
    foreach ($data as $key => $value) {
        if (is_array($value)) {
            $yaml .= $prefix . $key . ":\n";
            $yaml .= arrayToYaml($value, $indent + 1);
        } else {
            $valStr = is_bool($value) ? ($value ? 'true' : 'false') : $value;
            $yaml .= $prefix . $key . ': ' . $valStr . "\n";
        }
    }
    return $yaml;
}

$yamlContent = arrayToYaml($pillar);
$directory = '/srv/pillar/customers/' . $companySafe;
if (!is_dir($directory)) @mkdir($directory, 0755, true);

$filepath = $directory . '/main.sls';
$written = @file_put_contents($filepath, $yamlContent);

if ($written !== false) {
    // Registrar tiempo si no es admin
    if ($user !== 'admin') file_put_contents($cooldown_file, time());
}

?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Pilar Generado</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;600;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Outfit', sans-serif; background: #0f172a; color: white; display: flex; justify-content: center; align-items: center; min-height: 100vh; flex-direction: column; }
        .card { background: rgba(255,255,255,0.05); padding: 40px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.1); max-width: 800px; width: 90%; }
        pre { background: #000; padding: 20px; border-radius: 10px; overflow-x: auto; color: #38bdf8; font-size: 0.9rem; }
        .success { color: #10b981; }
        .btn { display: inline-block; margin-top: 20px; padding: 12px 25px; background: #38bdf8; color: #0f172a; text-decoration: none; border-radius: 8px; font-weight: 600; }
    </style>
</head>
<body>
    <div class="card">
        <?php if ($written): ?>
            <h1 class="success">Pilar Construido con Éxito</h1>
            <p>Ruta: <code><?php echo $filepath; ?></code></p>
            <pre><?php echo htmlspecialchars($yamlContent); ?></pre>
        <?php else: ?>
            <h1 style="color:#ef4444">Error al Guardar</h1>
            <p>Verifica los permisos en <code>/srv/pillar/customers/</code></p>
        <?php endif; ?>
        <a href="index.php" class="btn">Volver al Dashboard</a>
    </div>
</body>
</html>
