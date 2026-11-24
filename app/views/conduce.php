<?php
$conductores = lookup_options('conductores');
$buses = lookup_options('buses');
$viajes = lookup_options('viajes');
$asignaciones = db_rows('LEHZ_PS_LISTAR_CONDUCE');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">ASIGNACION</span><h3>Asignar conductor y bus</h3><p>Oracle valida licencia vigente, disponibilidad del bus y duplicados.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="conduce">
        <label>Conductor
            <select name="rut_conductor" required>
                <option value="">Seleccione un conductor...</option>
                <?php foreach ($conductores as $c): ?>
                    <option value="<?= h($c['value']) ?>" <?= (string)old_value('rut_conductor') === (string)$c['value'] ? 'selected' : '' ?>><?= h($c['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Bus
            <select name="patente_bus" required>
                <option value="">Seleccione un bus...</option>
                <?php foreach ($buses as $b): ?>
                    <option value="<?= h($b['value']) ?>" <?= (string)old_value('patente_bus') === (string)$b['value'] ? 'selected' : '' ?>><?= h($b['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label class="span-2">Viaje
            <select name="id_viaje" required>
                <option value="">Seleccione un viaje...</option>
                <?php foreach ($viajes as $v): ?>
                    <option value="<?= h($v['value']) ?>" <?= (string)old_value('id_viaje') === (string)$v['value'] ? 'selected' : '' ?>><?= h($v['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <div class="form-actions"><button class="btn primary" type="submit">Asignar</button></div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">FLOTA ASIGNADA</span><h3>Conductores y buses por viaje</h3></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>Conductor</th><th>Bus</th><th>Viaje</th><th>Fecha</th><th>Ruta</th><th>Salida</th><th>Acciones</th></tr></thead>
            <tbody>
            <?php foreach ($asignaciones as $a): ?>
                <tr>
                    <td><?= h($a['CONDUCTOR']) ?></td>
                    <td><?= h($a['BUS']) ?></td>
                    <td><?= h($a['ID_VIAJE']) ?></td>
                    <td><?= h($a['FECHA_VIAJE']) ?></td>
                    <td><?= h($a['NOMBRE_RUTA']) ?></td>
                    <td><?= h($a['HORA_SALIDA']) ?></td>
                    <td class="actions">
                        <form method="post" class="inline" onsubmit="return confirm('¿Eliminar esta asignacion?');">
                            <input type="hidden" name="action" value="conduce_delete">
                            <input type="hidden" name="rut_conductor" value="<?= h($a['RUT_CONDUCTOR']) ?>">
                            <input type="hidden" name="patente_bus" value="<?= h($a['PATENTE_BUS']) ?>">
                            <input type="hidden" name="id_viaje" value="<?= h($a['ID_VIAJE']) ?>">
                            <button class="icon-btn danger" type="submit" title="Eliminar">⌫</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$asignaciones): ?><tr><td colspan="7" class="empty">No hay asignaciones registradas.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>
