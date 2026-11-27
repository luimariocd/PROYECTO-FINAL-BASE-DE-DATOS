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

// Esta parte del código se encarga de usar la vista de dominios de Oracle en vez de repetir SQL.
function domain_options(string $domain): array {
    static $cache = [];
    if (isset($cache[$domain])) {
        return $cache[$domain];
    }
    $rows = db_rows('LEHZ_PS_LISTAR_DOMINIOS', ['p_dominio' => $domain]);
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

// Esta parte del código se encarga de consultar el permiso del rol con la funcion de Oracle del menu.
function can_access(string $module): bool {
    static $cache = [];
    if (isset($cache[$module])) {
        return $cache[$module];
    }
    $role = auth_role();
    if ($role === '') {
        return false;
    }
    $out = db_call(
        'BEGIN LEHZ_PS_ROL_PERMITE(:p_rol, :p_modulo, :p_resultado); END;',
        ['p_rol' => $role, 'p_modulo' => $module, 'p_resultado' => null]
    );
    $result = $out['p_resultado'] ?? 'N';
    $cache[$module] = ((string)$result === 'S');
    return $cache[$module];
}

// Esta parte del código se encarga de reutilizar el mapa de menu para autorizar cada accion.
function can_access_action(string $action, string $module = ''): bool {
    static $map = [
        'sale' => 'venta',
        'annul' => 'venta',
        'use' => 'venta',
        'bajada' => 'bajada',
        'viaje' => 'viaje',
        'conduce' => 'conduce',
        'conduce_delete' => 'conduce',
        'mantencion' => 'mantencion',
        'utilizan' => 'utilizan',
        'utilizan_delete' => 'utilizan',
        'user_create' => 'usuarios',
        'user_state' => 'usuarios',
    ];
    if ($action === 'maintainer') {
        return $module !== '' && can_access($module);
    }
    return isset($map[$action]) && can_access($map[$action]);
}

// Esta parte del código se encarga de validar solo el formato antes de invocar Oracle.
function valid_rut($value): bool {
    $v = strtoupper(trim((string)$value));
    return (bool)preg_match('/^(?:\d{1,2}\.\d{3}\.\d{3}|\d{7,8})-?[\dK]?$/', $v);
}

function valid_phone($value): bool {
    $v = trim((string)$value);
    if (str_starts_with($v, '+') && !str_starts_with($v, '+56')) {
        return false;
    }
    $digits = preg_replace('/\D+/', '', $v);
    return (bool)preg_match('/^(?:569\d{8}|600\d{6}|809\d{6}|\d{8,9})$/', $digits);
}

function valid_date($value): bool {
    $v = trim((string)$value);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $v)) {
        return false;
    }
    $d = DateTime::createFromFormat('!Y-m-d', $v);
    return $d !== false && $d->format('Y-m-d') === $v;
}

function valid_patente($value): bool {
    $v = strtoupper(trim((string)$value));
    return (bool)preg_match('/^(?:[B-DF-HJ-NP-TV-Z]{4}\d{2}|[A-Z]{2}\d{4})$/', $v);
}

