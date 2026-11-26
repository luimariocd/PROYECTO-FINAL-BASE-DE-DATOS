<?php
$mecanicos = lookup_options('mecanicos');
$buses = lookup_options('buses');
$mantenciones = db_rows('LEHZ_PS_LISTAR_MANTENCIONES');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Registrar mantencion</h3>
        <div class="text-body-secondary small mt-1">Oracle bloquea fechas futuras y buses asignados a un viaje ese dia.</div>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="mantencion">
            <div class="col-md-6">
                <label class="form-label" for="mantFecha">Fecha</label>
                <input class="form-control" type="date" id="mantFecha" name="fecha" required min="<?= date('Y-m-d') ?>" value="<?= h(old_value('fecha')) ?>">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="mantCosto">Costo</label>
                <input class="form-control" type="number" id="mantCosto" name="costo" min="0" step="1" required value="<?= h(old_value('costo')) ?>">
            </div>
            <div class="col-12">
                <label class="form-label" for="mantDescripcion">Descripcion</label>
                <input class="form-control" id="mantDescripcion" name="descripcion" required maxlength="500" value="<?= h(old_value('descripcion')) ?>" placeholder="Trabajo realizado">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="mantMecanico">Mecanico</label>
                <select class="form-select" id="mantMecanico" name="rut_mecanico" required>
                    <option value="">Seleccione un mecanico...</option>
                    <?php foreach ($mecanicos as $m): ?>
                        <option value="<?= h($m['value']) ?>" <?= (string)old_value('rut_mecanico') === (string)$m['value'] ? 'selected' : '' ?>><?= h($m['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="mantBus">Bus</label>
                <select class="form-select" id="mantBus" name="patente_bus" required>
                    <option value="">Seleccione un bus...</option>
                    <?php foreach ($buses as $b): ?>
                        <option value="<?= h($b['value']) ?>" <?= (string)old_value('patente_bus') === (string)$b['value'] ? 'selected' : '' ?>><?= h($b['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-tools me-1"></i>Registrar mantencion</button>
            </div>
        </form>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Mantenciones registradas</h3>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
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
                <?php if (!$mantenciones): ?><tr><td colspan="7" class="text-center text-body-secondary py-4">No hay mantenciones registradas.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
