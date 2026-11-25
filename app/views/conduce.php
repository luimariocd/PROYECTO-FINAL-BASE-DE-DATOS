<?php
$conductores = lookup_options('conductores');
$buses = lookup_options('buses');
$viajes = lookup_options('viajes');
$asignaciones = db_rows('LEHZ_PS_LISTAR_CONDUCE');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Asignar conductor y bus</h3>
        <div class="text-body-secondary small mt-1">Oracle valida licencia vigente, disponibilidad del bus y duplicados.</div>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="conduce">
            <div class="col-md-6">
                <label class="form-label" for="conduceConductor">Conductor</label>
                <select class="form-select" name="rut_conductor" id="conduceConductor" required>
                    <option value="">Seleccione un conductor...</option>
                    <?php foreach ($conductores as $c): ?>
                        <option value="<?= h($c['value']) ?>" <?= (string)old_value('rut_conductor') === (string)$c['value'] ? 'selected' : '' ?>><?= h($c['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="conduceBus">Bus</label>
                <select class="form-select" name="patente_bus" id="conduceBus" required>
                    <option value="">Seleccione un bus...</option>
                    <?php foreach ($buses as $b): ?>
                        <option value="<?= h($b['value']) ?>" <?= (string)old_value('patente_bus') === (string)$b['value'] ? 'selected' : '' ?>><?= h($b['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12">
                <label class="form-label" for="conduceViaje">Viaje</label>
                <select class="form-select" name="id_viaje" id="conduceViaje" required>
                    <option value="">Seleccione un viaje...</option>
                    <?php foreach ($viajes as $v): ?>
                        <option value="<?= h($v['value']) ?>" <?= (string)old_value('id_viaje') === (string)$v['value'] ? 'selected' : '' ?>><?= h($v['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-diagram-3 me-1"></i>Asignar</button>
            </div>
        </form>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Conductores y buses por viaje</h3>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead><tr><th>Conductor</th><th>Bus</th><th>Viaje</th><th>Fecha</th><th>Ruta</th><th>Salida</th><th class="text-end">Acciones</th></tr></thead>
                <tbody>
                <?php foreach ($asignaciones as $a): ?>
                    <tr>
                        <td><?= h($a['CONDUCTOR']) ?></td>
                        <td><?= h($a['BUS']) ?></td>
                        <td><?= h($a['ID_VIAJE']) ?></td>
                        <td><?= h($a['FECHA_VIAJE']) ?></td>
                        <td><?= h($a['NOMBRE_RUTA']) ?></td>
                        <td><?= h($a['HORA_SALIDA']) ?></td>
                        <td class="text-end text-nowrap">
                            <form method="post" class="d-inline" onsubmit="return confirm('¿Eliminar esta asignacion?');">
                                <input type="hidden" name="action" value="conduce_delete">
                                <input type="hidden" name="rut_conductor" value="<?= h($a['RUT_CONDUCTOR']) ?>">
                                <input type="hidden" name="patente_bus" value="<?= h($a['PATENTE_BUS']) ?>">
                                <input type="hidden" name="id_viaje" value="<?= h($a['ID_VIAJE']) ?>">
                                <button class="btn btn-sm btn-outline-danger" type="submit" title="Eliminar"><i class="bi bi-trash"></i></button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
                <?php if (!$asignaciones): ?><tr><td colspan="7" class="text-center text-body-secondary py-4">No hay asignaciones registradas.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
