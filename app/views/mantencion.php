<?php
$mecanicos = lookup_options('mecanicos');
$buses = lookup_options('buses');
$mantenciones = db_rows('LEHZ_PS_LISTAR_MANTENCIONES');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">CONTROL DE FLOTA</span><h3>Registrar mantencion</h3><p>Oracle bloquea fechas futuras y buses asignados a un viaje ese dia.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="mantencion">
        <label>Fecha
            <input type="date" name="fecha" required min="<?= date('Y-m-d') ?>" value="<?= h(old_value('fecha')) ?>">
        </label>
        <label>Costo
            <input type="number" name="costo" min="0" step="1" required value="<?= h(old_value('costo')) ?>">
        </label>
        <label class="span-2">Descripcion
            <input name="descripcion" required maxlength="500" value="<?= h(old_value('descripcion')) ?>" placeholder="Trabajo realizado">
        </label>
        <label>Mecanico
            <select name="rut_mecanico" required>
                <option value="">Seleccione un mecanico...</option>
                <?php foreach ($mecanicos as $m): ?>
                    <option value="<?= h($m['value']) ?>" <?= (string)old_value('rut_mecanico') === (string)$m['value'] ? 'selected' : '' ?>><?= h($m['label']) ?></option>
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
        <div class="form-actions"><button class="btn primary" type="submit">Registrar mantencion</button></div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">HISTORIAL</span><h3>Mantenciones registradas</h3></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID</th><th>Fecha</th><th>Descripcion</th><th>Costo</th><th>Mecanico</th><th>Bus</th><th>Empresa</th></tr></thead>
            <tbody>
            <?php foreach ($mantenciones as $m): ?>
                <tr>
                    <td><?= h($m['ID_MANTENCION']) ?></td>
                    <td><?= h($m['FECHA_MANTENCION']) ?></td>
                    <td><?= h($m['DESCRIPCION_MANTENCION']) ?></td>
                    <td>$<?= h(number_format((float)$m['COSTO_MANTENCION'], 0, ',', '.')) ?></td>
                    <td><?= h($m['MECANICO']) ?></td>
                    <td><?= h($m['PATENTE_BUS']) ?></td>
                    <td><?= h($m['RAZON_SOCIAL']) ?></td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$mantenciones): ?><tr><td colspan="7" class="empty">No hay mantenciones registradas.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>
