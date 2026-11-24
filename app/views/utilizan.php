<?php
$terminales = lookup_options('terminales');
$empresas = lookup_options('empresas');
$utilizan = db_rows('LEHZ_PS_LISTAR_UTILIZAN');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">RELACION OPERATIVA</span><h3>Asociar terminal a empresa</h3><p>Oracle valida la existencia de ambos registros y evita duplicados.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="utilizan">
        <label>Terminal
            <select name="id_terminal" required>
                <option value="">Seleccione un terminal...</option>
                <?php foreach ($terminales as $t): ?>
                    <option value="<?= h($t['value']) ?>" <?= (string)old_value('id_terminal') === (string)$t['value'] ? 'selected' : '' ?>><?= h($t['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Empresa
            <select name="rut_empresa" required>
                <option value="">Seleccione una empresa...</option>
                <?php foreach ($empresas as $e): ?>
                    <option value="<?= h($e['value']) ?>" <?= (string)old_value('rut_empresa') === (string)$e['value'] ? 'selected' : '' ?>><?= h($e['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <div class="form-actions"><button class="btn primary" type="submit">Asociar terminal</button></div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">ASOCIACIONES</span><h3>Terminales utilizados por empresa</h3></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>Terminal</th><th>Comuna</th><th>Empresa</th><th>Acciones</th></tr></thead>
            <tbody>
            <?php foreach ($utilizan as $u): ?>
                <tr>
                    <td><?= h($u['TERMINAL']) ?></td>
                    <td><?= h($u['NOMBRE_COMUNA']) ?></td>
                    <td><?= h($u['RAZON_SOCIAL']) ?></td>
                    <td class="actions">
                        <form method="post" class="inline" onsubmit="return confirm('¿Eliminar esta asociacion?');">
                            <input type="hidden" name="action" value="utilizan_delete">
                            <input type="hidden" name="id_terminal" value="<?= h($u['ID_TERMINAL']) ?>">
                            <input type="hidden" name="rut_empresa" value="<?= h($u['RUT_EMPRESA']) ?>">
                            <button class="icon-btn danger" type="submit" title="Eliminar">⌫</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$utilizan): ?><tr><td colspan="4" class="empty">No hay asociaciones registradas.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>
