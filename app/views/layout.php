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
        'dashboard' => '⌂', 'regiones' => '▦', 'comunas' => '▦', 'terminales' => '⌑',
        'empresas' => '▦', 'buses' => '▤', 'asientos' => '▥', 'conductores' => '◉',
        'mecanicos' => '⚙', 'rutas' => '↗', 'paradas' => '⇢', 'horarios' => '◷',
        'pasajeros' => '◉', 'venta' => '▣', 'bajada' => '⇣', 'viaje' => '↗',
        'conduce' => '⇄', 'mantencion' => '⚙', 'utilizan' => '⌑', 'usuarios' => '◉',
        'recaudacion' => '▤', 'rep_mantencion' => '▤', 'ocupacion' => '▥',
        'itinerario' => '⇢',
    ];
    ?><!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title><?= h($title) ?> · RutaGestion</title>
    <link rel="stylesheet" href="assets/css/app.css">
</head>
<body>
<div class="shell">
    <aside class="sidebar">
        <a class="brand" href="?page=dashboard">
            <span class="brand-icon">R</span>
            <span><b>RutaGestion</b><small>TRANSPORTE REGIONAL</small></span>
        </a>
        <div class="side-user">
            <div class="avatar"><?= h(strtoupper(substr((string)($user['name'] ?? 'U'), 0, 1))) ?></div>
            <div><b><?= h($user['name'] ?? 'Usuario') ?></b><small><?= h($user['role'] ?? '') ?></small></div>
        </div>
        <nav>
            <?php foreach ($groups as $group => $groupItems): ?>
                <div class="nav-label"><?= h($groupLabels[$group] ?? $group) ?></div>
                <?php foreach ($groupItems as $item): ?>
                    <a class="nav-link <?= $active === $item['CODIGO'] ? 'active' : '' ?>" href="?page=<?= h($item['CODIGO']) ?>">
                        <span><?= $icons[$item['CODIGO']] ?? '·' ?></span><?= h($item['ETIQUETA']) ?>
                    </a>
                <?php endforeach; ?>
            <?php endforeach; ?>
        </nav>
        <a class="logout" href="?page=logout">↪ Cerrar sesion</a>
    </aside>
    <main class="main">
        <header class="topbar">
            <div><span class="eyebrow">SISTEMA DE GESTION INTEGRAL</span><h1><?= h($title) ?></h1></div>
            <div class="top-user"><span class="status-dot"></span> Conectado <b><?= h($user['username'] ?? '') ?></b></div>
        </header>
        <div class="content">
        <?php foreach (auth_take_flash() as $flash): ?>
            <div class="alert <?= h($flash['type']) ?>"><?= h($flash['message']) ?></div>
        <?php endforeach; ?>
<?php
}

function layout_end(): void {
    ?>
        </div>
        <footer>RutaGestion · Sistema de Gestion Integral de Transporte Publico Regional</footer>
    </main>
</div>
<script src="assets/js/app.js"></script>
</body>
</html>
<?php
}
