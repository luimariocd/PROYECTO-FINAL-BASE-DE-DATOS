<?php
// Esta parte del código se encarga de usar la vista de resumen ya calculada en Oracle.
$resumen = db_rows('LEHZ_PS_RESUMEN_DASHBOARD');
$resumen = $resumen[0] ?? [];
$viajes = can_access('viaje') || can_access('venta') ? db_rows('LEHZ_PS_LISTAR_VIAJES') : [];
$boletos = can_access('venta') ? db_rows('LEHZ_PS_LISTAR_BOLETOS') : [];
$quick = [
    ['venta', 'Vender boleto', 'Registrar venta y pago', 'bi-ticket-perforated'],
    ['viaje', 'Programar viaje', 'Crear una nueva salida', 'bi-calendar-plus'],
    ['mantencion', 'Registrar mantencion', 'Control de flota', 'bi-tools'],
    ['recaudacion', 'Ver recaudacion', 'Consultar resultados', 'bi-cash-stack'],
];
$stats = [
    ['Empresas', $resumen['TOTAL_EMPRESAS'] ?? 0, 'bi-briefcase-fill', 'primary'],
    ['Buses', $resumen['TOTAL_BUSES'] ?? 0, 'bi-bus-front-fill', 'info'],
    ['Viajes', $resumen['TOTAL_VIAJES'] ?? 0, 'bi-calendar-event-fill', 'success'],
    ['Pasajeros', $resumen['TOTAL_PASAJEROS'] ?? 0, 'bi-people-fill', 'warning'],
    ['Boletos emitidos', $resumen['BOLETOS_EMITIDOS'] ?? 0, 'bi-ticket-perforated-fill', 'danger'],
    ['Recaudacion activa', $resumen['RECAUDACION_ACTIVA'] ?? 0, 'bi-cash-coin', 'secondary'],
];
?>
<div class="card border-0 text-bg-primary dashboard-hero mb-4">
    <div class="card-body p-4">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <div>
                <div class="text-uppercase small fw-semibold text-white-50">Resumen operacional</div>
                <h2 class="mb-1 fw-bold">Hola, <?= h(explode(' ', (string)(auth_user()['name'] ?? 'Usuario'))[0]) ?></h2>
                <p class="mb-0 text-white-50">Este es el estado general de tu sistema de transporte.</p>
            </div>
            <div class="text-end">
                <div class="fs-4 fw-bold"><?= date('d/m/Y') ?></div>
                <div class="text-uppercase small text-white-50">Fecha de consulta</div>
            </div>
        </div>
    </div>
</div>

<div class="row g-3 mb-4">
    <?php foreach ($stats as [$label, $value, $icon, $color]): ?>
        <div class="col-6 col-md-4 col-xl-2">
            <div class="small-box text-bg-<?= h($color) ?> mb-0">
                <div class="inner">
                    <h3><?= h(is_money_column(strtoupper($label)) ? '$' . number_format((float)$value, 0, ',', '.') : number_format((float)$value, 0, ',', '.')) ?></h3>
                    <p><?= h($label) ?></p>
                </div>
                <i class="small-box-icon bi <?= h($icon) ?>" aria-hidden="true"></i>
                <span class="small-box-footer">Registros en Oracle</span>
            </div>
        </div>
    <?php endforeach; ?>
</div>

<div class="row g-4 mb-4">
    <div class="col-lg-8">
        <div class="card h-100 mb-0">
            <div class="card-header">
                <h3 class="card-title mb-0">Operaciones frecuentes</h3>
            </div>
            <div class="card-body">
                <div class="row g-2">
                    <?php foreach ($quick as [$code, $label, $help, $icon]): ?>
                        <?php if (can_access($code)): ?>
                            <div class="col-sm-6">
                                <a href="?page=<?= h($code) ?>" class="btn btn-outline-primary w-100 text-start p-3 d-flex align-items-center gap-3 h-100">
                                    <i class="bi <?= h($icon) ?> fs-4"></i>
                                    <span>
                                        <span class="d-block fw-semibold"><?= h($label) ?></span>
                                        <small class="text-body-secondary fw-normal"><?= h($help) ?></small>
                                    </span>
                                </a>
                            </div>
                        <?php endif; ?>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>
    <div class="col-lg-4">
        <div class="card h-100 mb-0">
            <div class="card-header">
                <h3 class="card-title mb-0">Estado del sistema</h3>
            </div>
            <div class="card-body">
                <div class="callout callout-success mb-3">
                    <div class="d-flex align-items-center gap-2">
                        <i class="bi bi-database-check fs-5"></i>
                        <div>
                            <div class="fw-bold">Oracle · LEHZ</div>
                            <div class="small">Conexion activa</div>
                        </div>
                        <span class="badge text-bg-success ms-auto">OK</span>
                    </div>
                </div>
                <p class="text-body-secondary small mb-0">
                    Los modulos ejecutan procedimientos y vistas almacenadas en Oracle.
                    La interfaz no contiene reglas de negocio.
                </p>
            </div>
        </div>
    </div>
</div>

<?php if ($viajes): ?>
<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center gap-2">
        <h3 class="card-title mb-0">Viajes programados</h3>
        <a class="btn btn-sm btn-outline-primary" href="?page=<?= can_access('viaje') ? 'viaje' : 'venta' ?>">
            Ver modulo <i class="bi bi-arrow-right ms-1"></i>
        </a>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead>
                    <tr><th>ID</th><th>Fecha</th><th>Ruta</th><th>Hora</th><th>Origen</th><th>Destino</th><th>Buses</th><th>Boletos</th></tr>
                </thead>
                <tbody>
                <?php foreach (array_slice($viajes, 0, 6) as $v): ?>
                    <tr>
                        <td><?= h($v['ID_VIAJE']) ?></td>
                        <td><?= h($v['FECHA_VIAJE']) ?></td>
                        <td><?= h($v['NOMBRE_RUTA']) ?></td>
                        <td><?= h($v['HORA_SALIDA']) ?></td>
                        <td><?= h($v['TERMINAL_ORIGEN']) ?></td>
                        <td><?= h($v['TERMINAL_DESTINO']) ?></td>
                        <td><?= h($v['TOTAL_BUSES']) ?></td>
                        <td><?= h($v['BOLETOS_ACTIVOS']) ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<?php endif; ?>

<?php if ($boletos): ?>
<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center gap-2">
        <h3 class="card-title mb-0">Boletos recientes</h3>
        <a class="btn btn-sm btn-outline-primary" href="?page=venta">
            Ir a venta <i class="bi bi-arrow-right ms-1"></i>
        </a>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead>
                    <tr><th>ID</th><th>Pasajero</th><th>Ruta</th><th>Asiento</th><th>Valor</th><th>Estado</th></tr>
                </thead>
                <tbody>
                <?php foreach (array_slice($boletos, 0, 6) as $b): ?>
                    <tr>
                        <td><?= h($b['ID_BOLETO']) ?></td>
                        <td><?= h($b['PASAJERO']) ?></td>
                        <td><?= h($b['NOMBRE_RUTA']) ?></td>
                        <td><?= h($b['NUMERO_ASIENTO']) ?></td>
                        <td>$<?= h(number_format((float)$b['VALOR_BOLETO'], 0, ',', '.')) ?></td>
                        <td>
                            <span class="badge <?= $b['ESTADO'] === 'EMITIDO' ? 'text-bg-success' : ($b['ESTADO'] === 'ANULADO' ? 'text-bg-danger' : 'text-bg-secondary') ?>">
                                <?= h($b['ESTADO']) ?>
                            </span>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<?php endif; ?>
