<?php
$pasajeros = lookup_options('pasajeros');
$viajes = db_rows('LEHZ_PS_LISTAR_VIAJES');
$buses = lookup_options('buses');
$metodos = domain_options('METODO_PAGO');
$paradas = db_query(
    'SELECT ID_VIAJE, ID_TERMINAL, TERMINAL, ORDEN_PARADA, TARIFA
       FROM LEHZ_VW_PARADAS_BAJADA
      ORDER BY ID_VIAJE, ORDEN_PARADA'
);
$boletos = db_rows('LEHZ_PS_LISTAR_BOLETOS');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">VENTA EN ORACLE</span><h3>Emitir boleto</h3><p>La tarifa se calcula con LEHZ_FN_CALCULAR_TARIFA_BUS; no se recibe un precio desde la interfaz.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="sale">
        <label>Pasajero
            <select name="rut_pasajero" required>
                <option value="">Seleccione un pasajero...</option>
                <?php foreach ($pasajeros as $p): ?>
                    <option value="<?= h($p['value']) ?>" <?= (string)old_value('rut_pasajero') === (string)$p['value'] ? 'selected' : '' ?>><?= h($p['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Viaje
            <select name="id_viaje" id="saleViaje" required>
                <option value="">Seleccione un viaje...</option>
                <?php foreach ($viajes as $v): ?>
                    <option value="<?= h($v['ID_VIAJE']) ?>" <?= (string)old_value('id_viaje') === (string)$v['ID_VIAJE'] ? 'selected' : '' ?>>
                        #<?= h($v['ID_VIAJE']) ?> · <?= h($v['FECHA_VIAJE']) ?> · <?= h($v['NOMBRE_RUTA']) ?> · <?= h($v['HORA_SALIDA']) ?> (<?= h($v['TERMINAL_ORIGEN']) ?> → <?= h($v['TERMINAL_DESTINO']) ?>)
                    </option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Asiento
            <input type="number" name="numero_asiento" min="1" required value="<?= h(old_value('numero_asiento')) ?>">
        </label>
        <label>Bus
            <select name="patente_bus" required>
                <option value="">Seleccione un bus...</option>
                <?php foreach ($buses as $b): ?>
                    <option value="<?= h($b['value']) ?>" <?= (string)old_value('patente_bus') === (string)$b['value'] ? 'selected' : '' ?>><?= h($b['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Metodo de pago
            <select name="metodo_pago" required>
                <option value="">Seleccione...</option>
                <?php foreach ($metodos as $m): ?>
                    <option value="<?= h($m['value']) ?>" <?= (string)old_value('metodo_pago') === (string)$m['value'] ? 'selected' : '' ?>><?= h($m['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Terminal de bajada (opcional)
            <select name="id_terminal_bajada" id="saleBajada">
                <option value="">Sin bajada (destino final)</option>
                <?php foreach ($paradas as $p): ?>
                    <option value="<?= h($p['ID_TERMINAL']) ?>" data-viaje="<?= h($p['ID_VIAJE']) ?>" data-tarifa="<?= h($p['TARIFA']) ?>" <?= (string)old_value('id_terminal_bajada') === (string)$p['ID_TERMINAL'] && (string)old_value('id_viaje') === (string)$p['ID_VIAJE'] ? 'selected' : '' ?>>
                        <?= h($p['TERMINAL']) ?> · $<?= h(number_format((float)$p['TARIFA'], 0, ',', '.')) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </label>
        <div class="span-2 notice" id="tarifaPreview">La tarifa final la calcula Oracle al confirmar la venta.</div>
        <div class="form-actions">
            <button class="btn primary" type="submit">Vender boleto</button>
        </div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">BOLETERIA</span><h3>Boletos emitidos</h3><p>Anula o marca como usado; el estado y las reglas se validan en Oracle.</p></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID</th><th>Emision</th><th>Pasajero</th><th>Viaje</th><th>Ruta</th><th>Bus</th><th>Asiento</th><th>Valor</th><th>Pago</th><th>Bajada</th><th>Estado</th><th>Acciones</th></tr></thead>
            <tbody>
            <?php foreach ($boletos as $b): ?>
                <tr>
                    <td><?= h($b['ID_BOLETO']) ?></td>
                    <td><?= h($b['FECHA_EMISION']) ?></td>
                    <td><?= h($b['PASAJERO']) ?></td>
                    <td><?= h($b['FECHA_VIAJE']) ?></td>
                    <td><?= h($b['NOMBRE_RUTA']) ?></td>
                    <td><?= h($b['PATENTE_BUS']) ?></td>
                    <td><?= h($b['NUMERO_ASIENTO']) ?></td>
                    <td>$<?= h(number_format((float)$b['VALOR_BOLETO'], 0, ',', '.')) ?></td>
                    <td><?= h($b['METODO_PAGO']) ?></td>
                    <td><?= h($b['TERMINAL_BAJADA'] ?: '-') ?></td>
                    <td><span class="badge"><?= h($b['ESTADO']) ?></span></td>
                    <td class="actions">
                        <?php if ($b['ESTADO'] === 'EMITIDO'): ?>
                            <button class="icon-btn" type="button" title="Anular" onclick="openAnnul(<?= (int)$b['ID_BOLETO'] ?>)">⊘</button>
                            <form method="post" class="inline" onsubmit="return confirm('¿Marcar este boleto como usado?');">
                                <input type="hidden" name="action" value="use">
                                <input type="hidden" name="id_boleto" value="<?= h($b['ID_BOLETO']) ?>">
                                <button class="icon-btn" type="submit" title="Marcar usado">✓</button>
                            </form>
                        <?php else: ?>
                            <span class="empty">-</span>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$boletos): ?><tr><td colspan="12" class="empty">No hay boletos emitidos.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>

<div class="modal" id="annulModal">
    <div class="modal-card">
        <div class="modal-head"><div><span class="eyebrow">ANULACION</span><h3>Anular boleto</h3></div><button class="icon-btn" type="button" onclick="closeAnnul()">×</button></div>
        <form method="post">
            <input type="hidden" name="action" value="annul">
            <input type="hidden" name="id_boleto" id="annulId" value="">
            <label>Motivo de la anulacion
                <input name="motivo" id="annulMotivo" required maxlength="200" placeholder="Ej. Pasajero no se presento">
            </label>
            <div class="modal-actions">
                <button class="btn ghost" type="button" onclick="closeAnnul()">Cancelar</button>
                <button class="btn primary" type="submit">Anular boleto</button>
            </div>
        </form>
    </div>
</div>
