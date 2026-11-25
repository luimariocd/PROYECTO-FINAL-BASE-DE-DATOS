<?php
$horarios = lookup_options('horarios');
$rutas = lookup_options('rutas');
$viajes = db_rows('LEHZ_PS_LISTAR_VIAJES');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Programar viaje</h3>
        <div class="text-body-secondary small mt-1">Oracle rechaza fechas pasadas, duplicados y combinaciones invalidas.</div>
    </div>
<<<<<<< HEAD
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="viaje">
            <div class="col-md-6">
                <label class="form-label" for="viajeFecha">Fecha del viaje</label>
                <input class="form-control" type="date" id="viajeFecha" name="fecha_viaje" required min="<?= date('Y-m-d') ?>" value="<?= h(old_value('fecha_viaje')) ?>">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="viajeHorario">Horario</label>
                <select class="form-select" id="viajeHorario" name="id_horario" required>
                    <option value="">Seleccione un horario...</option>
                    <?php foreach ($horarios as $h): ?>
                        <option value="<?= h($h['value']) ?>" <?= (string)old_value('id_horario') === (string)$h['value'] ? 'selected' : '' ?>><?= h($h['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12">
                <label class="form-label" for="viajeRuta">Ruta</label>
                <select class="form-select" id="viajeRuta" name="id_ruta" required>
                    <option value="">Seleccione una ruta...</option>
                    <?php foreach ($rutas as $r): ?>
                        <option value="<?= h($r['value']) ?>" <?= (string)old_value('id_ruta') === (string)$r['value'] ? 'selected' : '' ?>><?= h($r['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-calendar-plus me-1"></i>Programar viaje</button>
            </div>
        </form>
    </div>
</div>
=======
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
>>>>>>> 05e766dd077aefce9c75935cc0164f80ed0eb28f

<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Viajes programados</h3>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
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
                <?php if (!$viajes): ?><tr><td colspan="9" class="text-center text-body-secondary py-4">No hay viajes programados.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
