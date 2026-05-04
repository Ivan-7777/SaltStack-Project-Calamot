<?php
require_once 'auth.php';

if (isset($_SESSION['authenticated']) && $_SESSION['authenticated'] === true) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user = $_POST['username'] ?? '';
    $pass = $_POST['password'] ?? '';

    if (isset($USERS[$user]) && $USERS[$user] === $pass) {
        $_SESSION['authenticated'] = true;
        $_SESSION['username'] = $user;
        header('Location: index.php');
        exit;
    } else {
        $error = 'Credenciales inválidas.';
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Login - SaltStack Hub</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;600;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%);
            --accent: #38bdf8;
            --text: #f8fafc;
        }
        body {
            font-family: 'Outfit', sans-serif;
            background: var(--bg);
            color: var(--text);
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }
        .login-card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 24px;
            width: 100%;
            max-width: 400px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.5);
            text-align: center;
        }
        h1 { margin-bottom: 30px; font-weight: 800; font-size: 2rem; color: var(--accent); }
        .form-group { text-align: left; margin-bottom: 20px; }
        label { display: block; margin-bottom: 8px; color: #94a3b8; font-size: 0.9rem; }
        input {
            width: 100%;
            padding: 12px 15px;
            background: rgba(0,0,0,0.2);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 10px;
            color: white;
            box-sizing: border-box;
            font-family: inherit;
        }
        input:focus { outline: none; border-color: var(--accent); }
        button {
            width: 100%;
            padding: 14px;
            background: var(--accent);
            border: none;
            border-radius: 10px;
            color: #0f172a;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 10px;
        }
        button:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(56, 189, 248, 0.4); }
        .error { color: #ef4444; margin-bottom: 20px; font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="login-card">
        <h1>SaltStack Hub</h1>
        <?php if ($error): ?><div class="error"><?php echo $error; ?></div><?php endif; ?>
        <form method="POST">
            <div class="form-group">
                <label>Usuario</label>
                <input type="text" name="username" required autofocus>
            </div>
            <div class="form-group">
                <label>Contraseña</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit">Iniciar Sesión</button>
        </form>
    </div>
</body>
</html>
