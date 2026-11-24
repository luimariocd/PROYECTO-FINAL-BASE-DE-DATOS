<?php
$rows = db_rows($report['proc']);
$columns = $rows ? array_keys($rows[0]) : [];
$summary = [];
if ($rows) {
    $summary[] = ['Filas', count($rows)];
    foreach ($columns as $col) {
        if (is_money_column($col)) {
            $total = 0.0;
            foreach ($rows as $r) {
                $total += (float)($r[$col] ?? 0);
            }
            $summary[] = [column_label($col), '$' . number_format($total, 0, ',', '.')];
        }
    }
}
?>
<section class="panel">
    <div class="panel-head">
        <div>
            <span class="eyebrow">REPORTE ORACLE</span>
            <h3><?= h($report['title']) ?></h3>
            <p>Datos calculados por <?= h($report['proc']) ?>.</p>
        </div>
        <button class="btn ghost" type="button" onclick="window.print()">Imprimir</button>
    </div>
    <?php if ($summary): ?>
        <div class="report-summary">
            <?php foreach ($summary as [$label, $value]): ?>
                <div><span><?= h($label) ?></span><strong><?= h($value) ?></strong></div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
    <div class="table-wrap">
        <table>
            <thead><tr><?php foreach ($columns as $col): ?><th><?= h(column_label($col)) ?></th><?php endforeach; ?></tr></thead>
            <tbody>
            <?php foreach ($rows as $row): ?>
                <tr>
                    <?php foreach ($columns as $col): ?><td><?= h(format_cell($col, $row[$col] ?? null)) ?></td><?php endforeach; ?>
                </tr>
            <?php endforeach; ?>
            <?php if (!$rows): ?><tr><td colspan="<?= max(1, count($columns)) ?>" class="empty">El reporte no devolvio datos.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</section>
