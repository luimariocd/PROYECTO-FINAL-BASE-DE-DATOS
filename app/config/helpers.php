<?php
require_once __DIR__ . '/database.php';

function h($value): string {
    return htmlspecialchars((string)($value ?? ''), ENT_QUOTES, 'UTF-8');
}

function column_label(string $column): string {
    if (str_ends_with($column, '_TEXTO')) {
        $column = substr($column, 0, -6);
    }
    $special = [
        'ID_REGION' => 'ID region',
        'ID_COMUNA' => 'ID comuna',
        'ID_TERMINAL' => 'ID terminal',
        'RUT_EMPRESA' => 'RUT empresa',
        'RUT_CONDUCTOR' => 'RUT conductor',
        'RUT_MECANICO' => 'RUT mecanico',
        'RUT_PASAJERO' => 'RUT pasajero',
        'PATENTE_BUS' => 'Patente bus',
        'NUMERO_ASIENTO' => 'Asiento',
        'ANIO_FABRICACION' => 'Anio fabricacion',
        'CORREO_ELECTRONICO_EMPRESA' => 'Correo empresa',
        'CORREO_ELECTRONICO_PASAJERO' => 'Correo pasajero',
        'TIPO_SERVICIO' => 'Tipo servicio',
        'CANTIDAD_PISOS' => 'Pisos',
        'TARIFA_BASE' => 'Tarifa base',
        'PERMITE_BAJADA' => 'Permite bajada',
    ];
    if (isset($special[$column])) {
        return $special[$column];
    }
    return ucfirst(strtolower(str_replace('_', ' ', $column)));
}

function is_money_column(string $column): bool {
    foreach (['VALOR', 'MONTO', 'COSTO', 'TARIFA', 'RECAUDACION', 'PROMEDIO'] as $needle) {
        if (str_contains($column, $needle)) {
            return true;
        }
    }
    return false;
}

function format_cell(string $column, $value): string {
    if ($value === null || $value === '') {
        return '-';
    }
    if (is_money_column($column) && is_numeric($value)) {
        return '$' . number_format((float)$value, 0, ',', '.');
    }
    return (string)$value;
}

function lookup_options(string $source): array {
    static $cache = [];
    if (isset($cache[$source])) {
        return $cache[$source];
    }
    $lookups = $GLOBALS['LEHZ_LOOKUPS'] ?? [];
    if (!isset($lookups[$source])) {
        return [];
    }
    $def = $lookups[$source];
    $rows = db_rows($def['proc']);
    $options = [];
    foreach ($rows as $row) {
        $parts = [];
        foreach ($def['label'] as $col) {
            $v = $row[$col] ?? null;
            if ($v !== null && $v !== '') {
                $parts[] = $v;
            }
        }
        $options[] = [
            'value' => $row[$def['value']] ?? '',
            'label' => implode(' - ', $parts),
        ];
    }
    $cache[$source] = $options;
    return $options;
}

function domain_options(string $domain): array {
    static $cache = [];
    if (isset($cache[$domain])) {
        return $cache[$domain];
    }
    $rows = db_query(
        'SELECT VALOR, ETIQUETA FROM LEHZ_VW_DOMINIOS WHERE DOMINIO = :p_dominio ORDER BY VALOR',
        ['p_dominio' => $domain]
    );
    $options = [];
    foreach ($rows as $row) {
        $options[] = ['value' => $row['VALOR'], 'label' => $row['ETIQUETA']];
    }
    $cache[$domain] = $options;
    return $options;
}

function field_options(array $field): array {
    if (($field['type'] ?? '') === 'domain') {
        return domain_options($field['domain']);
    }
    if (($field['type'] ?? '') === 'select' && isset($field['source'])) {
        return lookup_options($field['source']);
    }
    return [];
}

function can_access(string $module): bool {
    static $cache = [];
    if (isset($cache[$module])) {
        return $cache[$module];
    }
    $role = auth_role();
    if ($role === '') {
        return false;
    }
    $result = db_scalar(
        'SELECT LEHZ_FN_ROL_PERMITE(:p_rol, :p_modulo) FROM DUAL',
        ['p_rol' => $role, 'p_modulo' => $module]
    );
    $cache[$module] = ((string)$result === 'S');
    return $cache[$module];
}

function menu_items(): array {
    static $items = null;
    if ($items !== null) {
        return $items;
    }
    if (!auth_user()) {
        return [];
    }
    $items = db_rows('LEHZ_PS_LISTAR_MENU', ['p_rol' => auth_role()]);
    return $items;
}

function bind_expression(string $param, string $type, string $domain = ''): string {
    if ($type === 'date') {
        return "TO_DATE(:{$param}, 'YYYY-MM-DD')";
    }
    if ($type === 'datetime-local') {
        return "TO_TIMESTAMP(:{$param}, 'YYYY-MM-DD\"T\"HH24:MI')";
    }
    if ($type === 'number' || ($type === 'domain' && $domain === 'CANTIDAD_PISOS')) {
        return "TO_NUMBER(:{$param})";
    }
    return ":{$param}";
}

function clean_input(string $type, $value) {
    if (is_string($value)) {
        $value = trim($value);
    }
    if ($value === '' || $value === null) {
        return null;
    }
    return $value;
}

function old_value(string $name, $default = '') {
    return $_SESSION['old'][$name] ?? $default;
}

function clear_old(): void {
    unset($_SESSION['old']);
}
