<?php
$rows = db_rows($report['proc']);
$columns = $rows ? array_keys($rows[0]) : [];

/**
 * Funciones de apoyo para los graficos del reporte.
 * Trabajan solo con los datos ya devueltos por Oracle; no inventan informacion.
 */
function lehz_report_money(array $row, array $cols): float {
    foreach ($cols as $col) {
        if (is_money_column($col) && is_numeric($row[$col] ?? null)) {
            return (float)$row[$col];
        }
    }
    return 0.0;
}
function lehz_report_money_col(array $cols): ?string {
    foreach ($cols as $col) {
        if (is_money_column($col)) return $col;
    }
    return null;
}
function lehz_report_axis_col(array $cols, array $rows): ?string {
    foreach ($cols as $col) {
        if (stripos($col, 'FECHA') !== false) return $col;
    }
    if (!$rows) return null;
    foreach ($cols as $col) {
        foreach ($rows as $row) {
            $v = (string)($row[$col] ?? '');
            if ($v !== '' && preg_match('/^\d{2}\/\d{2}\/\d{4}|^\d{4}-\d{2}-\d{2}/', $v)) return $col;
        }
    }
    return null;
}
function lehz_report_category_col(array $cols): ?string {
    $preferred = ['NOMBRE', 'RAZON', 'RUTA', 'PATENTE', 'EMPRESA', 'TERMINAL'];
    foreach ($preferred as $needle) {
        foreach ($cols as $col) {
            if (!is_money_column($col) && stripos($col, $needle) !== false) return $col;
        }
    }
    foreach ($cols as $col) {
        if (is_money_column($col) || stripos($col, 'ID_') === 0 || stripos($col, 'FECHA') !== false) continue;
        if (!preg_match('/(CANTIDAD|TOTAL|NUMERO|CODIGO)/', $col)) return $col;
    }
    return null;
}
function lehz_report_compact(float $value): string {
    $abs = abs($value);
    if ($abs >= 1000000) return '$' . number_format($value / 1000000, 1, ',', '.') . 'M';
    if ($abs >= 1000) return '$' . number_format($value / 1000, 1, ',', '.') . 'k';
    return '$' . number_format($value, 0, ',', '.');
}
function lehz_report_short_date($value): string {
    $value = (string)$value;
    if (preg_match('/^(\d{2})\/(\d{2})\/(\d{4})/', $value, $m)) {
        return $m[1] . '/' . $m[2];
    }
    if (preg_match('/^(\d{4})-(\d{2})-(\d{2})/', $value, $m)) {
        return $m[3] . '/' . $m[2];
    }
    return $value === '' ? '-' : $value;
}
function lehz_report_date_key($value): string {
    $value = (string)$value;
    if (preg_match('/^(\d{2})\/(\d{2})\/(\d{4})/', $value, $m)) return $m[3] . $m[2] . $m[1];
    if (preg_match('/^(\d{4})-(\d{2})-(\d{2})/', $value, $m)) return $m[1] . $m[2] . $m[3];
    return $value;
}

$moneyCol = lehz_report_money_col($columns);
$axisCol = lehz_report_axis_col($columns, $rows);
$categoryCol = lehz_report_category_col($columns);

$daily = [];
$byCategory = [];
$total = 0.0;
$units = 0;
foreach ($rows as $row) {
    $amount = lehz_report_money($row, $columns);
    $total += $amount;
    if ($axisCol !== null && $moneyCol !== null) {
        $key = lehz_report_date_key($row[$axisCol] ?? '');
        if (!isset($daily[$key])) {
            $daily[$key] = ['label' => lehz_report_short_date($row[$axisCol] ?? ''), 'value' => 0.0, 'units' => 0];
        }
        $daily[$key]['value'] += $amount;
        if (isset($row['TOTAL_BOLETOS_VENDIDOS']) && is_numeric($row['TOTAL_BOLETOS_VENDIDOS'])) {
            $daily[$key]['units'] += (int)$row['TOTAL_BOLETOS_VENDIDOS'];
        }
    }
    if ($categoryCol !== null && $moneyCol !== null) {
        $label = trim((string)($row[$categoryCol] ?? ''));
        if ($label === '') $label = 'Sin categoria';
        if (!isset($byCategory[$label])) $byCategory[$label] = 0.0;
        $byCategory[$label] += $amount;
    }
    if (isset($row['TOTAL_BOLETOS_VENDIDOS']) && is_numeric($row['TOTAL_BOLETOS_VENDIDOS'])) {
        $units += (int)$row['TOTAL_BOLETOS_VENDIDOS'];
    }
}
ksort($daily);
arsort($byCategory);
$byCategory = array_slice($byCategory, 0, 6, true);
$maxDaily = 0.0;
$maxUnits = 0;
foreach ($daily as $d) {
    $maxDaily = max($maxDaily, $d['value']);
    $maxUnits = max($maxUnits, $d['units']);
}

