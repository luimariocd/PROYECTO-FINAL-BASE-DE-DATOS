<?php
$rows = db_rows($meta['list']);
$columns = [];
if ($rows) {
    $columns = array_keys($rows[0]);
    $visible = [];
    foreach ($columns as $col) {
        if ($col === 'FECHA_ORDEN' || isset($rows[0][$col . '_TEXTO'])) {
            continue;
        }
        $visible[] = $col;
    }
    $columns = $visible ?? $columns;
}
?>
<section class="panel">
    <div class="panel-head">
        <div>
            <span class="eyebrow">GESTION DE DATOS</span>
            <h3><?= h($meta['title']) ?></h3>
            <p>Las altas, cambios y bajas se ejecutan con el procedimiento <?= h($meta['proc']) ?>.</p>
        </div>
        <button class="btn primary" type="button" onclick="openCreate()">+ Nuevo registro</button>
    </div>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <?php foreach ($columns as $col): ?><th><?= h(column_label($col)) ?></th><?php endforeach; ?>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $row): ?>
                <tr>
                    <?php foreach ($columns as $col): ?><td><?= h(format_cell($col, $row[$col] ?? null)) ?></td><?php endforeach; ?>
                    <td class="actions">
                        <button class="icon-btn" type="button" title="Editar" onclick='editMaintainer(<?= h(json_encode($row, JSON_UNESCAPED_UNICODE | JSON_HEX_APOS | JSON_HEX_QUOT)) ?>)'>✎</button>
                        <form method="post" class="inline" onsubmit="return confirm('¿Eliminar este registro?');">
                            <input type="hidden" name="action" value="maintainer">
                            <input type="hidden" name="module" value="<?= h($key) ?>">
                            <input type="hidden" name="op" value="D">
                            <?php foreach ($meta['id'] as $id): ?>
                                <input type="hidden" name="original_<?= h($id['name']) ?>" value="<?= h($row[$id['name']] ?? '') ?>">
                            <?php endforeach; ?>
                            <button class="icon-btn danger" type="submit" title="Eliminar">⌫</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$rows): ?>
                <tr><td colspan="<?= count($columns) + 1 ?>" class="empty">Todavia no hay registros.</td></tr>
            <?php endif; ?>
            </tbody>
        </table>
    </div>
</section>

