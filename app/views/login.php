<?php
$tab = ($_GET['tab'] ?? 'login') === 'register' ? 'register' : 'login';
?><!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title><?= $tab === 'register' ? 'Crear cuenta' : 'Iniciar sesion' ?> · RutaGestion</title>
    <link rel="stylesheet" href="assets/css/app.css">
</head>
<body class="login-body">
<div class="login-wrap">
    <section class="login-art">
        <div class="art-brand"><span class="brand-icon">R</span> RutaGestion</div>
        <div class="art-copy">
            <span class="eyebrow">PLATAFORMA DE OPERACIONES</span>
            <h1>Conectamos<br>personas y<br><em>regiones.</em></h1>
            <p>Administra flotas, viajes, pasajeros y operaciones desde un solo lugar.</p>
        </div>
        <div class="art-footer">GESTION INTELIGENTE · TRANSPORTE REGIONAL</div>
    </section>
    <section class="login-panel">
        <div class="login-form">
            <div class="login-tabs">
                <a class="<?= $tab === 'login' ? 'active' : '' ?>" href="?page=login">Iniciar sesion</a>
                <a class="<?= $tab === 'register' ? 'active' : '' ?>" href="?page=login&amp;tab=register">Crear cuenta</a>
            </div>
            <?php foreach (auth_take_flash() as $flash): ?>
                <div class="alert <?= h($flash['type']) ?>"><?= h($flash['message']) ?></div>
            <?php endforeach; ?>

            <?php if ($tab === 'login'): ?>
                <span class="eyebrow">BIENVENIDO DE VUELTA</span>
                <h2>Iniciar sesion</h2>
                <p>Ingresa tus credenciales para continuar.</p>
                <form method="post" action="?page=login">
                    <input type="hidden" name="action" value="login">
                    <label>Nombre de usuario
                        <input name="username" required autocomplete="username" placeholder="Ej. admin" value="<?= h(old_value('username')) ?>">
                    </label>
                    <label>Contrasena
                        <span class="password-field">
                            <input type="password" name="password" required autocomplete="current-password" placeholder="Tu contrasena" data-password>
                            <button type="button" class="toggle-pass" data-toggle-password>Mostrar</button>
                        </span>
                    </label>
                    <button class="btn primary full">Ingresar al sistema <span>→</span></button>
                </form>
                <div class="login-note">Acceso protegido mediante usuarios y roles de Oracle.</div>
            <?php else: ?>
                <span class="eyebrow">REGISTRO PUBLICO</span>
                <h2>Crear cuenta</h2>
                <p>El registro publico crea siempre una cuenta con rol VENDEDOR.</p>
                <form method="post" action="?page=login&amp;tab=register">
                    <input type="hidden" name="action" value="register">
                    <label>Nombre completo
                        <input name="nombre_completo" required autocomplete="name" value="<?= h(old_value('nombre_completo')) ?>">
                    </label>
                    <label>Nombre de usuario
                        <input name="username" required autocomplete="username" value="<?= h(old_value('username')) ?>">
                    </label>
                    <label>Correo electronico
                        <input type="email" name="email" required autocomplete="email" value="<?= h(old_value('email')) ?>">
                    </label>
                    <label>Contrasena
                        <span class="password-field">
                            <input type="password" name="password" required autocomplete="new-password" data-password>
                            <button type="button" class="toggle-pass" data-toggle-password>Mostrar</button>
                        </span>
                    </label>
                    <label>Repetir contrasena
                        <span class="password-field">
                            <input type="password" name="password_confirm" required autocomplete="new-password" data-password>
                            <button type="button" class="toggle-pass" data-toggle-password>Mostrar</button>
                        </span>
                    </label>
                    <button class="btn primary full">Crear cuenta <span>→</span></button>
                </form>
                <div class="login-note">La politica de contrasenas y los permisos se validan en Oracle.</div>
            <?php endif; ?>
        </div>
    </section>
</div>
<script src="assets/js/app.js"></script>
</body>
</html>
