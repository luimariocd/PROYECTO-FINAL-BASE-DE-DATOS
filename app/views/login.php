<?php
$tab = ($_GET['tab'] ?? 'login') === 'register' ? 'register' : 'login';
?><!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light dark">
    <title><?= $tab === 'register' ? 'Crear cuenta' : 'Iniciar sesion' ?> · RutaGestion</title>
    <script>
        (() => {
            'use strict';
            const root = document.documentElement;
            if (root.getAttribute('data-lte-color-mode') === 'off') return;
            const STORAGE_KEY = 'lte-theme';
            let stored = null;
            try { stored = localStorage.getItem(STORAGE_KEY); } catch (e) {}
            const authored = root.getAttribute('data-bs-theme');
            let resolved = 'light';
            if (stored === 'dark' || stored === 'light') {
                resolved = stored;
            } else if (authored === 'dark' || authored === 'light') {
                resolved = authored;
            } else if (globalThis.matchMedia('(prefers-color-scheme: dark)').matches) {
                resolved = 'dark';
            }
            root.setAttribute('data-bs-theme', resolved);
            root.style.colorScheme = resolved;
            if (resolved !== authored) root.setAttribute('data-lte-theme-resolved', '');
        })();
    </script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.2/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="adminlte/css/adminlte.min.css">
    <link rel="stylesheet" href="assets/css/app.css">
</head>
<body class="login-page">
<div class="login-theme-switch" aria-label="Cambiar tema">
    <button type="button" class="btn btn-sm btn-light border" data-bs-theme-value="light" title="Tema claro"><i class="bi bi-sun"></i></button>
    <button type="button" class="btn btn-sm btn-light border" data-bs-theme-value="dark" title="Tema oscuro"><i class="bi bi-moon"></i></button>
    <button type="button" class="btn btn-sm btn-light border" data-bs-theme-value="auto" title="Tema automatico"><i class="bi bi-circle-half"></i></button>
</div>
<main class="login-box">
    <div class="login-logo">
        <a href="?page=login"><span class="login-brand-icon"><i class="bi bi-bus-front-fill"></i></span><span><b>Ruta</b>Gestion<small>Transporte regional</small></span></a>
    </div>
    <div class="card card-outline card-primary login-card">
        <div class="card-header text-center">
            <div class="login-shield"><i class="bi bi-shield-lock"></i></div>
            <span class="h5 mb-0 d-block"><?= $tab === 'register' ? 'Crea tu cuenta' : 'Bienvenido de nuevo' ?></span>
            <span class="text-body-secondary small">Sistema LEHZ · Transporte Regional</span>
        </div>
        <div class="card-body login-card-body">
            <p class="login-box-msg"><?= $tab === 'register' ? 'Completa tus datos para operar el sistema.' : 'Ingresa tus credenciales para continuar.' ?></p>

            <ul class="nav nav-pills nav-fill mb-3">
                <li class="nav-item">
                    <a class="nav-link <?= $tab === 'login' ? 'active' : '' ?>" href="?page=login">Iniciar sesion</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $tab === 'register' ? 'active' : '' ?>" href="?page=login&amp;tab=register">Crear cuenta</a>
                </li>
            </ul>

            <?php foreach (auth_take_flash() as $flash): ?>
                <div class="alert alert-<?= $flash['type'] === 'error' ? 'danger' : 'success' ?> alert-dismissible fade show" role="alert">
                    <i class="bi <?= $flash['type'] === 'error' ? 'bi-exclamation-triangle-fill' : 'bi-check-circle-fill' ?> me-2"></i>
                    <?= h($flash['message']) ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
                </div>
            <?php endforeach; ?>

            <?php if ($tab === 'login'): ?>
                <form method="post" action="?page=login">
                    <input type="hidden" name="action" value="login">
                    <label class="form-label" for="loginUsername">Nombre de usuario</label>
                    <div class="input-group mb-3">
                        <input id="loginUsername" class="form-control" name="username" required autocomplete="username" placeholder="Nombre de usuario" value="<?= h(old_value('username')) ?>">
                        <span class="input-group-text"><i class="bi bi-person"></i></span>
                    </div>
                    <label class="form-label" for="loginPassword">Contrasena</label>
                    <div class="input-group mb-3">
                        <input id="loginPassword" class="form-control" type="password" name="password" required autocomplete="current-password" placeholder="Contrasena" data-password>
                        <button class="btn btn-outline-secondary" type="button" data-toggle-password>Mostrar</button>
                    </div>
                    <div class="d-grid">
                        <button class="btn btn-primary" type="submit">Ingresar al sistema <i class="bi bi-arrow-right ms-1"></i></button>
                    </div>
                </form>
                <div class="login-social mt-3">Acceso seguro</div>
                <div class="login-note"><i class="bi bi-lock-fill me-1"></i>Acceso protegido mediante usuarios y roles de Oracle.</div>
            <?php else: ?>
                <form method="post" action="?page=login&amp;tab=register">
                    <input type="hidden" name="action" value="register">
                    <label class="form-label" for="regName">Nombre completo</label>
                    <div class="input-group mb-3">
                        <input id="regName" class="form-control" name="nombre_completo" required autocomplete="name" placeholder="Nombre completo" value="<?= h(old_value('nombre_completo')) ?>">
                        <span class="input-group-text"><i class="bi bi-person-vcard"></i></span>
                    </div>
                    <label class="form-label" for="regUsername">Nombre de usuario</label>
                    <div class="input-group mb-3">
                        <input id="regUsername" class="form-control" name="username" required autocomplete="username" placeholder="Nombre de usuario" value="<?= h(old_value('username')) ?>">
                        <span class="input-group-text"><i class="bi bi-at"></i></span>
                    </div>
                    <label class="form-label" for="regEmail">Correo electronico</label>
                    <div class="input-group mb-3">
                        <input id="regEmail" class="form-control" type="email" name="email" required autocomplete="email" placeholder="Correo electronico" value="<?= h(old_value('email')) ?>">
                        <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    </div>
                    <label class="form-label" for="regPassword">Contrasena</label>
                    <div class="input-group mb-3">
                        <input id="regPassword" class="form-control" type="password" name="password" required autocomplete="new-password" placeholder="Contrasena" data-password>
                        <button class="btn btn-outline-secondary" type="button" data-toggle-password>Mostrar</button>
                    </div>
                    <label class="form-label" for="regPasswordConfirm">Repetir contrasena</label>
                    <div class="input-group mb-3">
                        <input id="regPasswordConfirm" class="form-control" type="password" name="password_confirm" required autocomplete="new-password" placeholder="Repetir contrasena" data-password>
                        <button class="btn btn-outline-secondary" type="button" data-toggle-password>Mostrar</button>
                    </div>
                    <div class="d-grid">
                        <button class="btn btn-primary" type="submit">Crear cuenta <i class="bi bi-arrow-right ms-1"></i></button>
                    </div>
                </form>
                <div class="login-social mt-3">Registro publico</div>
                <div class="login-note"><i class="bi bi-info-circle-fill me-1"></i>El registro publico crea siempre una cuenta con rol VENDEDOR. La politica de contrasenas y los permisos se validan en Oracle.</div>
            <?php endif; ?>
        </div>
    </div>
</main>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="adminlte/js/adminlte.min.js"></script>
<script src="assets/js/app.js"></script>
</body>
</html>
