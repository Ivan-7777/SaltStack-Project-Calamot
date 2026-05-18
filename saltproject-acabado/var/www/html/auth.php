<?php
// Configuración de sesión segura
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);
// ini_set('session.cookie_secure', 1); // Activar si usas HTTPS

session_start();

// Usuarios con contraseñas hasheadas (Usando password_hash)
// admin: alumnat
// profesores: aso_2023_profes
// aitor: password
$USERS = [
    "admin" => "",
    "aitor" => "",
    "alex" => "",
    "maria" => "",
    "jordi" => ""
];

// Generar hashes reales para el entorno
$USERS["admin"] = password_hash("alumnat", PASSWORD_DEFAULT);
$USERS["aitor"] = password_hash("password", PASSWORD_DEFAULT);
$USERS["alex"] = password_hash("tribunal872", PASSWORD_DEFAULT);
$USERS["maria"] = password_hash("tribunal195", PASSWORD_DEFAULT);
$USERS["jordi"] = password_hash("tribunal213", PASSWORD_DEFAULT);

function check_auth() {
    if (!isset($_SESSION["authenticated"]) || $_SESSION["authenticated"] !== true) {
        header("Location: login.php");
        exit;
    }
    
    // Verificar IP para prevenir secuestro de sesión básico
    if (!isset($_SESSION["user_ip"]) || $_SESSION["user_ip"] !== $_SERVER['REMOTE_ADDR']) {
        session_destroy();
        header("Location: login.php");
        exit;
    }
}

function handle_logout() {
    if (isset($_GET["logout"])) {
        session_destroy();
        header("Location: login.php");
        exit;
    }
}

function generate_csrf_token() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verify_csrf_token($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

function log_action($message) {
    $log_file = "/var/log/salt_web_form.log";
    $timestamp = date("Y-m-d H:i:s");
    $user = $_SESSION["username"] ?? "unknown";
    $ip = $_SERVER['REMOTE_ADDR'];
    $entry = "[$timestamp] [USER: $user] [IP: $ip] $message\n";
    @file_put_contents($log_file, $entry, FILE_APPEND);
}
?>
