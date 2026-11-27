<?php
$pasajeros = lookup_options('pasajeros');
$viajes = db_rows('LEHZ_PS_LISTAR_VIAJES');
$buses = lookup_options('buses');
$metodos = domain_options('METODO_PAGO');
// Esta parte del código se encarga de usar la vista de paradas de Oracle para las tarifas de bajada.
$paradas = db_rows('LEHZ_PS_LISTAR_PARADAS_BAJADA');
$boletos = db_rows('LEHZ_PS_LISTAR_BOLETOS');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Emitir boleto</h3>
        <div class="text-body-secondary small mt-1">La tarifa se calcula con LEHZ_FN_CALCULAR_TARIFA_BUS; no se recibe un precio desde la interfaz.</div>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="sale">
            <div class="col-md-6">
                <label class="form-label" for="salePasajero">Pasajero</label>
                <select class="form-select" name="rut_pasajero" id="salePasajero" required>
                    <option value="">Seleccione un pasajero...</option>
                    <?php foreach ($pasajeros as $p): ?>
                        <option value="<?= h($p['value']) ?>" <?= (string)old_value('rut_pasajero') === (string)$p['value'] ? 'selected' : '' ?>><?= h($p['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="saleViaje">Viaje</label>
                <select class="form-select" name="id_viaje" id="saleViaje" required>
                    <option value="">Seleccione un viaje...</option>
                    <?php foreach ($viajes as $v): ?>
                        <option value="<?= h($v['ID_VIAJE']) ?>" <?= (string)old_value('id_viaje') === (string)$v['ID_VIAJE'] ? 'selected' : '' ?>>
                            #<?= h($v['ID_VIAJE']) ?> · <?= h($v['FECHA_VIAJE']) ?> · <?= h($v['NOMBRE_RUTA']) ?> · <?= h($v['HORA_SALIDA']) ?> (<?= h($v['TERMINAL_ORIGEN']) ?> → <?= h($v['TERMINAL_DESTINO']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="saleAsiento">Asiento</label>
                <input class="form-control" type="number" name="numero_asiento" id="saleAsiento" min="1" required value="<?= h(old_value('numero_asiento')) ?>">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="saleBus">Bus</label>
                <select class="form-select" name="patente_bus" id="saleBus" required>
                    <option value="">Seleccione un bus...</option>
                    <?php foreach ($buses as $b): ?>
                        <option value="<?= h($b['value']) ?>" <?= (string)old_value('patente_bus') === (string)$b['value'] ? 'selected' : '' ?>><?= h($b['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="saleMetodo">Metodo de pago</label>
                <select class="form-select" name="metodo_pago" id="saleMetodo" required>
                    <option value="">Seleccione...</option>
                    <?php foreach ($metodos as $m): ?>
                        <option value="<?= h($m['value']) ?>" <?= (string)old_value('metodo_pago') === (string)$m['value'] ? 'selected' : '' ?>><?= h($m['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="saleBajada">Terminal de bajada (opcional)</label>
                <select class="form-select" name="id_terminal_bajada" id="saleBajada">
                    <option value="">Sin bajada (destino final)</option>
                    <?php foreach ($paradas as $p): ?>
                        <option value="<?= h($p['ID_TERMINAL']) ?>" data-viaje="<?= h($p['ID_VIAJE']) ?>" data-tarifa="<?= h($p['TARIFA']) ?>" <?= (string)old_value('id_terminal_bajada') === (string)$p['ID_TERMINAL'] && (string)old_value('id_viaje') === (string)$p['ID_VIAJE'] ? 'selected' : '' ?>>
                            <?= h($p['TERMINAL']) ?> · $<?= h(number_format((float)$p['TARIFA'], 0, ',', '.')) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12">
                <div class="alert alert-info mb-0" id="tarifaPreview">La tarifa final la calcula Oracle al confirmar la venta.</div>
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-ticket-perforated me-1"></i>Vender boleto</button>
            </div>
        </form>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <div>
            <h3 class="card-title mb-0">Boletos emitidos</h3>
            <div class="text-body-secondary small mt-1">Anula o marca como usado; el estado y las reglas se validan en Oracle.</div>
        </div>
        <input class="form-control filter-input" type="search" data-filter="boletosBody" placeholder="Filtrar boletos..." aria-label="Filtrar boletos" style="max-width: 18rem;">
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead>
                    <tr><th>ID</th><th>Emision</th><th>Pasajero</th><th>Viaje</th><th>Ruta</th><th>Bus</th><th>Asiento</th><th>Valor</th><th>Pago</th><th>Bajada</th><th>Estado</th><th class="text-end">Acciones</th></tr>
                </thead>
                <tbody id="boletosBody">
                <?php foreach ($boletos as $b): ?>
                    <?php
                    $badge = $b['ESTADO'] === 'EMITIDO' ? 'text-bg-success' : ($b['ESTADO'] === 'ANULADO' ? 'text-bg-danger' : 'text-bg-secondary');
                    ?>
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
                        <td><span class="badge <?= $badge ?>"><?= h($b['ESTADO']) ?></span></td>
                        <td class="text-end text-nowrap">
                            <?php if ($b['ESTADO'] === 'EMITIDO'): ?>
                                <button class="btn btn-sm btn-outline-danger" type="button" title="Anular" onclick="openAnnul(<?= (int)$b['ID_BOLETO'] ?>)">
                                    <i class="bi bi-slash-circle"></i>
                                </button>
                                <form method="post" class="d-inline" onsubmit="return confirm('¿Marcar este boleto como usado?');">
                                    <input type="hidden" name="action" value="use">
                                    <input type="hidden" name="id_boleto" value="<?= h($b['ID_BOLETO']) ?>">
                                    <button class="btn btn-sm btn-outline-success" type="submit" title="Marcar usado"><i class="bi bi-check-lg"></i></button>
                                </form>
                            <?php else: ?>
                                <span class="text-body-secondary">-</span>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                <?php if (!$boletos): ?><tr><td colspan="12" class="text-center text-body-secondary py-4">No hay boletos emitidos.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<div class="modal fade" id="annulModal" tabindex="-1" aria-labelledby="annulModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <form method="post" class="modal-content">
            <div class="modal-header">
                <div>
                    <div class="text-uppercase small text-body-secondary fw-semibold">Anulacion</div>
                    <h5 class="modal-title" id="annulModalTitle">Anular boleto</h5>
                </div>
                <button class="btn-close" type="button" onclick="closeAnnul()" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" name="action" value="annul">
                <input type="hidden" name="id_boleto" id="annulId" value="">
                <label class="form-label" for="annulMotivo">Motivo de la anulacion</label>
                <input class="form-control" name="motivo" id="annulMotivo" required maxlength="200" placeholder="Ej. Pasajero no se presento">
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" type="button" onclick="closeAnnul()">Cancelar</button>
                <button class="btn btn-danger" type="submit">Anular boleto</button>
            </div>
        </form>
    </div>
</div>
