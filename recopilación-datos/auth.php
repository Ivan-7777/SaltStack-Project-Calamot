<?php
session_start();

// Configuración de usuarios del generador
$USERS = [
    'admin' => 'alumnat',              // Usuario administrador (sin cooldown)
    'profesores' => 'aso_2023_profes', // Usuario cliente (con cooldown)
    'aitor' => 'password'
];

function check_auth() {
    if (!isset($_SESSION['authenticated']) || $_SESSION['authenticated'] !== true) {
        header('Location: login.php');
        exit;
    }
}

function handle_logout() {
    if (isset($_GET['logout'])) {
        session_destroy();
        header('Location: login.php');
        exit;
    }
}
?>
