<?php
function layout_start(string $title, string $active): void {
    $user = auth_user();
    $items = menu_items();
    $groups = [];
    foreach ($items as $item) {
        $groups[$item['GRUPO']][] = $item;
    }
    $groupLabels = [
        'PRINCIPAL' => 'GENERAL',
        'MANTENEDORES' => 'MANTENEDORES',
        'GESTION' => 'GESTION',
        'REPORTES' => 'REPORTES',
        'SEGURIDAD' => 'SEGURIDAD',
    ];
    $icons = [
        'dashboard' => 'bi-speedometer2', 'regiones' => 'bi-geo-alt', 'comunas' => 'bi-geo-alt',
        'terminales' => 'bi-building', 'empresas' => 'bi-briefcase', 'buses' => 'bi-bus-front',
        'asientos' => 'bi-grid-3x3', 'conductores' => 'bi-person-badge', 'mecanicos' => 'bi-wrench',
        'rutas' => 'bi-signpost-2', 'paradas' => 'bi-pin-map', 'horarios' => 'bi-clock',
        'pasajeros' => 'bi-people', 'venta' => 'bi-ticket-perforated', 'bajada' => 'bi-box-arrow-down',
        'viaje' => 'bi-calendar-event', 'conduce' => 'bi-diagram-3', 'mantencion' => 'bi-tools',
        'utilizan' => 'bi-link-45deg', 'usuarios' => 'bi-person-gear',
        'recaudacion' => 'bi-cash-stack', 'rep_mantencion' => 'bi-wrench-adjustable',
        'ocupacion' => 'bi-pie-chart', 'itinerario' => 'bi-map',
    ];
    $username = (string)($user['username'] ?? 'usuario');
    $role = (string)($user['role'] ?? '');
    $initial = strtoupper(substr($username, 0, 1));
    ?><!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <meta name="color-scheme" content="light dark">
  <title><?= h($title) ?> · RutaGestion</title>
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
<body class="layout-fixed sidebar-expand-lg">
<div class="app-wrapper">
  <nav class="app-header navbar navbar-expand bg-body">
    <div class="container-fluid">
      <ul class="navbar-nav">
        <li class="nav-item">
          <a class="nav-link" data-lte-toggle="sidebar" href="#" role="button" aria-label="Abrir o cerrar menu">
            <i class="bi bi-list"></i>
          </a>
        </li>
        <li class="nav-item d-none d-md-flex align-items-center">
          <span class="header-pill"><i class="bi bi-diagram-3"></i><?= h($title) ?></span>
        </li>
      </ul>
      <ul class="navbar-nav ms-auto align-items-center gap-1">
        <li class="nav-item dropdown">
          <a class="nav-link" href="#" id="bd-theme" aria-label="Cambiar tema" data-bs-toggle="dropdown" aria-expanded="false">
            <i class="bi bi-sun-fill" data-lte-theme-icon="light"></i>
            <i class="bi bi-moon-fill d-none" data-lte-theme-icon="dark"></i>
            <i class="bi bi-circle-half d-none" data-lte-theme-icon="auto"></i>
          </a>
          <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="bd-theme" style="--bs-dropdown-min-width: 9rem">
            <li>
              <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="light" aria-pressed="false">
                <i class="bi bi-sun-fill me-2"></i>Claro<i class="bi bi-check-lg ms-auto d-none"></i>
              </button>
            </li>
            <li>
              <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="dark" aria-pressed="false">
                <i class="bi bi-moon-fill me-2"></i>Oscuro<i class="bi bi-check-lg ms-auto d-none"></i>
              </button>
            </li>
            <li>
              <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="auto" aria-pressed="false">
                <i class="bi bi-circle-half me-2"></i>Automatico<i class="bi bi-check-lg ms-auto d-none"></i>
              </button>
            </li>
          </ul>
        </li>
        <li class="nav-item d-none d-lg-flex align-items-center">
          <span class="user-chip">
            <span class="user-avatar"><?= h($initial) ?></span>
            <span class="user-meta"><b><?= h($username) ?></b><small><?= h($role) ?></small></span>
          </span>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="?page=logout" title="Cerrar sesion">
            <i class="bi bi-box-arrow-right"></i><span class="d-none d-sm-inline">Salir</span>
          </a>
        </li>
      </ul>
    </div>
  </nav>

  <aside class="app-sidebar bg-body-secondary shadow" data-bs-theme="dark">
    <div class="sidebar-brand">
      <a href="?page=dashboard" class="brand-link">
        <span class="brand-image"><i class="bi bi-bus-front-fill"></i></span>
        <span class="brand-copy">
          <span class="brand-text">RutaGestion</span>
          <small>Transporte regional</small>
        </span>
      </a>
    </div>
    <div class="sidebar-wrapper">
      <nav class="mt-2">
        <ul class="nav sidebar-menu flex-column" data-lte-toggle="treeview" role="navigation">
          <?php foreach ($groups as $group => $groupItems): ?>
            <li class="nav-header"><?= h($groupLabels[$group] ?? $group) ?></li>
            <?php foreach ($groupItems as $item): ?>
              <li class="nav-item">
                <a href="?page=<?= h($item['CODIGO']) ?>" class="nav-link <?= $active === $item['CODIGO'] ? 'active' : '' ?>">
                  <i class="nav-icon bi <?= $icons[$item['CODIGO']] ?? 'bi-circle' ?>"></i>
                  <p><?= h($item['ETIQUETA']) ?></p>
                </a>
              </li>
            <?php endforeach; ?>
          <?php endforeach; ?>
        </ul>
      </nav>
    </div>
  </aside>

  <main class="app-main">
    <div class="app-content-header">
      <div class="container-fluid">
        <div class="row">
          <div class="col-sm-8">
            <div class="page-kicker mb-1">Sistema LHAOMRJZ · Transporte Regional</div>
            <h3 class="mb-0"><?= h($title) ?></h3>
          </div>
          <div class="col-sm-4 d-none d-sm-block">
            <ol class="breadcrumb float-sm-end mb-0">
              <li class="breadcrumb-item"><a href="?page=dashboard">Inicio</a></li>
              <li class="breadcrumb-item active" aria-current="page"><?= h($title) ?></li>
            </ol>
          </div>
        </div>
      </div>
    </div>
    <div class="app-content">
      <div class="container-fluid">
        <?php foreach (auth_take_flash() as $flash): ?>
          <div class="alert alert-<?= $flash['type'] === 'error' ? 'danger' : 'success' ?> alert-dismissible fade show" role="alert">
            <i class="bi <?= $flash['type'] === 'error' ? 'bi-exclamation-triangle-fill' : 'bi-check-circle-fill' ?> me-2"></i>
            <?= h($flash['message']) ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
          </div>
        <?php endforeach; ?>
<?php
}
function layout_end(): void {
    ?>
      </div>
    </div>
  </main>
  <footer class="app-footer">
    <div class="float-end d-none d-sm-inline">RutaGestion</div>
    <strong>Transporte Regional</strong>
  </footer>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="adminlte/js/adminlte.min.js"></script>
<script src="assets/js/app.js"></script>
</body>
</html>
<?php
}
