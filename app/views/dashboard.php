<?php
$resumen = db_query('SELECT * FROM LEHZ_VW_RESUMEN');
$resumen = $resumen[0] ?? [];
$viajes = can_access('viaje') || can_access('venta') ? db_rows('LEHZ_PS_LISTAR_VIAJES') : [];
$boletos = can_access('venta') ? db_rows('LEHZ_PS_LISTAR_BOLETOS') : [];
$quick = [
    ['venta', 'Vender boleto', 'Registrar venta y pago'],
    ['viaje', 'Programar viaje', 'Crear una nueva salida'],
    ['mantencion', 'Registrar mantencion', 'Control de flota'],
    ['recaudacion', 'Ver recaudacion', 'Consultar resultados'],
];
$stats = [
    ['Empresas', $resumen['TOTAL_EMPRESAS'] ?? 0],
    ['Buses', $resumen['TOTAL_BUSES'] ?? 0],
    ['Viajes', $resumen['TOTAL_VIAJES'] ?? 0],
    ['Pasajeros', $resumen['TOTAL_PASAJEROS'] ?? 0],
    ['Boletos emitidos', $resumen['BOLETOS_EMITIDOS'] ?? 0],
    ['Recaudacion activa', $resumen['RECAUDACION_ACTIVA'] ?? 0],
];
?>
<div class="welcome">
    <div>
        <span class="eyebrow">RESUMEN OPERACIONAL</span>
        <h2>Hola, <?= h(explode(' ', (string)(auth_user()['name'] ?? 'Usuario'))[0]) ?></h2>
        <p>Este es el estado general de tu sistema de transporte.</p>
    </div>
    <div class="welcome-date"><?= date('d/m/Y') ?> <small>FECHA DE CONSULTA</small></div>
</div>

<div class="stat-grid">
    <?php foreach ($stats as [$label, $value]): ?>
        <article class="stat-card">
            <span><?= h($label) ?></span>
            <strong><?= h(is_money_column(strtoupper($label)) ? '$' . number_format((float)$value, 0, ',', '.') : number_format((float)$value, 0, ',', '.')) ?></strong>
            <small>Registros en Oracle</small>
        </article>
    <?php endforeach; ?>
</div>

<div class="dashboard-grid">
    <section class="panel">
        <div class="panel-head"><div><span class="eyebrow">ACCESOS RAPIDOS</span><h3>Operaciones frecuentes</h3></div></div>
        <div class="quick-grid">
            <?php foreach ($quick as [$code, $label, $help]): ?>
                <?php if (can_access($code)): ?>
                    <a href="?page=<?= h($code) ?>"><b>▣</b><span><?= h($label) ?></span><small><?= h($help) ?></small></a>
                <?php endif; ?>
            <?php endforeach; ?>
        </div>
    </section>
    <section class="panel side-panel">
        <span class="eyebrow">ESTADO DEL SISTEMA</span>
        <h3>Base de datos</h3>
        <div class="db-status"><i></i><b>Oracle · LEHZ</b><span>Conexion activa</span></div>
        <p>Los modulos ejecutan procedimientos y vistas almacenadas en Oracle. La interfaz no contiene reglas de negocio.</p>
    </section>
</div>

<?php if ($viajes): ?>
<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">PROXIMAS SALIDAS</span><h3>Viajes programados</h3></div><a class="btn ghost" href="?page=<?= can_access('viaje') ? 'viaje' : 'venta' ?>">Ver modulo</a></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID</th><th>Fecha</th><th>Ruta</th><th>Hora</th><th>Origen</th><th>Destino</th><th>Buses</th><th>Boletos</th></tr></thead>
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
</section>
<?php endif; ?>

<?php if ($boletos): ?>
<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">ULTIMAS VENTAS</span><h3>Boletos recientes</h3></div><a class="btn ghost" href="?page=venta">Ir a venta</a></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID</th><th>Pasajero</th><th>Ruta</th><th>Asiento</th><th>Valor</th><th>Estado</th></tr></thead>
            <tbody>
            <?php foreach (array_slice($boletos, 0, 6) as $b): ?>
                <tr>
                    <td><?= h($b['ID_BOLETO']) ?></td>
                    <td><?= h($b['PASAJERO']) ?></td>
                    <td><?= h($b['NOMBRE_RUTA']) ?></td>
                    <td><?= h($b['NUMERO_ASIENTO']) ?></td>
                    <td>$<?= h(number_format((float)$b['VALOR_BOLETO'], 0, ',', '.')) ?></td>
                    <td><span class="badge"><?= h($b['ESTADO']) ?></span></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</section>
<?php endif; ?>
