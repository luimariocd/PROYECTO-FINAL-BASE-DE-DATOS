<?php
$boletos = array_values(array_filter(db_rows('LEHZ_PS_LISTAR_BOLETOS'), function ($b) {
    return $b['ESTADO'] !== 'ANULADO' && ($b['TERMINAL_BAJADA'] === null || $b['TERMINAL_BAJADA'] === '');
}));
$terminales = lookup_options('terminales');
$bajadas = db_rows('LEHZ_PS_GES_LISTAR_BAJADAS');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Registrar bajada</h3>
        <div class="text-body-secondary small mt-1">Oracle valida que la parada pertenezca al recorrido y que permita bajada.</div>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="bajada">
            <div class="col-md-6">
                <label class="form-label" for="bajadaBoleto">Boleto</label>
                <select class="form-select" name="id_boleto" id="bajadaBoleto" required>
                    <option value="">Seleccione un boleto...</option>
                    <?php foreach ($boletos as $b): ?>
                        <option value="<?= h($b['ID_BOLETO']) ?>" <?= (string)old_value('id_boleto') === (string)$b['ID_BOLETO'] ? 'selected' : '' ?>>
                            #<?= h($b['ID_BOLETO']) ?> · <?= h($b['PASAJERO']) ?> · <?= h($b['NOMBRE_RUTA']) ?> · asiento <?= h($b['NUMERO_ASIENTO']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="bajadaTerminal">Terminal de bajada</label>
                <select class="form-select" name="id_terminal_bajada" id="bajadaTerminal" required>
                    <option value="">Seleccione un terminal...</option>
                    <?php foreach ($terminales as $t): ?>
                        <option value="<?= h($t['value']) ?>" <?= (string)old_value('id_terminal_bajada') === (string)$t['value'] ? 'selected' : '' ?>><?= h($t['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12">
                <label class="form-label" for="bajadaObservacion">Observacion</label>
                <input class="form-control" id="bajadaObservacion" name="observacion" maxlength="150" value="<?= h(old_value('observacion')) ?>" placeholder="Opcional">
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-box-arrow-down me-1"></i>Registrar bajada</button>
            </div>
        </form>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <h3 class="card-title mb-0">Bajadas registradas</h3>
        <input class="form-control filter-input" type="search" data-filter="bajadasBody" placeholder="Filtrar bajadas..." aria-label="Filtrar bajadas" style="max-width: 18rem;">
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead><tr><th>ID bajada</th><th>Boleto</th><th>Terminal</th><th>Observacion</th><th>Fecha registro</th></tr></thead>
                <tbody id="bajadasBody">
                <?php foreach ($bajadas as $b): ?>
                    <tr>
                        <td><?= h($b['ID_BAJADA']) ?></td>
                        <td><?= h($b['ID_BOLETO']) ?></td>
                        <td><?= h($b['TERMINAL']) ?></td>
                        <td><?= h($b['OBSERVACION'] ?: '-') ?></td>
                        <td><?= h($b['FECHA_REGISTRO']) ?></td>
                    </tr>
                <?php endforeach; ?>
                <?php if (!$bajadas): ?><tr><td colspan="5" class="text-center text-body-secondary py-4">No hay bajadas registradas.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
