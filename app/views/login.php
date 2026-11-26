<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light dark">
    <title>Iniciar sesion · RutaGestion</title>
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
<main class="login-shell">
    <picture class="login-backdrop" aria-hidden="true">
        <source srcset="assets/img/login-bus-atardecer.avif" type="image/avif">
        <img src="assets/img/login-bus-atardecer.webp" alt="">
    </picture>

    <section class="login-panel" aria-label="Ingreso al sistema">
    <div class="login-box">
    <div class="login-logo">
        <a href="?page=login"><span class="login-brand-icon"><i class="bi bi-bus-front-fill"></i></span><span><b>Ruta</b>Gestion<small>Transporte regional</small></span></a>
    </div>
    <div class="card card-outline card-primary login-card">
        <div class="card-header text-center">
            <div class="login-shield"><i class="bi bi-shield-lock"></i></div>
            <span class="h5 mb-0 d-block">Bienvenido de nuevo</span>
            <span class="text-body-secondary small">Sistema LEHZ · Transporte Regional</span>
        </div>
        <div class="card-body login-card-body">
            <p class="login-box-msg">Ingresa tus credenciales para continuar.</p>

            <?php foreach (auth_take_flash() as $flash): ?>
                <div class="alert alert-<?= $flash['type'] === 'error' ? 'danger' : 'success' ?> alert-dismissible fade show" role="alert">
                    <i class="bi <?= $flash['type'] === 'error' ? 'bi-exclamation-triangle-fill' : 'bi-check-circle-fill' ?> me-2"></i>
                    <?= h($flash['message']) ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
                </div>
            <?php endforeach; ?>

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
            <div class="login-social mt-3">Acceso restringido</div>
            <div class="login-note"><i class="bi bi-lock-fill me-1"></i>Los usuarios son creados por el administrador desde el modulo Usuarios. La autenticacion y los permisos se validan en Oracle.</div>
        </div>
    </div>
    </div>
    </section>
</main>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="adminlte/js/adminlte.min.js"></script>
<script src="assets/js/app.js"></script>
</body>
</html>
