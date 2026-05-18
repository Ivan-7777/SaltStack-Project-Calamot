<?php
require_once "auth.php";

if (isset($_SESSION["authenticated"]) && $_SESSION["authenticated"] === true) {
    header("Location: index.php");
    exit;
}

$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $user = $_POST["username"] ?? "";
    $pass = $_POST["password"] ?? "";
    
    if (isset($USERS[$user]) && password_verify($pass, $USERS[$user])) {
        session_regenerate_id(true); // Prevenir fijación de sesión
        $_SESSION["authenticated"] = true;
        $_SESSION["username"] = $user;
        $_SESSION["user_ip"] = $_SERVER['REMOTE_ADDR'];
        log_action("Login exitoso");
        header("Location: index.php");
        exit;
    }
    log_action("Fallo de login para usuario: $user");
    $error = "Credenciales inválidas.";
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Seguro - Salt</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .card { width: min(420px, 92vw); background: #111827; border: 1px solid #334155; border-radius: 16px; padding: 28px; box-shadow: 0 20px 50px rgba(0,0,0,.35); }
        h1 { margin: 0 0 18px; font-size: 1.6rem; text-align: center; }
        label { display: block; margin: 12px 0 6px; color: #cbd5e1; }
        input { width: 100%; box-sizing: border-box; padding: 12px; border-radius: 10px; border: 1px solid #475569; background: #0b1220; color: #fff; }
        button { margin-top: 24px; width: 100%; padding: 12px; border: none; border-radius: 10px; background: #38bdf8; color: #082f49; font-weight: 700; cursor: pointer; transition: background 0.2s; }
        button:hover { background: #7dd3fc; }
        .err { color: #f87171; background: rgba(248, 113, 113, 0.1); padding: 10px; border-radius: 8px; text-align: center; font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Formularios Salt</h1>
        <?php if ($error): ?>
            <p class="err"><?php echo htmlspecialchars($error); ?></p>
        <?php endif; ?>
        <form method="POST">
            <label>Usuario</label>
            <input type="text" name="username" required autofocus autocomplete="username">
            <label>Contraseña</label>
            <input type="password" name="password" required autocomplete="current-password">
            <button type="submit">Iniciar Sesión</button>
        </form>
    </div>
</body>
</html>
