<?php
$horarios = lookup_options('horarios');
$rutas = lookup_options('rutas');
$viajes = db_rows('LEHZ_PS_LISTAR_VIAJES');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">PROGRAMACION</span><h3>Programar viaje</h3><p>Oracle rechaza fechas pasadas, duplicados y combinaciones invalidas.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="viaje">
        <label>Fecha del viaje
            <input type="date" name="fecha_viaje" required min="<?= date('Y-m-d') ?>" value="<?= h(old_value('fecha_viaje')) ?>">
        </label>
        <label>Horario
            <select name="id_horario" required>
                <option value="">Seleccione un horario...</option>
                <?php foreach ($horarios as $h): ?>
                    <option value="<?= h($h['value']) ?>" <?= (string)old_value('id_horario') === (string)$h['value'] ? 'selected' : '' ?>><?= h($h['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label class="span-2">Ruta
            <select name="id_ruta" required>
                <option value="">Seleccione una ruta...</option>
                <?php foreach ($rutas as $r): ?>
                    <option value="<?= h($r['value']) ?>" <?= (string)old_value('id_ruta') === (string)$r['value'] ? 'selected' : '' ?>><?= h($r['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <div class="form-actions"><button class="btn primary" type="submit">Programar viaje</button></div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">OPERACION</span><h3>Viajes programados</h3></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID</th><th>Fecha</th><th>Ruta</th><th>Salida</th><th>Llegada</th><th>Origen</th><th>Destino</th><th>Buses</th><th>Boletos activos</th></tr></thead>
            <tbody>
            <?php foreach ($viajes as $v): ?>
                <tr>
                    <td><?= h($v['ID_VIAJE']) ?></td>
                    <td><?= h($v['FECHA_VIAJE']) ?></td>
                    <td><?= h($v['NOMBRE_RUTA']) ?></td>
                    <td><?= h($v['HORA_SALIDA']) ?></td>
                    <td><?= h($v['HORA_LLEGADA']) ?></td>
                    <td><?= h($v['TERMINAL_ORIGEN']) ?></td>
                    <td><?= h($v['TERMINAL_DESTINO']) ?></td>
                    <td><?= h($v['TOTAL_BUSES']) ?></td>
                    <td><?= h($v['BOLETOS_ACTIVOS']) ?></td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$viajes): ?><tr><td colspan="9" class="empty">No hay viajes programados.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>