<div class="modal" id="recordModal">
    <div class="modal-card">
        <div class="modal-head">
            <div><span class="eyebrow">FORMULARIO</span><h3 id="modalTitle">Nuevo registro</h3></div>
            <button class="icon-btn" type="button" onclick="closeModal()">×</button>
        </div>
        <form method="post" id="recordForm">
            <input type="hidden" name="action" value="maintainer">
            <input type="hidden" name="module" value="<?= h($key) ?>">
            <input type="hidden" name="op" id="formOp" value="<?= in_array(old_value('op'), ['I', 'U'], true) ? h(old_value('op')) : 'I' ?>">

            <?php foreach ($meta['id'] as $id): ?>
                <?php if (!empty($id['auto'])): ?>
                    <input type="hidden" name="original_<?= h($id['name']) ?>" id="orig_<?= h($id['name']) ?>" value="<?= h(old_value('original_' . $id['name'])) ?>">
                <?php else: ?>
                    <label id="idwrap_<?= h($id['name']) ?>"><?= h($id['label'] ?? column_label($id['name'])) ?>
                        <?php if (isset($id['source'])): ?>
                            <select name="<?= h($id['name']) ?>" id="field_<?= h($id['name']) ?>" data-idfield="1">
                                <option value="">Seleccione...</option>
                                <?php foreach (lookup_options($id['source']) as $option): ?>
                                    <option value="<?= h($option['value']) ?>" <?= (string)old_value($id['name']) === (string)$option['value'] ? 'selected' : '' ?>><?= h($option['label']) ?></option>
                                <?php endforeach; ?>
                            </select>
                        <?php else: ?>
                            <input
                                type="<?= ($id['type'] ?? 'text') === 'number' ? 'number' : 'text' ?>"
                                name="<?= h($id['name']) ?>"
                                id="field_<?= h($id['name']) ?>"
                                data-idfield="1"
                                <?= str_starts_with($id['name'], 'RUT_') ? 'data-rut="1"' : '' ?>
                                placeholder="<?= h($id['placeholder'] ?? '') ?>"
                                value="<?= h(old_value($id['name'])) ?>">
                        <?php endif; ?>
                    </label>
                    <input type="hidden" name="original_<?= h($id['name']) ?>" id="orig_<?= h($id['name']) ?>" value="<?= h(old_value('original_' . $id['name'])) ?>">
                <?php endif; ?>
            <?php endforeach; ?>

            <?php foreach ($meta['fields'] as $field): ?>
                <label><?= h($field['label']) ?>
                    <?php if (in_array($field['type'], ['select', 'domain'], true)): ?>
                        <?php if (($field['source'] ?? '') === 'comunas_chile'): ?>
                            <?php
                            $comunaOpts = [];
                            foreach (db_query('SELECT NOMBRE_COMUNA, NOMBRE_REGION FROM LEHZ_VW_COMUNAS_CHILE ORDER BY NOMBRE_REGION, NOMBRE_COMUNA') as $opt) {
                                $comunaOpts[] = ['value' => $opt['NOMBRE_COMUNA'], 'label' => $opt['NOMBRE_COMUNA'], 'group' => $opt['NOMBRE_REGION']];
                            }
                            ?>
                            <input type="hidden" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" value="<?= h(old_value($field['name'])) ?>">
                            <input type="text" class="ac-input" id="ac_<?= h($field['name']) ?>" placeholder="Buscar comuna..." autocomplete="off" value="<?= h(old_value($field['name'])) ?>">
                            <div class="ac-dropdown" id="acdd_<?= h($field['name']) ?>"></div>
                            <script>window.LEHZ_AC = window.LEHZ_AC || {}; window.LEHZ_AC['<?= h($field['name']) ?>'] = <?= json_encode($comunaOpts, JSON_UNESCAPED_UNICODE) ?>;</script>
                        <?php else: ?>
                            <?php if (($field['source'] ?? '') === 'regiones_chile'): ?>
                                <?php
                                $regionOpts = [];
                                foreach (field_options($field) as $option) {
                                    $regionOpts[] = ['value' => $option['value'], 'label' => $option['label']];
                                }
                                ?>
                                <input type="hidden" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" value="<?= h(old_value($field['name'])) ?>">
                                <input type="text" class="ac-input" id="ac_<?= h($field['name']) ?>" placeholder="Buscar region..." autocomplete="off" value="<?= h(old_value($field['name'])) ?>">
                                <div class="ac-dropdown" id="acdd_<?= h($field['name']) ?>"></div>
                                <script>window.LEHZ_AC = window.LEHZ_AC || {}; window.LEHZ_AC['<?= h($field['name']) ?>'] = <?= json_encode($regionOpts, JSON_UNESCAPED_UNICODE) ?>;</script>
                            <?php else: ?>
                                <select name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>">
                                    <option value="">Seleccione...</option>
                                    <?php foreach (field_options($field) as $option): ?>
                                        <option value="<?= h($option['value']) ?>" <?= (string)old_value($field['name']) === (string)$option['value'] ? 'selected' : '' ?>><?= h($option['label']) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            <?php endif; ?>
                        <?php endif; ?>
                    <?php elseif ($field['type'] === 'textarea'): ?>
                        <textarea name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" rows="3"><?= h(old_value($field['name'])) ?></textarea>
                    <?php else: ?>
                        <?php
                        if (str_starts_with($field['name'], 'HORA_')) {
                            $inputType = 'time';
                        } else {
                            $inputType = in_array($field['type'], ['number', 'date', 'datetime-local', 'email', 'tel'], true) ? $field['type'] : 'text';
                        }
                        $extra = '';
                        if ($inputType === 'number') {
                            $extra = ' step="any"';
                        }
                        if ($inputType === 'tel') {
                            $extra .= ' data-phone="1"';
                        }
                        if ($inputType === 'date') {
                            $extra .= ' min="' . date('Y-m-d') . '"';
                        }
                        ?>
                        <?php if ($inputType === 'tel'): ?>
                            <?php
                            $pv = (string)old_value($field['name']);
                            $prefix = '+56 9';
                            $num = $pv;
                            if (strpos($pv, '+56 9') === 0) { $prefix = '+56 9'; $num = trim(substr($pv, 5)); }
                            elseif (strpos($pv, '600') === 0) { $prefix = '600'; $num = trim(substr($pv, 3)); }
                            elseif (strpos($pv, '809') === 0) { $prefix = '809'; $num = trim(substr($pv, 3)); }
                            elseif (strpos($pv, '+56') === 0) { $prefix = '+56 9'; $num = trim(substr($pv, 4)); }
                            ?>
                            <span class="phone-row">
                                <select class="phone-prefix" data-target="field_<?= h($field['name']) ?>">
                                    <option value="+56 9" <?= $prefix === '+56 9' ? 'selected' : '' ?>>+56 9</option>
                                    <option value="600" <?= $prefix === '600' ? 'selected' : '' ?>>600</option>
                                    <option value="809" <?= $prefix === '809' ? 'selected' : '' ?>>809</option>
                                </select>
                                <input type="tel" id="num_<?= h($field['name']) ?>" placeholder="" value="<?= h($num) ?>" data-phone-number="1" required>
                                <input type="hidden" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" value="<?= h($pv) ?>">
                            </span>
                        <?php else: ?>
                            <input type="<?= h($inputType) ?>" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>"
                                   placeholder="<?= h($field['placeholder'] ?? '') ?>"<?= $extra ?>
                                   value="<?= h(old_value($field['name'])) ?>">
                        <?php endif; ?>
                    <?php endif; ?>
                </label>
            <?php endforeach; ?>

            <div class="modal-actions">
                <button class="btn ghost" type="button" onclick="closeModal()">Cancelar</button>
                <button class="btn primary" type="submit">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
window.LEHZ_MAINTAINER = {
    id: <?= json_encode($meta['id'], JSON_UNESCAPED_UNICODE) ?>,
    fields: <?= json_encode($meta['fields'], JSON_UNESCAPED_UNICODE) ?>
};
<?php if (!empty($_SESSION['old'])): ?>
document.addEventListener('DOMContentLoaded', function () {
    var modal = document.getElementById('recordModal');
    if (!modal) return;
    modal.classList.add('show');
    document.getElementById('modalTitle').textContent = 'Revisar datos';
    var op = document.getElementById('formOp').value;
    if (op === 'U') {
        document.querySelectorAll('[data-idfield]').forEach(function (el) { el.disabled = true; });
    }
});
<?php endif; ?>
</script>