function validate_post(array $rules, array $data): array {
    $errors = [];
    foreach ($rules as $name => $rule) {
        $raw = $data[$name] ?? '';
        if (is_array($raw)) {
            $errors[] = ($rule['label'] ?? column_label($name)) . ' no es valido.';
            continue;
        }
        $value = trim((string)$raw);
        $label = $rule['label'] ?? column_label($name);
        if ($value === '') {
            if (!empty($rule['required'])) {
                $errors[] = $label . ' es obligatorio.';
            }
            continue;
        }
        if (isset($rule['in']) && !in_array($value, $rule['in'], true)) {
            $errors[] = $label . ' no es valido.';
            continue;
        }
        $type = $rule['type'] ?? 'text';
        if ($type === 'tel') {
            $type = 'phone';
        }
        if ($type === 'domain' && ($rule['domain'] ?? '') === 'CANTIDAD_PISOS') {
            $type = 'number';
        }
        if ($type === 'rut' && !valid_rut($value)) {
            $errors[] = $label . ' debe tener formato de RUT.';
        } elseif ($type === 'phone' && !valid_phone($value)) {
            $errors[] = $label . ' debe tener formato de telefono chileno.';
        } elseif ($type === 'email' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
            $errors[] = $label . ' debe ser un correo valido.';
        } elseif ($type === 'date' && !valid_date($value)) {
            $errors[] = $label . ' debe ser una fecha valida (YYYY-MM-DD).';
        } elseif ($type === 'datetime-local' && !preg_match('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/', $value)) {
            $errors[] = $label . ' debe tener fecha y hora.';
        } elseif ($type === 'patente' && !valid_patente($value)) {
            $errors[] = $label . ' debe tener formato de patente.';
        } elseif ($type === 'int' && filter_var($value, FILTER_VALIDATE_INT) === false) {
            $errors[] = $label . ' debe ser un numero entero.';
        } elseif ($type === 'number' && !is_numeric($value)) {
            $errors[] = $label . ' debe ser un numero.';
        }
        if (isset($rule['min']) && is_numeric($value) && (float)$value < (float)$rule['min']) {
            $errors[] = $label . ' no puede ser menor a ' . $rule['min'] . '.';
        }
        if (isset($rule['max']) && is_numeric($value) && (float)$value > (float)$rule['max']) {
            $errors[] = $label . ' no puede ser mayor a ' . $rule['max'] . '.';
        }
        if (isset($rule['max_date']) && valid_date($value) && $value > $rule['max_date']) {
            $errors[] = $label . ' no puede ser futura.';
        }
        if (isset($rule['max_length'])) {
            $len = function_exists('mb_strlen') ? mb_strlen($value, 'UTF-8') : strlen($value);
            if ($len > (int)$rule['max_length']) {
                $errors[] = $label . ' es demasiado largo.';
            }
        }
    }
    return $errors;
}

function action_validation_errors(string $action, array $post): array {
    $today = date('Y-m-d');
    $rules = [
        'sale' => [
            'rut_pasajero' => ['label' => 'Pasajero', 'required' => true, 'type' => 'rut'],
            'id_viaje' => ['label' => 'Viaje', 'required' => true, 'type' => 'int', 'min' => 1],
            'numero_asiento' => ['label' => 'Asiento', 'required' => true, 'type' => 'int', 'min' => 1],
            'patente_bus' => ['label' => 'Bus', 'required' => true, 'type' => 'patente'],
            'metodo_pago' => ['label' => 'Metodo de pago', 'required' => true],
            'id_terminal_bajada' => ['label' => 'Terminal de bajada', 'type' => 'int', 'min' => 1],
        ],
        'annul' => [
            'id_boleto' => ['label' => 'Boleto', 'required' => true, 'type' => 'int', 'min' => 1],
            'motivo' => ['label' => 'Motivo', 'required' => true, 'max_length' => 200],
        ],
        'use' => ['id_boleto' => ['label' => 'Boleto', 'required' => true, 'type' => 'int', 'min' => 1]],
        'bajada' => [
            'id_boleto' => ['label' => 'Boleto', 'required' => true, 'type' => 'int', 'min' => 1],
            'id_terminal_bajada' => ['label' => 'Terminal de bajada', 'required' => true, 'type' => 'int', 'min' => 1],
            'observacion' => ['label' => 'Observacion', 'max_length' => 150],
        ],
        'viaje' => [
            'fecha_viaje' => ['label' => 'Fecha del viaje', 'required' => true, 'type' => 'date'],
            'id_horario' => ['label' => 'Horario', 'required' => true, 'type' => 'int', 'min' => 1],
            'id_ruta' => ['label' => 'Ruta', 'required' => true, 'type' => 'int', 'min' => 1],
        ],
        'conduce' => [
            'rut_conductor' => ['label' => 'Conductor', 'required' => true, 'type' => 'rut'],
            'patente_bus' => ['label' => 'Bus', 'required' => true, 'type' => 'patente'],
            'id_viaje' => ['label' => 'Viaje', 'required' => true, 'type' => 'int', 'min' => 1],
        ],
        'conduce_delete' => [
            'rut_conductor' => ['label' => 'Conductor', 'required' => true, 'type' => 'rut'],
            'patente_bus' => ['label' => 'Bus', 'required' => true, 'type' => 'patente'],
            'id_viaje' => ['label' => 'Viaje', 'required' => true, 'type' => 'int', 'min' => 1],
        ],
        'mantencion' => [
            'fecha' => ['label' => 'Fecha', 'required' => true, 'type' => 'date', 'max_date' => $today],
            'descripcion' => ['label' => 'Descripcion', 'required' => true, 'max_length' => 500],
            'costo' => ['label' => 'Costo', 'required' => true, 'type' => 'number', 'min' => 0],
            'rut_mecanico' => ['label' => 'Mecanico', 'required' => true, 'type' => 'rut'],
            'patente_bus' => ['label' => 'Bus', 'required' => true, 'type' => 'patente'],
        ],
        'utilizan' => [
            'id_terminal' => ['label' => 'Terminal', 'required' => true, 'type' => 'int', 'min' => 1],
            'rut_empresa' => ['label' => 'Empresa', 'required' => true, 'type' => 'rut'],
        ],
        'utilizan_delete' => [
            'id_terminal' => ['label' => 'Terminal', 'required' => true, 'type' => 'int', 'min' => 1],
            'rut_empresa' => ['label' => 'Empresa', 'required' => true, 'type' => 'rut'],
        ],
        'user_create' => [
            'nombre_completo' => ['label' => 'Nombre completo', 'required' => true],
            'username' => ['label' => 'Nombre de usuario', 'required' => true],
            'email' => ['label' => 'Correo electronico', 'required' => true, 'type' => 'email'],
            'rol' => ['label' => 'Rol', 'required' => true],
            'password' => ['label' => 'Contrasena', 'required' => true],
            'password_confirm' => ['label' => 'Repetir contrasena', 'required' => true],
        ],
        'user_state' => [
            'id_usuario' => ['label' => 'Usuario', 'required' => true, 'type' => 'int', 'min' => 1],
            'estado' => ['label' => 'Estado', 'required' => true, 'in' => ['ACTIVO', 'INACTIVO']],
        ],
    ];
    if (!isset($rules[$action])) {
        return ['Accion no reconocida.'];
    }
    $errors = validate_post($rules[$action], $post);
    if ($action === 'user_create'
        && trim((string)($post['password'] ?? '')) !== trim((string)($post['password_confirm'] ?? ''))) {
        $errors[] = 'Las contrasenas no coinciden.';
    }
    return $errors;
}