$summary = [['Filas', (string)count($rows)]];
if ($moneyCol !== null) {
    $summary[] = ['Total ' . column_label($moneyCol), '$' . number_format($total, 0, ',', '.')];
    $summary[] = ['Promedio por fila', '$' . number_format($rows ? $total / count($rows) : 0, 0, ',', '.')];
}
if ($units > 0) $summary[] = ['Boletos vendidos', number_format($units, 0, ',', '.')];
if ($daily) $summary[] = ['Dias con datos', (string)count($daily)];

$palette = ['#3563d9', '#00b3a4', '#f5a524', '#7c5cff', '#ef5675', '#38bdf8'];
$donutColors = [];
$donutParts = [];
$donutStart = 0.0;
foreach ($byCategory as $label => $amount) {
    $color = $palette[count($donutColors) % count($palette)];
    $donutColors[] = ['label' => $label, 'value' => $amount, 'color' => $color];
    $share = $total > 0 ? $amount / $total * 100 : 0;
    $donutParts[] = $color . ' ' . $donutStart . '% ' . ($donutStart + $share) . '%';
    $donutStart += $share;
}
$donutStyle = $donutParts
    ? 'background: conic-gradient(' . implode(', ', $donutParts) . ');'
    : 'background: conic-gradient(var(--app-border) 0% 100%);';

$chartId = 'lehzline_' . preg_replace('/[^a-z0-9]/', '', strtolower($report['title']));
?>
<div class="card mb-4">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <div>
            <div class="page-kicker mb-1">Reporte del sistema</div>
            <h3 class="card-title mb-0"><?= h($report['title']) ?></h3>
            <div class="text-body-secondary small mt-1">Datos calculados por <?= h($report['proc']) ?>.</div>
        </div>
        <button class="btn btn-outline-secondary" type="button" onclick="window.print()">
            <i class="bi bi-printer me-1"></i>Imprimir
        </button>
    </div>
    <div class="card-body">
        <div class="row g-3">
            <?php foreach ($summary as [$label, $value]): ?>
                <div class="col-6 col-lg-3">
                    <div class="stat-card h-100 hover-lift">
                        <div class="stat-label"><?= h($label) ?></div>
                        <div class="stat-value mt-1"><?= h($value) ?></div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</div>

