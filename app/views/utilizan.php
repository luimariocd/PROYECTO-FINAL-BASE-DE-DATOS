<?php
$terminales = lookup_options('terminales');
$empresas = lookup_options('empresas');
$utilizan = db_rows('LHAOMRJZ_PS_LISTAR_UTILIZAN');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Asociar terminal a empresa</h3>
        <div class="text-body-secondary small mt-1">Oracle valida la existencia de ambos registros y evita duplicados.</div>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="utilizan">
            <div class="col-md-6">
                <label class="form-label" for="utilizaTerminal">Terminal</label>
                <select class="form-select" id="utilizaTerminal" name="id_terminal" required>
                    <option value="">Seleccione un terminal...</option>
                    <?php foreach ($terminales as $t): ?>
                        <option value="<?= h($t['value']) ?>" <?= (string)old_value('id_terminal') === (string)$t['value'] ? 'selected' : '' ?>><?= h($t['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="utilizaEmpresa">Empresa</label>
                <select class="form-select" id="utilizaEmpresa" name="rut_empresa" required>
                    <option value="">Seleccione una empresa...</option>
                    <?php foreach ($empresas as $e): ?>
                        <option value="<?= h($e['value']) ?>" <?= (string)old_value('rut_empresa') === (string)$e['value'] ? 'selected' : '' ?>><?= h($e['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-link-45deg me-1"></i>Asociar terminal</button>
            </div>
        </form>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Terminales utilizados por empresa</h3>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead><tr><th>Terminal</th><th>Comuna</th><th>Empresa</th><th class="text-end">Acciones</th></tr></thead>
                <tbody>
                <?php foreach ($utilizan as $u): ?>
                    <tr>
                        <td><?= h($u['TERMINAL']) ?></td>
                        <td><?= h($u['NOMBRE_COMUNA']) ?></td>
                        <td><?= h($u['RAZON_SOCIAL']) ?></td>
                        <td class="text-end text-nowrap">
                            <form method="post" class="d-inline" onsubmit="return confirm('¿Eliminar esta asociacion?');">
                                <input type="hidden" name="action" value="utilizan_delete">
                                <input type="hidden" name="id_terminal" value="<?= h($u['ID_TERMINAL']) ?>">
                                <input type="hidden" name="rut_empresa" value="<?= h($u['RUT_EMPRESA']) ?>">
                                <button class="btn btn-sm btn-outline-danger" type="submit" title="Eliminar"><i class="bi bi-trash"></i></button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
                <?php if (!$utilizan): ?><tr><td colspan="4" class="text-center text-body-secondary py-4">No hay asociaciones registradas.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