// Esta parte del código se encarga de respetar los campos opcionales que Oracle permite vacios.
function field_required(array $field): bool {
    static $optional = [
        'NUMERO', 'MARCA', 'MODELO', 'TELEFONO', 'ESPECIALIDAD', 'TIPO_SERVICIO', 'PERMITE_BAJADA',
        'APELLIDO2_CONDUCTOR', 'APELLIDO2_MECANICO', 'APELLIDO2_PASAJERO',
        'CORREO_ELECTRONICO_EMPRESA', 'CORREO_ELECTRONICO_PASAJERO',
    ];
    return !in_array($field['name'] ?? '', $optional, true);
}

function maintainer_validation_errors(array $meta, string $op, array $post, array $overrides = []): array {
    $rules = [];
    foreach ($meta['id'] as $id) {
        $name = $id['name'];
        $label = $id['label'] ?? column_label($name);
        $type = ($id['type'] ?? '') === 'number' ? 'int' : 'text';
        if (str_starts_with($name, 'RUT_')) {
            $type = 'rut';
        } elseif (str_starts_with($name, 'PATENTE_')) {
            $type = 'patente';
        }
        $key = (!empty($id['auto']) || $op !== 'I') ? 'original_' . $name : $name;
        if ($op === 'I' && !empty($id['auto'])) {
            continue;
        }
        $rules[$key] = ['label' => $label, 'required' => true, 'type' => $type];
    }
    if (in_array($op, ['I', 'U'], true)) {
        foreach ($meta['fields'] as $field) {
            $rules[$field['name']] = [
                'label' => $field['label'] ?? column_label($field['name']),
                'required' => field_required($field),
                'type' => $field['type'] ?? 'text',
                'domain' => $field['domain'] ?? '',
            ];
        }
    }
    return validate_post($rules, array_merge($post, $overrides));
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
    if (is_array($value)) {
        return null;
    }
    if (is_string($value)) {
        $value = trim($value);
    }
    if ($value === '' || $value === null) {
        return null;
    }
    return $value;
}

// Esta parte del código se encarga de limitar los valores recuperados al modulo que los pidio.
function old_value(string $name, $default = '') {
    $old = $_SESSION['old'] ?? null;
    if (!is_array($old)) {
        return $default;
    }
    if (isset($old['data'])) {
        if (($old['scope'] ?? '') !== ($GLOBALS['LEHZ_OLD_SCOPE'] ?? '')) {
            return $default;
        }
        return $old['data'][$name] ?? $default;
    }
    return $old[$name] ?? $default;
}

function clear_old(?string $scope = null): void {
    if ($scope === null || (($_SESSION['old']['scope'] ?? '') === $scope)) {
        unset($_SESSION['old']);
    }
}
