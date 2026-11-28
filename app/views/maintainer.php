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
<div class="card mb-4">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <div>
            <h3 class="card-title mb-0"><?= h($meta['title']) ?></h3>
            <div class="text-body-secondary small mt-1">
                Las altas, cambios y bajas se ejecutan con el procedimiento <?= h($meta['proc']) ?>.
            </div>
        </div>
        <input class="form-control filter-input" type="search" data-filter="maintainerBody" placeholder="Filtrar registros..." aria-label="Filtrar registros" style="max-width: 18rem;">
        <button class="btn btn-primary" type="button" onclick="openCreate()">
            <i class="bi bi-plus-lg me-1"></i>Nuevo registro
        </button>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead>
                    <tr>
                        <?php foreach ($columns as $col): ?><th><?= h(column_label($col)) ?></th><?php endforeach; ?>
                        <th class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody id="maintainerBody">
                <?php foreach ($rows as $row): ?>
                    <?php
                    // Esta parte del código se encarga de bloquear la baja cuando Oracle informa dependencias en la fila.
                    $deleteLabel = (string)($row[$meta['id'][0]['name']] ?? '');
                    $blockedDelete = false;
                    foreach (['TIENE_DEPENDENCIAS', 'DEPENDENCIAS', 'BLOQUEADO'] as $flag) {
                        $flagValue = strtoupper(trim((string)($row[$flag] ?? '')));
                        if (in_array($flagValue, ['S', '1', 'Y', 'TRUE', 'ON', 'YES'], true) || (is_numeric($flagValue) && (float)$flagValue > 0)) {
                            $blockedDelete = true;
                            break;
                        }
                    }
                    if (isset($row['ELIMINABLE'])) {
                        $flagValue = strtoupper(trim((string)$row['ELIMINABLE']));
                        if (in_array($flagValue, ['N', '0', 'NO', 'FALSE', 'OFF'], true)) {
                            $blockedDelete = true;
                        }
                    }
                    $confirmMsg = '¿Eliminar ' . ($deleteLabel !== '' ? $deleteLabel : 'este registro') . '? Oracle validara dependencias y mostrara el motivo si no es posible.';
                    $deleteAttrs = $blockedDelete ? 'disabled title="No se puede eliminar: tiene dependencias."' : 'title="Eliminar"';
                    ?>
                    <tr>
                        <?php foreach ($columns as $col): ?><td><?= h(format_cell($col, $row[$col] ?? null)) ?></td><?php endforeach; ?>
                        <td class="text-end text-nowrap">
                            <button class="btn btn-sm btn-outline-primary" type="button" title="Editar" onclick='editMaintainer(<?= h(json_encode($row, JSON_UNESCAPED_UNICODE | JSON_HEX_APOS | JSON_HEX_QUOT)) ?>)'>
                                <i class="bi bi-pencil"></i>
                            </button>
                            <form method="post" class="d-inline" onsubmit="return confirm(<?= h(json_encode($confirmMsg, JSON_UNESCAPED_UNICODE | JSON_HEX_APOS | JSON_HEX_QUOT)) ?>);">
                                <input type="hidden" name="action" value="maintainer">
                                <input type="hidden" name="module" value="<?= h($key) ?>">
                                <input type="hidden" name="op" value="D">
                                <?php foreach ($meta['id'] as $id): ?>
                                    <input type="hidden" name="original_<?= h($id['name']) ?>" value="<?= h($row[$id['name']] ?? '') ?>">
                                <?php endforeach; ?>
                                <button class="btn btn-sm btn-outline-danger" type="submit" <?= $deleteAttrs ?>><i class="bi bi-trash"></i></button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
                <?php if (!$rows): ?>
                    <tr><td colspan="<?= count($columns) + 1 ?>" class="text-center text-body-secondary py-4">Todavia no hay registros.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<div class="modal fade" id="recordModal" tabindex="-1" aria-labelledby="modalTitle" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
        <form method="post" id="recordForm" class="modal-content">
            <div class="modal-header">
                <div>
                    <div class="text-uppercase small text-body-secondary fw-semibold">Formulario</div>
                    <h5 class="modal-title" id="modalTitle">Nuevo registro</h5>
                </div>
                <button class="btn-close" type="button" onclick="closeModal()" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" name="action" value="maintainer">
                <input type="hidden" name="module" value="<?= h($key) ?>">
                <input type="hidden" name="op" id="formOp" value="<?= in_array(old_value('op'), ['I', 'U'], true) ? h(old_value('op')) : 'I' ?>">

                <div class="row g-3">
                    <?php foreach ($meta['id'] as $id): ?>
                        <?php if (!empty($id['auto'])): ?>
                            <input type="hidden" name="original_<?= h($id['name']) ?>" id="orig_<?= h($id['name']) ?>" value="<?= h(old_value('original_' . $id['name'])) ?>">
                        <?php else: ?>
                            <div class="col-md-6" id="idwrap_<?= h($id['name']) ?>">
                                <label class="form-label" for="field_<?= h($id['name']) ?>"><?= h($id['label'] ?? column_label($id['name'])) ?></label>
                                <?php if (isset($id['source'])): ?>
                                    <select class="form-select" name="<?= h($id['name']) ?>" id="field_<?= h($id['name']) ?>" data-idfield="1" required>
                                        <option value="">Seleccione...</option>
                                        <?php foreach (lookup_options($id['source']) as $option): ?>
                                            <option value="<?= h($option['value']) ?>" <?= (string)old_value($id['name']) === (string)$option['value'] ? 'selected' : '' ?>><?= h($option['label']) ?></option>
                                        <?php endforeach; ?>
                                    </select>
                                <?php else: ?>
                                    <input
                                        class="form-control"
                                        type="<?= ($id['type'] ?? 'text') === 'number' ? 'number' : 'text' ?>"
                                        name="<?= h($id['name']) ?>"
                                        id="field_<?= h($id['name']) ?>"
                                        data-idfield="1"
                                        <?= str_starts_with($id['name'], 'RUT_') ? 'data-rut="1"' : '' ?>
                                        placeholder="<?= h($id['placeholder'] ?? '') ?>"
                                        required
                                        value="<?= h(old_value($id['name'])) ?>">
                                <?php endif; ?>
                                <input type="hidden" name="original_<?= h($id['name']) ?>" id="orig_<?= h($id['name']) ?>" value="<?= h(old_value('original_' . $id['name'])) ?>">
                            </div>
                        <?php endif; ?>
                    <?php endforeach; ?>

                    <?php foreach ($meta['fields'] as $field): ?>
                        <?php if (in_array($field['type'], ['select', 'domain'], true)): ?>
                            <?php if (($field['source'] ?? '') === 'comunas_chile'): ?>
                                <?php
                                // Esta parte del código se encarga de usar la vista de comunas de Oracle para el autocompletado.
                                $comunaOpts = [];
                                foreach (db_rows('LHAOMRJZ_PS_LISTAR_COMUNAS_CHILE') as $opt) {
                                    $comunaOpts[] = ['value' => $opt['NOMBRE_COMUNA'], 'label' => $opt['NOMBRE_COMUNA'], 'group' => $opt['NOMBRE_REGION']];
                                }
                                ?>
                                <div class="col-md-6">
                                    <label class="form-label" for="ac_<?= h($field['name']) ?>"><?= h($field['label']) ?></label>
                                    <div class="position-relative">
                                        <input type="hidden" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" value="<?= h(old_value($field['name'])) ?>">
                                        <input type="text" class="form-control ac-input" id="ac_<?= h($field['name']) ?>" placeholder="Buscar comuna..." autocomplete="off" value="<?= h(old_value($field['name'])) ?>" <?= field_required($field) ? 'required' : '' ?>>
                                        <div class="ac-dropdown list-group shadow" id="acdd_<?= h($field['name']) ?>"></div>
                                    </div>
                                    <script>window.LHAOMRJZ_AC = window.LHAOMRJZ_AC || {}; window.LHAOMRJZ_AC['<?= h($field['name']) ?>'] = <?= json_encode($comunaOpts, JSON_UNESCAPED_UNICODE) ?>;</script>
                                </div>
                            <?php else: ?>
                                <?php if (($field['source'] ?? '') === 'regiones_chile'): ?>
                                    <?php
                                    $regionOpts = [];
                                    foreach (field_options($field) as $option) {
                                        $regionOpts[] = ['value' => $option['value'], 'label' => $option['label']];
                                    }
                                    ?>
                                    <div class="col-md-6">
                                        <label class="form-label" for="ac_<?= h($field['name']) ?>"><?= h($field['label']) ?></label>
                                        <div class="position-relative">
                                            <input type="hidden" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" value="<?= h(old_value($field['name'])) ?>">
                                            <input type="text" class="form-control ac-input" id="ac_<?= h($field['name']) ?>" placeholder="Buscar region..." autocomplete="off" value="<?= h(old_value($field['name'])) ?>" <?= field_required($field) ? 'required' : '' ?>>
                                            <div class="ac-dropdown list-group shadow" id="acdd_<?= h($field['name']) ?>"></div>
                                        </div>
                                        <script>window.LHAOMRJZ_AC = window.LHAOMRJZ_AC || {}; window.LHAOMRJZ_AC['<?= h($field['name']) ?>'] = <?= json_encode($regionOpts, JSON_UNESCAPED_UNICODE) ?>;</script>
                                    </div>
                                <?php else: ?>
                                    <div class="col-md-6">
                                        <label class="form-label" for="field_<?= h($field['name']) ?>"><?= h($field['label']) ?></label>
                                        <select class="form-select" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" <?= field_required($field) ? 'required' : '' ?>>
                                            <option value="">Seleccione...</option>
                                            <?php foreach (field_options($field) as $option): ?>
                                                <option value="<?= h($option['value']) ?>" <?= (string)old_value($field['name']) === (string)$option['value'] ? 'selected' : '' ?>><?= h($option['label']) ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                    </div>
                                <?php endif; ?>
                            <?php endif; ?>
                        <?php elseif ($field['type'] === 'textarea'): ?>
                            <div class="col-12">
                                <label class="form-label" for="field_<?= h($field['name']) ?>"><?= h($field['label']) ?></label>
                                <textarea class="form-control" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" rows="3" <?= field_required($field) ? 'required' : '' ?>><?= h(old_value($field['name'])) ?></textarea>
                            </div>
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
                                <div class="col-md-6">
                                    <label class="form-label" for="num_<?= h($field['name']) ?>"><?= h($field['label']) ?></label>
                                    <div class="input-group">
                                        <select class="form-select phone-prefix" data-target="field_<?= h($field['name']) ?>">
                                            <option value="+56 9" <?= $prefix === '+56 9' ? 'selected' : '' ?>>+56 9</option>
                                            <option value="600" <?= $prefix === '600' ? 'selected' : '' ?>>600</option>
                                            <option value="809" <?= $prefix === '809' ? 'selected' : '' ?>>809</option>
                                        </select>
                                        <input class="form-control" type="tel" id="num_<?= h($field['name']) ?>" placeholder="912345678" maxlength="9" value="<?= h($num) ?>" data-phone-number="1" <?= field_required($field) ? 'required' : '' ?>>
                                        <input type="hidden" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>" value="<?= h($pv) ?>">
                                    </div>
                                </div>
                            <?php else: ?>
                                <div class="col-md-6">
                                    <label class="form-label" for="field_<?= h($field['name']) ?>"><?= h($field['label']) ?></label>
                                    <input class="form-control" type="<?= h($inputType) ?>" name="<?= h($field['name']) ?>" id="field_<?= h($field['name']) ?>"
                                           placeholder="<?= h($field['placeholder'] ?? '') ?>"<?= $extra ?>
                                           value="<?= h(old_value($field['name'])) ?>" <?= field_required($field) ? 'required' : '' ?>>
                                </div>
                            <?php endif; ?>
                        <?php endif; ?>
                    <?php endforeach; ?>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" type="button" onclick="closeModal()">Cancelar</button>
                <button class="btn btn-primary" type="submit">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
window.LHAOMRJZ_MAINTAINER = {
    id: <?= json_encode($meta['id'], JSON_UNESCAPED_UNICODE) ?>,
    fields: <?= json_encode($meta['fields'], JSON_UNESCAPED_UNICODE) ?>
};
<?php if (!empty($_SESSION['old'])): ?>
document.addEventListener('DOMContentLoaded', function () {
    var modal = document.getElementById('recordModal');
    if (!modal) return;
    if (window.bootstrap && bootstrap.Modal) {
        bootstrap.Modal.getOrCreateInstance(modal).show();
    } else {
        modal.classList.add('show');
        modal.style.display = 'block';
    }
    document.getElementById('modalTitle').textContent = 'Revisar datos';
    var op = document.getElementById('formOp').value;
    if (op === 'U') {
        document.querySelectorAll('[data-idfield]').forEach(function (el) { el.disabled = true; });
    }
});
<?php endif; ?>
</script>
