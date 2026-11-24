<?php
$boletos = array_values(array_filter(db_rows('LEHZ_PS_LISTAR_BOLETOS'), function ($b) {
    return $b['ESTADO'] !== 'ANULADO' && ($b['TERMINAL_BAJADA'] === null || $b['TERMINAL_BAJADA'] === '');
}));
$terminales = lookup_options('terminales');
$bajadas = db_rows('LEHZ_PS_GES_LISTAR_BAJADAS');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">CONTROL DE PASAJEROS</span><h3>Registrar bajada</h3><p>Oracle valida que la parada pertenezca al recorrido y que permita bajada.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="bajada">
        <label>Boleto
            <select name="id_boleto" required>
                <option value="">Seleccione un boleto...</option>
                <?php foreach ($boletos as $b): ?>
                    <option value="<?= h($b['ID_BOLETO']) ?>" <?= (string)old_value('id_boleto') === (string)$b['ID_BOLETO'] ? 'selected' : '' ?>>
                        #<?= h($b['ID_BOLETO']) ?> · <?= h($b['PASAJERO']) ?> · <?= h($b['NOMBRE_RUTA']) ?> · asiento <?= h($b['NUMERO_ASIENTO']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Terminal de bajada
            <select name="id_terminal_bajada" required>
                <option value="">Seleccione un terminal...</option>
                <?php foreach ($terminales as $t): ?>
                    <option value="<?= h($t['value']) ?>" <?= (string)old_value('id_terminal_bajada') === (string)$t['value'] ? 'selected' : '' ?>><?= h($t['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label class="span-2">Observacion
            <input name="observacion" maxlength="150" value="<?= h(old_value('observacion')) ?>" placeholder="Opcional">
        </label>
        <div class="form-actions"><button class="btn primary" type="submit">Registrar bajada</button></div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">REGISTRO</span><h3>Bajadas registradas</h3></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID bajada</th><th>Boleto</th><th>Terminal</th><th>Observacion</th><th>Fecha registro</th></tr></thead>
            <tbody>
            <?php foreach ($bajadas as $b): ?>
                <tr>
                    <td><?= h($b['ID_BAJADA']) ?></td>
                    <td><?= h($b['ID_BOLETO']) ?></td>
                    <td><?= h($b['TERMINAL']) ?></td>
                    <td><?= h($b['OBSERVACION'] ?: '-') ?></td>
                    <td><?= h($b['FECHA_REGISTRO']) ?></td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$bajadas): ?><tr><td colspan="5" class="empty">No hay bajadas registradas.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>