<?php if ($daily && $maxDaily > 0): ?>
<div class="row g-3 mb-4">
    <div class="col-12 col-xl-8">
        <div class="card chart-card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="card-title mb-0"><i class="bi bi-graph-up me-2 text-primary"></i>Evolucion por dia</h5>
                    <div class="text-body-secondary small"><?= h(column_label($axisCol)) ?> · <?= h(column_label($moneyCol)) ?></div>
                </div>
                <span class="badge text-bg-primary-subtle text-primary-emphasis rounded-pill"><?= count($daily) ?> dias</span>
            </div>
            <div class="card-body">
                <?php
                $w = 760; $h = 260; $left = 58; $right = 16; $top = 18; $bottom = 34;
                $plotW = $w - $left - $right; $plotH = $h - $top - $bottom;
                $values = array_values($daily);
                $count = count($values);
                $step = $count > 1 ? $plotW / ($count - 1) : 0;
                $pts = [];
                foreach ($values as $i => $d) {
                    $x = $left + ($count > 1 ? $i * $step : $plotW / 2);
                    $y = $top + $plotH - ($maxDaily > 0 ? $d['value'] / $maxDaily * $plotH : 0);
                    $pts[] = [$x, $y, $d['label']];
                }
                $line = implode(' ', array_map(fn($p) => $p[0] . ',' . $p[1], $pts));
                $area = 'M ' . $pts[0][0] . ',' . ($top + $plotH);
                foreach ($pts as $p) $area .= ' L ' . $p[0] . ',' . $p[1];
                $area .= ' L ' . $pts[count($pts) - 1][0] . ',' . ($top + $plotH) . ' Z';
                ?>
                <div class="chart-wrap">
                    <svg viewBox="0 0 <?= $w ?> <?= $h ?>" preserveAspectRatio="none" style="width:100%;height:100%;color:var(--bs-secondary-color)" role="img" aria-label="Grafico de linea: <?= h(column_label($moneyCol)) ?> por dia">
                        <defs>
                            <linearGradient id="<?= $chartId ?>_fill" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0%" stop-color="#3563d9" stop-opacity=".35"/>
                                <stop offset="100%" stop-color="#00b3a4" stop-opacity=".02"/>
                            </linearGradient>
                            <linearGradient id="<?= $chartId ?>_line" x1="0" y1="0" x2="1" y2="0">
                                <stop offset="0%" stop-color="#3563d9"/>
                                <stop offset="100%" stop-color="#00b3a4"/>
                            </linearGradient>
                        </defs>
                        <?php for ($g = 0; $g <= 4; $g++): ?>
                            <?php
                            $gy = $top + $plotH / 4 * $g;
                            $gv = $maxDaily * (1 - $g / 4);
                            ?>
                            <line x1="<?= $left ?>" y1="<?= $gy ?>" x2="<?= $w - $right ?>" y2="<?= $gy ?>" stroke="currentColor" stroke-opacity=".14" stroke-dasharray="4 4"/>
                            <text x="<?= $left - 8 ?>" y="<?= $gy + 4 ?>" text-anchor="end" font-size="10" fill="currentColor"><?= h(lehz_report_compact($gv)) ?></text>
                        <?php endfor; ?>
                        <path d="<?= $area ?>" fill="url(#<?= $chartId ?>_fill)"/>
                        <polyline points="<?= $line ?>" fill="none" stroke="url(#<?= $chartId ?>_line)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
                        <?php foreach ($pts as $i => $p): ?>
                            <circle cx="<?= $p[0] ?>" cy="<?= $p[1] ?>" r="4" fill="var(--app-surface)" stroke="#3563d9" stroke-width="2">
                                <title><?= h($p[2]) ?>: $<?= h(number_format($values[$i]['value'], 0, ',', '.')) ?></title>
                            </circle>
                            <?php
                            $showLabel = $count <= 8 || $i % (int)ceil($count / 7) === 0 || $i === $count - 1;
                            if ($showLabel): ?>
                                <text x="<?= $p[0] ?>" y="<?= $h - 10 ?>" text-anchor="middle" font-size="10" fill="currentColor"><?= h($p[2]) ?></text>
                            <?php endif; ?>
                        <?php endforeach; ?>
                    </svg>
                </div>
                <div class="chart-legend">
                    <span class="legend-item"><span class="legend-swatch" style="background:linear-gradient(90deg,#3563d9,#00b3a4)"></span><?= h(column_label($moneyCol)) ?> por dia</span>
                    <span class="legend-item">Punto = dia con datos · maxima <?= h(lehz_report_compact($maxDaily)) ?></span>
                </div>
            </div>
        </div>
    </div>
    <?php if ($donutColors): ?>
    <div class="col-12 col-xl-4">
        <div class="card chart-card">
            <div class="card-header">
                <h5 class="card-title mb-0"><i class="bi bi-pie-chart me-2 text-info"></i>Distribucion</h5>
                <div class="text-body-secondary small"><?= h(column_label($categoryCol)) ?> · top <?= count($donutColors) ?></div>
            </div>
            <div class="card-body">
                <div class="donut" style="<?= h($donutStyle) ?>">
                    <div class="donut-inner">
                        <div>
                            <div class="donut-value"><?= h(lehz_report_compact($total)) ?></div>
                            <div class="donut-label">Total</div>
                        </div>
                    </div>
                </div>
                <div class="chart-legend mt-3">
                    <?php foreach ($donutColors as $item): ?>
                        <span class="legend-item">
                            <span class="legend-swatch" style="background:<?= $item['color'] ?>"></span>
                            <?= h($item['label']) ?>
                            <b class="ms-1"><?= $total > 0 ? number_format($item['value'] / $total * 100, 0) : 0 ?>%</b>
                        </span>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>
    <?php endif; ?>
</div>
<?php endif; ?>

<?php if ($maxUnits > 0): ?>
<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center">
        <div>
            <h5 class="card-title mb-0"><i class="bi bi-bar-chart-line me-2 text-success"></i>Boletos vendidos por dia</h5>
            <div class="text-body-secondary small">Volumen diario segun los datos del reporte</div>
        </div>
        <span class="badge text-bg-success-subtle text-success-emphasis rounded-pill"><?= number_format($units, 0, ',', '.') ?> boletos</span>
    </div>
    <div class="card-body">
        <div class="chart-bars">
            <?php foreach (array_slice($daily, -8) as $d): ?>
                <div class="chart-bar-row">
                    <span class="text-body-secondary fw-semibold"><?= h($d['label']) ?></span>
                    <span class="chart-bar-track">
                        <span class="chart-bar-fill" style="width:<?= $maxUnits > 0 ? round($d['units'] / $maxUnits * 100, 1) : 0 ?>%"></span>
                    </span>
                    <span class="chart-bar-value"><?= number_format($d['units'], 0, ',', '.') ?></span>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="card mb-4">
    <div class="card-header">
        <h5 class="card-title mb-0"><i class="bi bi-table me-2 text-secondary"></i>Detalle</h5>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead><tr><?php foreach ($columns as $col): ?><th><?= h(column_label($col)) ?></th><?php endforeach; ?></tr></thead>
                <tbody>
                <?php foreach ($rows as $row): ?>
                    <tr>
                        <?php foreach ($columns as $col): ?><td><?= h(format_cell($col, $row[$col] ?? null)) ?></td><?php endforeach; ?>
                    </tr>
                <?php endforeach; ?>
                <?php if (!$rows): ?><tr><td colspan="<?= max(1, count($columns)) ?>" class="text-center text-body-secondary py-4">El reporte no devolvio datos.</td></tr><?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
