<?php
session_start();
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../auth/auth.php';

/* =========================================================================
 * CONFIGURACION DE PANTALLAS
 * Aqui solo se describe que campos mostrar y que procedimiento invocar.
 * Ninguna validacion de RUT, telefono, nombres o rutas vive en PHP:
 * todas las reglas y los mensajes provienen de Oracle.
 * ========================================================================= */

$maintainers = [
    'regiones' => [
        'title'     => 'Regiones',
        'proc'      => 'LEHZ_PS_IUD_REGION',
        'list'      => 'LEHZ_PS_LISTAR_REGIONES',
        'id'        => 'ID_REGION',
        'idparam'   => 'p_id_region',
        'generated' => true,
        'columns'   => ['ID_REGION', 'NOMBRE_REGION', 'TOTAL_COMUNAS'],
        'fields'    => [
            ['name' => 'NOMBRE_REGION', 'label' => 'Nombre de la region', 'param' => 'p_nombre_region', 'type' => 'text', 'placeholder' => 'Ej. Region del Maule', 'maxlength' => 60],
        ],
    ],
    'comunas' => [
        'title'   => 'Comunas',
        'proc'    => 'LEHZ_PS_IUD_COMUNA',
        'list'    => 'LEHZ_PS_LISTAR_COMUNAS',
        'id'      => 'ID_COMUNA',
        'idparam' => 'p_id_comuna',
        'generated' => true,
        'columns' => ['ID_COMUNA', 'NOMBRE_COMUNA', 'NOMBRE_REGION'],
        'fields'  => [
            ['name' => 'NOMBRE_COMUNA', 'label' => 'Nombre de la comuna', 'param' => 'p_nombre_comuna', 'type' => 'text', 'placeholder' => 'Ej. Talca', 'maxlength' => 60],
            ['name' => 'ID_REGION', 'label' => 'Region', 'param' => 'p_id_region', 'type' => 'lookup', 'source' => 'regiones'],
        ],
    ],
    'terminales' => [
        'title'   => 'Terminales',
        'proc'    => 'LEHZ_PS_IUD_TERMINAL',
        'list'    => 'LEHZ_PS_LISTAR_TERMINALES',
        'id'      => 'ID_TERMINAL',
        'idparam' => 'p_id_terminal',
        'generated' => true,
        'columns' => ['ID_TERMINAL', 'NOMBRE', 'CALLE', 'NUMERO', 'NOMBRE_COMUNA', 'NOMBRE_REGION'],
        'fields'  => [
            ['name' => 'NOMBRE', 'label' => 'Nombre del terminal', 'param' => 'p_nombre', 'type' => 'text', 'placeholder' => 'Ej. Terminal Lorenzo Varoli', 'maxlength' => 80],
            ['name' => 'CALLE', 'label' => 'Calle', 'param' => 'p_calle', 'type' => 'text', 'optional' => true, 'maxlength' => 60],
            ['name' => 'NUMERO', 'label' => 'Numero', 'param' => 'p_numero', 'type' => 'number', 'optional' => true, 'min' => 1],
            ['name' => 'ID_COMUNA', 'label' => 'Comuna', 'param' => 'p_id_comuna', 'type' => 'lookup', 'source' => 'comunas'],
        ],
    ],
    'empresas' => [
        'title'       => 'Empresas',
        'proc'        => 'LEHZ_PS_IUD_EMPRESA',
        'list'        => 'LEHZ_PS_LISTAR_EMPRESAS',
        'id'          => 'RUT_EMPRESA',
        'idparam'     => 'p_rut_empresa',
        'generated'   => false,
        'idtype'      => 'text',
        'manualid'    => true,
        'manuallabel' => 'RUT de la empresa (cuerpo-DV, ej. 76123456-0)',
        'idmaxlength' => 20,
        'columns'     => ['RUT_EMPRESA', 'RAZON_SOCIAL', 'TELEFONO_EMPRESA', 'CORREO_ELECTRONICO_EMPRESA', 'TOTAL_BUSES'],
        'fields'      => [
            ['name' => 'RAZON_SOCIAL', 'label' => 'Razon social', 'param' => 'p_razon_social', 'type' => 'text', 'maxlength' => 120],
            ['name' => 'TELEFONO_EMPRESA', 'label' => 'Telefono (movil o fijo, con +56 si quieres)', 'param' => 'p_telefono', 'type' => 'tel', 'placeholder' => '+56 71 234 455', 'maxlength' => 20],
            ['name' => 'CORREO_ELECTRONICO_EMPRESA', 'label' => 'Correo electronico', 'param' => 'p_correo', 'type' => 'email', 'optional' => true, 'maxlength' => 80],
        ],
    ],
    'buses' => [
        'title'       => 'Buses',
        'proc'        => 'LEHZ_PS_IUD_BUS',
        'list'        => 'LEHZ_PS_LISTAR_BUSES',
        'id'          => 'PATENTE_BUS',
        'idparam'     => 'p_patente',
        'generated'   => false,
        'idtype'      => 'text',
        'manualid'    => true,
        'manuallabel' => 'Patente del bus (6 caracteres, ej. ABCD12)',
        'idmaxlength' => 8,
        'columns'     => ['PATENTE_BUS', 'MARCA', 'MODELO', 'ANIO_FABRICACION', 'CAPACIDAD', 'NOMBRE_EMPRESA'],
        'fields'      => [
            ['name' => 'MARCA', 'label' => 'Marca', 'param' => 'p_marca', 'type' => 'text', 'optional' => true, 'maxlength' => 30],
            ['name' => 'MODELO', 'label' => 'Modelo', 'param' => 'p_modelo', 'type' => 'text', 'optional' => true, 'maxlength' => 30],
            ['name' => 'ANIO_FABRICACION', 'label' => 'Anio de fabricacion', 'param' => 'p_anio', 'type' => 'number', 'optional' => true, 'min' => 1950, 'max' => 2100],
            ['name' => 'CAPACIDAD', 'label' => 'Capacidad (asientos)', 'param' => 'p_capacidad', 'type' => 'number', 'optional' => true, 'min' => 1, 'max' => 100],
            ['name' => 'RUT_EMPRESA', 'label' => 'Empresa', 'param' => 'p_rut_empresa', 'type' => 'lookup', 'source' => 'empresas'],
        ],
    ],
    'asientos' => [
        'title'       => 'Asientos',
        'proc'        => 'LEHZ_PS_IUD_ASIENTO',
        'list'        => 'LEHZ_PS_LISTAR_ASIENTOS',
        'id'          => 'NUMERO_ASIENTO',
        'idparam'     => 'p_nro_asiento',
        'generated'   => false,
        'idtype'      => 'number',
        'manualid'    => true,
        'manuallabel' => 'Numero de asiento',
        'idmaxlength' => 3,
        'columns'     => ['NUMERO_ASIENTO', 'PATENTE_BUS', 'UBICACION', 'BUS_DETALLE'],
        'fields'      => [
            ['name' => 'PATENTE_BUS', 'label' => 'Bus', 'param' => 'p_patente', 'type' => 'lookup', 'source' => 'buses', 'lockEdit' => true],
            ['name' => 'UBICACION', 'label' => 'Ubicacion', 'param' => 'p_ubicacion', 'type' => 'text', 'optional' => true, 'placeholder' => 'Ventana / Pasillo', 'maxlength' => 20],
        ],
    ],
    'conductores' => [
        'title'       => 'Conductores',
        'proc'        => 'LEHZ_PS_IUD_CONDUCTOR',
        'list'        => 'LEHZ_PS_LISTAR_CONDUCTORES',
        'id'          => 'RUT_CONDUCTOR',
        'idparam'     => 'p_rut',
        'generated'   => false,
        'idtype'      => 'text',
        'manualid'    => true,
        'manuallabel' => 'RUT del conductor (cuerpo-DV, ej. 15432198-5)',
        'idmaxlength' => 20,
        'columns'     => ['RUT_CONDUCTOR', 'NOMBRE_CONDUCTOR', 'APELLIDO1_CONDUCTOR', 'APELLIDO2_CONDUCTOR', 'TELEFONO_CONDUCTOR', 'TIPO_LICENCIA', 'VENCIMIENTO_LICENCIA', 'NOMBRE_EMPRESA'],
        'fields'      => [
            ['name' => 'NOMBRE_CONDUCTOR', 'label' => 'Nombre', 'param' => 'p_nombre', 'type' => 'text', 'maxlength' => 100],
            ['name' => 'APELLIDO1_CONDUCTOR', 'label' => 'Primer apellido', 'param' => 'p_apellido1', 'type' => 'text', 'maxlength' => 80],
            ['name' => 'APELLIDO2_CONDUCTOR', 'label' => 'Segundo apellido', 'param' => 'p_apellido2', 'type' => 'text', 'optional' => true, 'maxlength' => 80],
            ['name' => 'TELEFONO_CONDUCTOR', 'label' => 'Celular (formato +56 9 XXXX XXXX)', 'param' => 'p_telefono', 'type' => 'tel', 'placeholder' => '+56 9 1234 5678', 'maxlength' => 20],
            ['name' => 'TIPO_LICENCIA', 'label' => 'Tipo de licencia', 'param' => 'p_tipo_licencia', 'type' => 'text', 'placeholder' => 'A3', 'maxlength' => 5],
            ['name' => 'VENCIMIENTO_LICENCIA', 'label' => 'Vencimiento de licencia', 'param' => 'p_vencimiento', 'type' => 'date'],
            ['name' => 'RUT_EMPRESA', 'label' => 'Empresa', 'param' => 'p_rut_empresa', 'type' => 'lookup', 'source' => 'empresas'],
        ],
    ],
    'mecanicos' => [
        'title'       => 'Mecanicos',
        'proc'        => 'LEHZ_PS_IUD_MECANICO',
        'list'        => 'LEHZ_PS_LISTAR_MECANICOS',
        'id'          => 'RUT_MECANICO',
        'idparam'     => 'p_rut',
        'generated'   => false,
        'idtype'      => 'text',
        'manualid'    => true,
        'manuallabel' => 'RUT del mecanico (cuerpo-DV, ej. 14222333-3)',
        'idmaxlength' => 20,
        'columns'     => ['RUT_MECANICO', 'NOMBRE_MECANICO', 'APELLIDO1_MECANICO', 'TELEFONO_MECANICO', 'ESPECIALIDAD', 'NOMBRE_EMPRESA'],
        'fields'      => [
            ['name' => 'NOMBRE_MECANICO', 'label' => 'Nombre', 'param' => 'p_nombre', 'type' => 'text', 'maxlength' => 100],
            ['name' => 'APELLIDO1_MECANICO', 'label' => 'Primer apellido', 'param' => 'p_apellido1', 'type' => 'text', 'maxlength' => 80],
            ['name' => 'APELLIDO2_MECANICO', 'label' => 'Segundo apellido', 'param' => 'p_apellido2', 'type' => 'text', 'optional' => true, 'maxlength' => 80],
            ['name' => 'TELEFONO_MECANICO', 'label' => 'Celular (formato +56 9 XXXX XXXX)', 'param' => 'p_telefono', 'type' => 'tel', 'placeholder' => '+56 9 1111 2222', 'maxlength' => 20],
            ['name' => 'ESPECIALIDAD', 'label' => 'Especialidad', 'param' => 'p_especialidad', 'type' => 'text', 'optional' => true, 'maxlength' => 40],
            ['name' => 'RUT_EMPRESA', 'label' => 'Empresa', 'param' => 'p_rut_empresa', 'type' => 'lookup', 'source' => 'empresas'],
        ],
    ],
    'rutas' => [
        'title'     => 'Rutas',
        'proc'      => 'LEHZ_PS_IUD_RUTA',
        'list'      => 'LEHZ_PS_LISTAR_RUTAS',
        'id'        => 'ID_RUTA',
        'idparam'   => 'p_id_ruta',
        'generated' => true,
        'columns'   => ['ID_RUTA', 'TRAYECTO', 'DISTANCIA', 'HORAS_ESTIMADAS', 'MINUTOS_ESTIMADOS', 'TOTAL_PARADAS', 'HORARIO'],
        'fields'    => [
            ['name' => 'ID_COMUNA_ORIGEN', 'label' => 'Ciudad de origen', 'param' => 'p_id_comuna_origen', 'type' => 'lookup', 'source' => 'comunas'],
            ['name' => 'ID_COMUNA_DESTINO', 'label' => 'Ciudad de destino', 'param' => 'p_id_comuna_destino', 'type' => 'lookup', 'source' => 'comunas'],
            ['name' => 'DISTANCIA', 'label' => 'Distancia (km)', 'param' => 'p_distancia', 'type' => 'number', 'min' => 1],
            ['name' => 'HORAS_ESTIMADAS', 'label' => 'Horas estimadas', 'param' => 'p_horas_est', 'type' => 'number', 'optional' => true, 'min' => 0],
            ['name' => 'MINUTOS_ESTIMADOS', 'label' => 'Minutos estimados', 'param' => 'p_minutos_est', 'type' => 'number', 'optional' => true, 'min' => 0, 'max' => 59],
            ['name' => 'HORARIO', 'label' => 'Fecha y hora de referencia', 'param' => 'p_horario', 'type' => 'datetime-local', 'optional' => true],
        ],
    ],
    'horarios' => [
        'title'     => 'Horarios',
        'proc'      => 'LEHZ_PS_IUD_HORARIO',
        'list'      => 'LEHZ_PS_LISTAR_HORARIOS',
        'id'        => 'ID_HORARIO',
        'idparam'   => 'p_id_horario',
        'generated' => true,
        'columns'   => ['ID_HORARIO', 'HORARIO', 'HORA_SALIDA', 'HORA_LLEGADA'],
        'fields'    => [
            ['name' => 'HORARIO', 'label' => 'Codigo de horario', 'param' => 'p_horario_val', 'type' => 'number', 'min' => 1],
            ['name' => 'HORA_SALIDA', 'label' => 'Hora de salida', 'param' => 'p_hora_salida', 'type' => 'datetime-local'],
            ['name' => 'HORA_LLEGADA', 'label' => 'Hora de llegada', 'param' => 'p_hora_llegada', 'type' => 'datetime-local'],
        ],
    ],
    'pasajeros' => [
        'title'       => 'Pasajeros',
        'proc'        => 'LEHZ_PS_IUD_PASAJERO',
        'list'        => 'LEHZ_PS_LISTAR_PASAJEROS',
        'id'          => 'RUT_PASAJERO',
        'idparam'     => 'p_rut',
        'generated'   => false,
        'idtype'      => 'text',
        'manualid'    => true,
        'manuallabel' => 'RUT del pasajero (cuerpo-DV, ej. 19111222-9 o 20000003-K)',
        'idmaxlength' => 20,
        'columns'     => ['RUT_PASAJERO', 'NOMBRE_COMPLETO', 'TELEFONO_PASAJERO', 'CORREO_ELECTRONICO_PASAJERO'],
        'fields'      => [
            ['name' => 'NOMBRE_PASAJERO', 'label' => 'Nombre', 'param' => 'p_nombre', 'type' => 'text', 'maxlength' => 100],
            ['name' => 'APELLIDO1_PASAJERO', 'label' => 'Primer apellido', 'param' => 'p_apellido1', 'type' => 'text', 'maxlength' => 80],
            ['name' => 'APELLIDO2_PASAJERO', 'label' => 'Segundo apellido', 'param' => 'p_apellido2', 'type' => 'text', 'optional' => true, 'maxlength' => 80],
            ['name' => 'TELEFONO_PASAJERO', 'label' => 'Celular (formato +56 9 XXXX XXXX)', 'param' => 'p_telefono', 'type' => 'tel', 'placeholder' => '+56 9 4444 5555', 'maxlength' => 20],
            ['name' => 'CORREO_ELECTRONICO_PASAJERO', 'label' => 'Correo electronico', 'param' => 'p_correo', 'type' => 'email', 'optional' => true, 'maxlength' => 80],
        ],
    ],
    'paradas' => [
        'title'     => 'Paradas de ruta',
        'proc'      => 'LEHZ_PS_IUD_PARADA',
        'list'      => 'LEHZ_PS_LISTAR_PARADAS',
        'id'        => 'ID_PARADA',
        'idparam'   => 'p_id_parada',
        'generated' => true,
        'columns'   => ['ID_PARADA', 'ID_RUTA', 'ORDEN', 'NOMBRE_COMUNA', 'DISTANCIA_DESDE_ORIGEN', 'MINUTOS_DESDE_SALIDA', 'TRAYECTO'],
        'fields'    => [
            ['name' => 'ID_RUTA', 'label' => 'Ruta', 'param' => 'p_id_ruta', 'type' => 'lookup', 'source' => 'rutas'],
            ['name' => 'ORDEN', 'label' => 'Orden de la parada (1, 2, 3...)', 'param' => 'p_orden', 'type' => 'number', 'min' => 1],
            ['name' => 'ID_COMUNA', 'label' => 'Ciudad / comuna de la parada', 'param' => 'p_id_comuna', 'type' => 'lookup', 'source' => 'comunas'],
            ['name' => 'DISTANCIA_DESDE_ORIGEN', 'label' => 'Distancia desde el origen (km)', 'param' => 'p_distancia', 'type' => 'number', 'optional' => true, 'min' => 0],
            ['name' => 'MINUTOS_DESDE_SALIDA', 'label' => 'Minutos desde la salida', 'param' => 'p_minutos', 'type' => 'number', 'optional' => true, 'min' => 0],
        ],
    ],
];

/* Etiqueta amigable para cada selector: el valor sigue siendo el ID. */
$lookupLabels = [
    'regiones'    => fn($r) => $r['NOMBRE_REGION'],
    'comunas'     => fn($r) => $r['NOMBRE_COMUNA'] . ' · ' . $r['NOMBRE_REGION'],
    'empresas'    => fn($r) => $r['RAZON_SOCIAL'] . ' · ' . $r['RUT_EMPRESA'],
    'buses'       => fn($r) => $r['PATENTE_BUS'] . ' · ' . trim(($r['MARCA'] ?? '') . ' ' . ($r['MODELO'] ?? '')),
    'conductores' => fn($r) => $r['NOMBRE_CONDUCTOR'] . ' ' . $r['APELLIDO1_CONDUCTOR'] . ' · ' . $r['RUT_CONDUCTOR'],
    'mecanicos'   => fn($r) => $r['NOMBRE_MECANICO'] . ' ' . $r['APELLIDO1_MECANICO'] . ' · ' . $r['RUT_MECANICO'],
    'rutas'       => fn($r) => 'Ruta #' . $r['ID_RUTA'] . ' · ' . ($r['TRAYECTO'] ?? ''),
    'horarios'    => fn($r) => '#' . $r['ID_HORARIO'] . ' · ' . $r['HORA_SALIDA'],
    'terminales'  => fn($r) => $r['NOMBRE'] . ' · ' . $r['NOMBRE_COMUNA'],
    'pasajeros'   => fn($r) => $r['NOMBRE_COMPLETO'] . ' · ' . $r['RUT_PASAJERO'],
];

/* Clave primaria que devuelve cada listado y si es numerica. */
$lookupKeys = [
    'regiones'    => 'ID_REGION',
    'comunas'     => 'ID_COMUNA',
    'empresas'    => 'RUT_EMPRESA',
    'buses'       => 'PATENTE_BUS',
    'conductores' => 'RUT_CONDUCTOR',
    'mecanicos'   => 'RUT_MECANICO',
    'rutas'       => 'ID_RUTA',
    'horarios'    => 'ID_HORARIO',
    'terminales'  => 'ID_TERMINAL',
    'pasajeros'   => 'RUT_PASAJERO',
];

$lookupNumeric = [
    'regiones'   => true,
    'comunas'    => true,
    'rutas'      => true,
    'horarios'   => true,
    'terminales' => true,
];

$reports = [
    'recaudacion'  => ['title' => 'Recaudacion por viajes', 'proc' => 'LEHZ_PS_REP_RECAUDACION_VIAJES'],
    'mantenciones' => ['title' => 'Costos de mantención', 'proc' => 'LEHZ_PS_REP_COSTOS_MANTENCION'],
    'ocupacion'    => ['title' => 'Ocupacion de asientos', 'proc' => 'LEHZ_PS_REP_OCUPACION_ASIENTOS'],
];

$page    = $_GET['page'] ?? (empty($_SESSION['user']) ? 'login' : 'dashboard');
$error   = '';
$success = '';

if (!empty($_SESSION['flash'])) {
    if (($_SESSION['flash']['type'] ?? '') === 'success') {
        $success = (string)($_SESSION['flash']['msg'] ?? '');
    } else {
        $error = (string)($_SESSION['flash']['msg'] ?? '');
    }
    unset($_SESSION['flash']);
}

function h($v): string {
    return htmlspecialchars((string)($v ?? ''), ENT_QUOTES, 'UTF-8');
}

function pretty_col(string $col): string {
    return ucwords(strtolower(str_replace('_', ' ', $col)));
}

function flash(string $type, string $msg): void {
    $_SESSION['flash'] = ['type' => $type, 'msg' => $msg];
}

/**
 * Traduce errores de Oracle a un mensaje legible. Los mensajes de negocio
 * son los que levantan las funciones y los procedimientos con RAISE_APPLICATION_ERROR.
 */
function friendly_error(Throwable $e): string {
    $msg = $e->getMessage();

    if (preg_match('/ORA-(?:20\d{3}|20\d{2}):\s*(.+?)(?:\s*ORA-|\s*Help:|$)/s', $msg, $m)) {
        return trim($m[1]);
    }
    if (str_contains($msg, 'ORA-00001')) {
        return 'Ya existe un registro con ese mismo identificador (RUT, patente o codigo duplicado).';
    }
    if (str_contains($msg, 'ORA-02292')) {
        return 'No se puede eliminar: el registro esta siendo utilizado en otros modulos.';
    }
    if (str_contains($msg, 'ORA-02291')) {
        return 'Uno de los valores seleccionados no existe en el sistema.';
    }
    if (str_contains($msg, 'ORA-01400')) {
        return 'Falta un dato obligatorio. Revisa el formulario e intenta nuevamente.';
    }
    if (str_contains($msg, 'ORA-12899')) {
        return 'Uno de los textos ingresados es demasiado largo para el campo.';
    }
    if (str_contains($msg, 'ORA-01722')) {
        return 'Uno de los valores numericos ingresados no es valido.';
    }

    return $msg;
}

if ($page === 'logout') {
    session_destroy();
    header('Location: ?page=login');
    exit;
}

/* -------------------------------------------------------------------------
 * LOGIN: la verificacion del hash y del estado del usuario ocurre en Oracle.
 * ------------------------------------------------------------------------- */
if ($page === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $usuario = db_cursor(
            "BEGIN LEHZ_PKG_SEGURIDAD.SP_VALIDAR_LOGIN(
                 p_username => :username,
                 p_password => :password,
                 p_cursor   => :p_cursor
             ); END;",
            [
                'username' => trim((string)($_POST['username'] ?? '')),
                'password' => (string)($_POST['password'] ?? ''),
            ]
        );

        if ($usuario) {
            $u = $usuario[0];
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'id'       => $u['ID_USUARIO'],
                'username' => $u['USERNAME'],
                'name'     => $u['NOMBRE_COMPLETO'],
                'email'    => $u['EMAIL'],
                'role'     => $u['NOMBRE_ROL'],
            ];
            header('Location: ?page=dashboard');
            exit;
        }

        $error = 'Usuario o contraseña incorrectos, o cuenta inactiva.';
    } catch (Throwable $e) {
        $error = friendly_error($e);
    }
}

if ($page !== 'login') {
    require_login();
}
if (isset($_SESSION['user']) && $page === 'login') {
    header('Location: ?page=dashboard');
    exit;
}
if ($page !== 'login') {
    require_page($page);
}

/* -------------------------------------------------------------------------
 * ACCIONES DE ESCRITURA
 * ------------------------------------------------------------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $page !== 'login') {
    try {
        if (str_starts_with($page, 'm_')) {
            $key = substr($page, 2);
            if (!isset($maintainers[$key])) {
                throw new RuntimeException('Mantenimiento no encontrado.');
            }
            $m  = $maintainers[$key];
            $op = strtoupper(trim((string)($_POST['op'] ?? 'I')));
            if (!in_array($op, ['I', 'U', 'D'], true)) {
                throw new RuntimeException('Operacion no valida: use I, U o D.');
            }

            $args  = ['p_opcion' => ':p_opcion'];
            $binds = ['p_opcion' => $op];

            $idParam = $m['idparam'];
            $idType  = $m['idtype'] ?? 'number';
            $rawId   = $op === 'I' && !empty($m['manualid'])
                ? trim((string)($_POST['manual_id'] ?? ''))
                : trim((string)($_POST['record_id'] ?? ''));

            if ($op !== 'I' && $rawId === '') {
                throw new RuntimeException('No se identifico el registro a modificar.');
            }
            if ($op === 'I' && !empty($m['manualid']) && $rawId === '') {
                throw new RuntimeException('El identificador del registro es obligatorio.');
            }

            $args[$idParam] = ':' . $idParam;
            if ($op === 'I' && !empty($m['generated'])) {
                $binds[$idParam] = 0;
            } elseif ($idType === 'number') {
                $binds[$idParam] = (int)$rawId;
            } else {
                $binds[$idParam] = $rawId;
            }

            foreach ($m['fields'] as $f) {
                $name  = $f['name'];
                $value = isset($_POST[$name]) ? trim((string)$_POST[$name]) : null;
                if ($value === '') {
                    $value = null;
                }

                $param = $f['param'];
                $type  = $f['type'] ?? 'text';

                if ($value === null) {
                    $args[$param]  = ':' . $param;
                    $binds[$param] = null;
                } elseif ($type === 'date') {
                    $args[$param]  = "TO_DATE(:{$param}, 'YYYY-MM-DD')";
                    $binds[$param] = $value;
                } elseif ($type === 'datetime-local') {
                    $args[$param]  = "TO_TIMESTAMP(:{$param}, 'YYYY-MM-DD HH24:MI')";
                    $binds[$param] = str_replace('T', ' ', $value);
                } elseif ($type === 'number') {
                    $args[$param]  = ':' . $param;
                    $binds[$param] = str_contains($value, '.') ? (float)$value : (int)$value;
                } elseif ($type === 'lookup') {
                    $args[$param]  = ':' . $param;
                    $binds[$param] = !empty($lookupNumeric[$f['source'] ?? '']) ? (int)$value : $value;
                } else {
                    $args[$param]  = ':' . $param;
                    $binds[$param] = $value;
                }
            }

            $argList = [];
            foreach ($args as $param => $expr) {
                $argList[] = $param . ' => ' . $expr;
            }
            db_call('BEGIN ' . $m['proc'] . '(' . implode(', ', $argList) . '); END;', $binds);

            $msg = $op === 'D'
                ? 'Registro eliminado correctamente.'
                : ($op === 'U' ? 'Registro actualizado correctamente.' : 'Registro creado correctamente.');
            flash('success', $msg);
            header('Location: ?page=' . urlencode($page));
            exit;

        } elseif ($page === 'seg_usuarios') {
            require_role(['ADMINISTRADOR']);
            $op = $_POST['op'] ?? 'create';

            if ($op === 'create') {
                $resultado = db_call(
                    "BEGIN LEHZ_PKG_SEGURIDAD.SP_CREAR_USUARIO(
                         p_username        => :username,
                         p_password        => :password,
                         p_nombre_completo => :nombre,
                         p_email           => :email,
                         p_id_rol          => :rol,
                         p_id_generado     => :nuevo
                     ); END;",
                    [
                        'username' => trim((string)($_POST['username'] ?? '')),
                        'password' => (string)($_POST['password'] ?? ''),
                        'nombre'   => trim((string)($_POST['nombre'] ?? '')),
                        'email'    => trim((string)($_POST['email'] ?? '')),
                        'rol'      => (int)($_POST['rol'] ?? 0),
                        'nuevo'    => 0,
                    ]
                );
                flash('success', 'Usuario creado correctamente. ID: ' . ($resultado['nuevo'] ?? ''));

            } elseif ($op === 'state') {
                $estado = strtoupper(trim((string)($_POST['estado'] ?? '')));
                db_call(
                    "BEGIN LEHZ_PKG_SEGURIDAD.SP_CAMBIAR_ESTADO_USUARIO(
                         p_id_usuario => :id,
                         p_estado     => :estado
                     ); END;",
                    [
                        'id'     => (int)($_POST['id_usuario'] ?? 0),
                        'estado' => $estado,
                    ]
                );
                flash('success', 'Estado del usuario actualizado a ' . $estado . '.');
            } else {
                throw new RuntimeException('Operacion de seguridad no reconocida.');
            }

            header('Location: ?page=seg_usuarios');
            exit;

        } elseif ($page === 'g_viaje') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            $v = db_call(
                "BEGIN LEHZ_PS_GES_PROGRAMAR_VIAJE(
                     p_fecha_viaje  => TO_DATE(:fecha, 'YYYY-MM-DD'),
                     p_id_horario   => :horario,
                     p_id_ruta      => :ruta,
                     p_id_viaje_out => :nuevo
                 ); END;",
                [
                    'fecha'   => (string)($_POST['fecha'] ?? ''),
                    'horario' => (int)($_POST['horario'] ?? 0),
                    'ruta'    => (int)($_POST['ruta'] ?? 0),
                    'nuevo'   => 0,
                ]
            );
            flash('success', 'Viaje programado correctamente. ID: ' . ($v['nuevo'] ?? ''));

        } elseif ($page === 'g_venta') {
            require_role(['ADMINISTRADOR', 'VENDEDOR']);
            $v = db_call(
                "BEGIN LEHZ_PS_GES_VENDER_BOLETO(
                     p_valor_boleto   => :valor,
                     p_rut_pasajero   => :pasajero,
                     p_id_viaje       => :viaje,
                     p_numero_asiento => :asiento,
                     p_patente_bus    => :bus,
                     p_metodo_pago    => :metodo,
                     p_id_boleto_out  => :nuevo
                 ); END;",
                [
                    'valor'    => (float)($_POST['valor'] ?? 0),
                    'pasajero' => trim((string)($_POST['pasajero'] ?? '')),
                    'viaje'    => (int)($_POST['viaje'] ?? 0),
                    'asiento'  => (int)($_POST['asiento'] ?? 0),
                    'bus'      => strtoupper(trim((string)($_POST['bus'] ?? ''))),
                    'metodo'   => strtoupper(trim((string)($_POST['metodo'] ?? ''))),
                    'nuevo'    => 0,
                ]
            );
            flash('success', 'Boleto vendido y pago registrado. Folio: ' . ($v['nuevo'] ?? ''));

        } elseif ($page === 'g_conduce') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            db_call(
                "BEGIN LEHZ_PS_GES_ASIGNAR_CONDUCE(
                     p_rut_conductor => :conductor,
                     p_patente_bus   => :bus,
                     p_id_viaje      => :viaje
                 ); END;",
                [
                    'conductor' => trim((string)($_POST['conductor'] ?? '')),
                    'bus'       => strtoupper(trim((string)($_POST['bus'] ?? ''))),
                    'viaje'     => (int)($_POST['viaje'] ?? 0),
                ]
            );
            flash('success', 'Asignacion registrada correctamente.');

        } elseif ($page === 'g_mantencion') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            $v = db_call(
                "BEGIN LEHZ_PS_GES_REGISTRAR_MANTENCION(
                     p_fecha        => TO_DATE(:fecha, 'YYYY-MM-DD'),
                     p_descripcion  => :descripcion,
                     p_costo        => :costo,
                     p_rut_mecanico => :mecanico,
                     p_patente_bus  => :bus,
                     p_id_mant_out  => :nuevo
                 ); END;",
                [
                    'fecha'       => (string)($_POST['fecha'] ?? ''),
                    'descripcion' => trim((string)($_POST['descripcion'] ?? '')),
                    'costo'       => (float)($_POST['costo'] ?? 0),
                    'mecanico'    => trim((string)($_POST['mecanico'] ?? '')),
                    'bus'         => strtoupper(trim((string)($_POST['bus'] ?? ''))),
                    'nuevo'       => 0,
                ]
            );
            flash('success', 'Mantención registrada. ID: ' . ($v['nuevo'] ?? ''));

        } elseif ($page === 'g_terminal') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            db_call(
                "BEGIN LEHZ_PS_GES_ASOCIAR_TERMINAL(
                     p_id_terminal => :terminal,
                     p_rut_empresa => :empresa
                 ); END;",
                [
                    'terminal' => (int)($_POST['terminal'] ?? 0),
                    'empresa'  => trim((string)($_POST['empresa'] ?? '')),
                ]
            );
            flash('success', 'Terminal asociado a la empresa correctamente.');
        }

        if (in_array($page, ['g_viaje', 'g_venta', 'g_conduce', 'g_mantencion', 'g_terminal'], true)) {
            header('Location: ?page=' . urlencode($page));
            exit;
        }
    } catch (Throwable $e) {
        $error = friendly_error($e);
    }
}

/* -------------------------------------------------------------------------
 * CARGA DE DATOS PARA LA PANTALLA ACTUAL
 * ------------------------------------------------------------------------- */
$rows       = [];
$reportRows = [];
$lookups    = [];
$usuarios   = [];
$roles      = [];

try {
    if (str_starts_with($page, 'm_')) {
        $key = substr($page, 2);
        if (isset($maintainers[$key])) {
            $m    = $maintainers[$key];
            $rows = db_rows($m['list']);

            $sources = [];
            foreach ($m['fields'] as $f) {
                if (($f['type'] ?? '') === 'lookup' && !in_array($f['source'], $sources, true)) {
                    $sources[] = $f['source'];
                }
            }
            foreach ($sources as $source) {
                $lookups[$source] = db_rows($maintainers[$source]['list']);
            }
        }
    } elseif (str_starts_with($page, 'r_')) {
        $rk = substr($page, 2);
        if (isset($reports[$rk])) {
            $reportRows = db_rows($reports[$rk]['proc']);
        }
    } elseif ($page === 'seg_usuarios') {
        $usuarios = db_rows('LEHZ_PKG_SEGURIDAD.SP_LISTAR_USUARIOS');
        $roles    = db_rows('LEHZ_PKG_SEGURIDAD.SP_LISTAR_ROLES');
    } elseif (in_array($page, ['g_viaje', 'g_venta', 'g_conduce', 'g_mantencion', 'g_terminal'], true)) {
        $needed = [
            'g_viaje'      => ['horarios', 'rutas'],
            'g_venta'      => ['pasajeros', 'buses'],
            'g_conduce'    => ['conductores', 'buses'],
            'g_mantencion' => ['mecanicos', 'buses'],
            'g_terminal'   => ['terminales', 'empresas'],
        ];
        foreach ($needed[$page] as $source) {
            $lookups[$source] = db_rows($maintainers[$source]['list']);
        }
        if (in_array($page, ['g_venta', 'g_conduce'], true)) {
            $lookups['viajes'] = db_rows('LEHZ_PS_LISTAR_VIAJES');
        }
    }
} catch (Throwable $e) {
    $error = $error ?: friendly_error($e);
}

/* -------------------------------------------------------------------------
 * NAVEGACION
 * ------------------------------------------------------------------------- */
$navGroups = [
    'GENERAL'        => [['dashboard', 'Panel principal', '⌂']],
    'ADMINISTRACION' => array_map(fn($k) => ['m_' . $k, $maintainers[$k]['title'], '▦'], array_keys($maintainers)),
    'OPERACIONES'    => [
        ['g_viaje', 'Programar viaje', '↗'],
        ['g_conduce', 'Asignar conductor', '⇄'],
        ['g_mantencion', 'Mantenciones', '⚙'],
        ['g_terminal', 'Asociar terminal', '⌑'],
    ],
    'VENTAS'         => [['g_venta', 'Vender boleto', '▣']],
    'REPORTES'       => [
        ['r_recaudacion', 'Recaudacion', '▤'],
        ['r_mantenciones', 'Costos de mantención', '▤'],
        ['r_ocupacion', 'Ocupacion', '▤'],
    ],
    'SEGURIDAD'      => [['seg_usuarios', 'Usuarios y roles', '⚿']],
];

function layout_start($title, $active, $navGroups) {
    $user = $_SESSION['user'] ?? null;
    ?><!doctype html>
    <html lang="es">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title><?= h($title) ?> · RutaGestion</title>
        <link rel="stylesheet" href="assets/css/app.css">
    </head>
    <body>
    <div class="shell">
        <aside class="sidebar">
            <a class="brand" href="?page=dashboard">
                <span class="brand-icon">R</span>
                <span><b>RutaGestion</b><small>TRANSPORTE REGIONAL</small></span>
            </a>
            <div class="side-user">
                <div class="avatar"><?= h(strtoupper(substr($user['name'] ?? 'U', 0, 1))) ?></div>
                <div><b><?= h($user['name'] ?? 'Usuario') ?></b><small><?= h($user['role'] ?? '') ?></small></div>
            </div>
            <nav>
                <?php foreach ($navGroups as $group => $items):
                    $visibles = array_values(array_filter($items, fn($it) => page_allowed($it[0])));
                    if (!$visibles) continue;
                ?>
                    <div class="nav-label"><?= h($group) ?></div>
                    <?php foreach ($visibles as $it): ?>
                        <a class="nav-link <?= $active === $it[0] ? 'active' : '' ?>" href="?page=<?= h($it[0]) ?>">
                            <span><?= $it[2] ?></span><?= h($it[1]) ?>
                        </a>
                    <?php endforeach; ?>
                <?php endforeach; ?>
            </nav>
            <a class="logout" href="?page=logout">↪ Cerrar sesion</a>
        </aside>
        <main class="main">
            <header class="topbar">
                <div><span class="eyebrow">SISTEMA DE GESTION INTEGRAL</span><h1><?= h($title) ?></h1></div>
                <div class="top-user"><span class="status-dot"></span> Conectado <b><?= h($user['username'] ?? '') ?></b></div>
            </header>
            <div class="content">
    <?php
}

function layout_end() {
    ?>
            </div>
            <footer>RutaGestion · Sistema de Gestion Integral de Transporte Publico Regional</footer>
        </main>
    </div>
    <script src="assets/js/app.js"></script>
    </body>
    </html>
    <?php
}

/* -------------------------------------------------------------------------
 * PANTALLA DE LOGIN
 * ------------------------------------------------------------------------- */
if ($page === 'login') {
    ?><!doctype html>
    <html lang="es">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Iniciar sesion · RutaGestion</title>
        <link rel="stylesheet" href="assets/css/app.css">
    </head>
    <body class="login-body">
    <div class="login-wrap">
        <section class="login-art">
            <div class="art-brand"><span class="brand-icon">R</span> RutaGestion</div>
            <div class="art-copy">
                <span class="eyebrow">PLATAFORMA DE OPERACIONES</span>
                <h1>Conectamos<br>personas y<br><em>regiones.</em></h1>
                <p>Administra flotas, viajes, pasajeros y operaciones desde un solo lugar.</p>
            </div>
            <div class="art-footer">GESTION INTELIGENTE · TRANSPORTE REGIONAL</div>
        </section>
        <section class="login-panel">
            <div class="login-form">
                <span class="eyebrow">BIENVENIDO DE VUELTA</span>
                <h2>Iniciar sesion</h2>
                <p>Ingresa tus credenciales para continuar.</p>
                <?php if ($error): ?><div class="alert error"><?= h($error) ?></div><?php endif; ?>
                <form method="post">
                    <label>Nombre de usuario<input name="username" required autocomplete="username" placeholder="Ej. admin"></label>
                    <label>Contraseña<input type="password" name="password" required autocomplete="current-password" placeholder="Tu contraseña"></label>
                    <button class="btn primary full">Ingresar al sistema <span>→</span></button>
                </form>
                <div class="login-note">Acceso protegido mediante usuarios, roles y hash SHA-256 de Oracle.</div>
            </div>
        </section>
    </div>
    </body>
    </html>
    <?php
    exit;
}

$title = 'Panel principal';
if (str_starts_with($page, 'm_')) {
    $title = $maintainers[substr($page, 2)]['title'] ?? 'Mantenimiento';
} elseif (str_starts_with($page, 'r_')) {
    $title = $reports[substr($page, 2)]['title'] ?? 'Reporte';
} elseif ($page === 'seg_usuarios') {
    $title = 'Usuarios y roles';
} elseif ($page === 'g_venta') {
    $title = 'Venta de boleto';
} elseif ($page === 'g_viaje') {
    $title = 'Programar viaje';
} elseif ($page === 'g_conduce') {
    $title = 'Asignar conductor y bus';
} elseif ($page === 'g_mantencion') {
    $title = 'Registrar mantención';
} elseif ($page === 'g_terminal') {
    $title = 'Asociar terminal';
}

layout_start($title, $page, $navGroups);
if ($error) echo '<div class="alert error">' . h($error) . '</div>';
if ($success) echo '<div class="alert success">' . h($success) . '</div>';

/* -------------------------------------------------------------------------
 * DASHBOARD: las metricas visibles las decide Oracle segun el rol.
 * ------------------------------------------------------------------------- */
if ($page === 'dashboard') {
    $stats = [];
    try {
        $stats = db_cursor(
            "BEGIN LEHZ_PS_DASHBOARD(p_perfil => :perfil, p_cursor => :p_cursor); END;",
            ['perfil' => current_role()]
        );
    } catch (Throwable $e) {
        echo '<div class="alert error">' . h(friendly_error($e)) . '</div>';
    }

    $quick = [
        ['g_venta', 'Vender boleto', 'Registrar venta y pago', '▣'],
        ['g_viaje', 'Programar viaje', 'Crear nueva salida', '↗'],
        ['g_mantencion', 'Registrar mantención', 'Control de flota', '⚙'],
        ['r_recaudacion', 'Ver recaudación', 'Consultar resultados', '▤'],
    ];
    ?>
    <div class="welcome">
        <div>
            <span class="eyebrow">RESUMEN OPERACIONAL</span>
            <h2>Hola, <?= h(explode(' ', $_SESSION['user']['name'])[0]) ?> 👋</h2>
            <p>Estas son las metricas que tu rol tiene permitido consultar.</p>
        </div>
        <div class="welcome-date"><?= date('d/m/Y') ?> <small>FECHA DE CONSULTA</small></div>
    </div>
    <div class="stat-grid">
        <?php foreach ($stats as $s):
            $metrica = (string)($s['METRICA'] ?? '');
            $esDinero = stripos($metrica, 'recaudaci') !== false || stripos($metrica, 'costo') !== false;
        ?>
            <article class="stat-card">
                <span><?= h($metrica) ?></span>
                <strong><?= ($esDinero ? '$' : '') . number_format((float)($s['TOTAL'] ?? 0), 0, ',', '.') ?></strong>
                <small><?= $esDinero ? 'Monto acumulado en Oracle' : 'Registros en Oracle' ?></small>
            </article>
        <?php endforeach; ?>
    </div>
    <div class="dashboard-grid">
        <section class="panel">
            <div class="panel-head"><div><span class="eyebrow">ACCESOS RAPIDOS</span><h3>Operaciones frecuentes</h3></div></div>
            <div class="quick-grid">
                <?php foreach ($quick as $q): if (!page_allowed($q[0])) continue; ?>
                    <a href="?page=<?= h($q[0]) ?>"><b><?= $q[3] ?></b><span><?= h($q[1]) ?></span><small><?= h($q[2]) ?></small></a>
                <?php endforeach; ?>
            </div>
        </section>
        <section class="panel side-panel">
            <span class="eyebrow">ESTADO DEL SISTEMA</span>
            <h3>Base de datos</h3>
            <div class="db-status"><i></i><b>Oracle · LEHZ</b><span>Conexion activa</span></div>
            <p>Los formularios no validan datos: envian los valores a Oracle y muestran el mensaje devuelto por la base de datos.</p>
        </section>
    </div>

<?php
/* -------------------------------------------------------------------------
 * MANTENEDORES GENERICOS
 * ------------------------------------------------------------------------- */
} elseif (str_starts_with($page, 'm_')) {
    $key = substr($page, 2);
    if (!isset($maintainers[$key])) {
        echo '<section class="panel"><h3>Modulo no encontrado</h3><a href="?page=dashboard">Volver al panel</a></section>';
        layout_end();
        exit;
    }
    $m = $maintainers[$key];

    $formFields = array_merge([$m['id']], array_column($m['fields'], 'name'));
    $fieldMeta  = [];
    foreach ($m['fields'] as $f) {
        $fieldMeta[$f['name']] = [
            'type'     => $f['type'] ?? 'text',
            'lockEdit' => !empty($f['lockEdit']),
        ];
    }
    ?>
    <section class="panel">
        <div class="panel-head">
            <div>
                <span class="eyebrow">GESTION DE DATOS</span>
                <h3><?= h($m['title']) ?></h3>
                <p>Los datos se graban y validan con <b><?= h($m['proc']) ?></b>. La interfaz solo muestra el resultado.</p>
            </div>
            <button class="btn primary" onclick="openCreate()">＋ Nuevo registro</button>
        </div>

        <div class="table-tools">
            <input type="search" placeholder="Buscar en <?= h($m['title']) ?>..." oninput="filterTable(this, 'tbl_m')">
            <span class="muted"><?= count($rows) ?> registro(s)</span>
        </div>

        <div class="table-wrap">
            <table id="tbl_m">
                <thead>
                    <tr>
                        <?php foreach ($m['columns'] as $col): ?>
                            <th><?= h(pretty_col($col)) ?></th>
                        <?php endforeach; ?>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($rows as $r): ?>
                        <tr>
                            <?php foreach ($m['columns'] as $col): ?>
                                <td><?= h($r[$col] ?? '—') ?></td>
                            <?php endforeach; ?>
                            <td class="actions">
                                <button class="icon-btn" title="Editar" onclick='editRow(<?= json_encode($r, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_INVALID_UTF8_SUBSTITUTE) ?>)'>✎</button>
                                <form method="post" class="inline" onsubmit="return confirm('¿Eliminar este registro?')">
                                    <input type="hidden" name="op" value="D">
                                    <input type="hidden" name="record_id" value="<?= h($r[$m['id']]) ?>">
                                    <?php if ($key === 'asientos'): ?>
                                        <input type="hidden" name="PATENTE_BUS" value="<?= h($r['PATENTE_BUS']) ?>">
                                    <?php endif; ?>
                                    <button class="icon-btn danger" title="Eliminar">⌫</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (!$rows): ?>
                        <tr class="empty"><td colspan="<?= count($m['columns']) + 1 ?>" class="empty">Todavia no hay registros.</td></tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </section>

    <div class="modal" id="recordModal">
        <div class="modal-card" style="overflow:auto;">
            <div class="modal-head">
                <div><span class="eyebrow">FORMULARIO</span><h3 id="modalTitle">Nuevo registro</h3></div>
                <button type="button" class="icon-btn" onclick="closeModal()">×</button>
            </div>
            <form method="post" id="recordForm">
                <input type="hidden" name="op" id="formOp" value="I">
                <input type="hidden" name="record_id" id="recordId">

                <?php if (!empty($m['manualid'])): ?>
                    <label><?= h($m['manuallabel']) ?>
                        <input name="manual_id" id="manualId" maxlength="<?= (int)($m['idmaxlength'] ?? 40) ?>" <?= in_array(($m['idtype'] ?? 'number'), ['number'], true) ? 'type="number" min="1"' : 'type="text"' ?> autocomplete="off" required>
                    </label>
                <?php endif; ?>

                <?php foreach ($m['fields'] as $f): ?>
                    <label><?= h($f['label']) ?>
                        <?php if (($f['type'] ?? '') === 'lookup'): ?>
                            <select name="<?= h($f['name']) ?>" <?= empty($f['optional']) ? 'required' : '' ?>>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($lookups[$f['source']] ?? [] as $o):
                                    $labelFn  = $lookupLabels[$f['source']] ?? null;
                                    $label    = $labelFn ? $labelFn($o) : ($o[$f['display'] ?? ''] ?? '');
                                    $valueKey = $lookupKeys[$f['source']] ?? ($f['value'] ?? $m['id']);
                                ?>
                                    <option value="<?= h($o[$valueKey] ?? '') ?>"><?= h($label) ?></option>
                                <?php endforeach; ?>
                            </select>
                        <?php else: ?>
                            <input
                                type="<?= h($f['type'] ?? 'text') ?>"
                                name="<?= h($f['name']) ?>"
                                <?= empty($f['optional']) ? 'required' : '' ?>
                                <?= isset($f['min']) ? 'min="' . h($f['min']) . '"' : '' ?>
                                <?= isset($f['max']) ? 'max="' . h($f['max']) . '"' : '' ?>
                                <?= isset($f['maxlength']) ? 'maxlength="' . h($f['maxlength']) . '"' : '' ?>
                                <?= isset($f['placeholder']) ? 'placeholder="' . h($f['placeholder']) . '"' : '' ?>
                                autocomplete="off">
                        <?php endif; ?>
                    </label>
                <?php endforeach; ?>

                <div class="modal-actions">
                    <button type="button" class="btn ghost" onclick="closeModal()">Cancelar</button>
                    <button type="submit" class="btn primary">Guardar registro</button>
                </div>
            </form>
        </div>
    </div>

    <script>
    const formFields = <?= json_encode($formFields) ?>;
    const fieldMeta  = <?= json_encode($fieldMeta, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;

    function unlockAll() {
        document.querySelectorAll('#recordForm [data-locked="1"]').forEach(el => {
            el.disabled = false;
            delete el.dataset.locked;
        });
    }

    function openCreate() {
        const form = document.getElementById('recordForm');
        form.reset();
        unlockAll();
        document.getElementById('formOp').value = 'I';
        document.getElementById('recordId').value = '';
        document.getElementById('modalTitle').textContent = 'Nuevo registro';
        const mid = document.getElementById('manualId');
        if (mid) { mid.disabled = false; mid.value = ''; }
        document.getElementById('recordModal').classList.add('show');
    }

    function editRow(r) {
        const form = document.getElementById('recordForm');
        form.reset();
        unlockAll();

        document.getElementById('formOp').value = 'U';
        document.getElementById('recordId').value = r[formFields[0]] ?? '';
        document.getElementById('modalTitle').textContent = 'Editar registro';

        const mid = document.getElementById('manualId');
        if (mid) {
            mid.value = r[formFields[0]] ?? '';
            mid.disabled = true;
        }

        formFields.slice(1).forEach(name => {
            const el = form.querySelector('[name="' + name + '"]');
            if (!el) return;
            const meta = fieldMeta[name] || {};
            let value = r[name];
            if (value === null || value === undefined) {
                value = '';
            } else if (meta.type === 'datetime-local') {
                value = String(value).replace(' ', 'T').slice(0, 16);
            } else if (meta.type === 'date') {
                value = String(value).slice(0, 10);
            }
            el.value = value;

            if (meta.lockEdit) {
                el.dataset.locked = '1';
                el.disabled = true;
            }
        });

        document.getElementById('recordModal').classList.add('show');
    }

    function closeModal() {
        document.getElementById('recordModal').classList.remove('show');
    }

    document.getElementById('recordForm').addEventListener('submit', () => {
        document.querySelectorAll('#recordForm [data-locked="1"]').forEach(el => {
            el.disabled = false;
        });
    });
    </script>

<?php
/* -------------------------------------------------------------------------
 * USUARIOS Y ROLES (solo administrador)
 * ------------------------------------------------------------------------- */
} elseif ($page === 'seg_usuarios') {
    ?>
    <section class="panel form-panel">
        <span class="eyebrow">SEGURIDAD</span>
        <h3>Crear usuario</h3>
        <p>El usuario, la contraseña, el correo y el rol se validan y almacenan en Oracle con hash SHA-256.</p>
        <form method="post" class="form-grid">
            <input type="hidden" name="op" value="create">
            <label>Nombre de usuario<input type="text" name="username" minlength="4" maxlength="40" required autocomplete="off" placeholder="Ej. jefe.talca"></label>
            <label>Contraseña<input type="password" name="password" minlength="8" required autocomplete="new-password" placeholder="Minimo 8 caracteres"></label>
            <label>Nombre completo<input type="text" name="nombre" maxlength="120" required autocomplete="off" placeholder="Ej. Ana Maria Rojas"></label>
            <label>Correo electronico<input type="email" name="email" maxlength="80" required autocomplete="off" placeholder="ana.rojas@empresa.cl"></label>
            <label>Rol
                <select name="rol" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($roles as $r): ?>
                        <option value="<?= h($r['ID_ROL']) ?>"><?= h($r['NOMBRE_ROL']) ?> · <?= h($r['DESCRIPCION_ROL'] ?? '') ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <div class="form-actions"><button class="btn primary">Crear usuario →</button></div>
        </form>
    </section>

    <section class="panel">
        <div class="panel-head">
            <div><span class="eyebrow">CONTROL DE ACCESO</span><h3>Usuarios registrados</h3><p>Activa o desactiva cuentas. Oracle impide desactivar al ultimo administrador activo.</p></div>
        </div>
        <div class="table-tools">
            <input type="search" placeholder="Buscar usuario, nombre o rol..." oninput="filterTable(this, 'tbl_users')">
            <span class="muted"><?= count($usuarios) ?> usuario(s)</span>
        </div>
        <div class="table-wrap">
            <table id="tbl_users">
                <thead>
                    <tr><th>ID</th><th>Usuario</th><th>Nombre completo</th><th>Correo</th><th>Rol</th><th>Estado</th><th>Creado</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                    <?php foreach ($usuarios as $u): ?>
                        <tr>
                            <td><?= h($u['ID_USUARIO']) ?></td>
                            <td><b><?= h($u['USERNAME']) ?></b></td>
                            <td><?= h($u['NOMBRE_COMPLETO']) ?></td>
                            <td><?= h($u['EMAIL'] ?? '—') ?></td>
                            <td><?= h($u['NOMBRE_ROL']) ?></td>
                            <td><span class="pill <?= $u['ESTADO'] === 'ACTIVO' ? 'on' : 'off' ?>"><?= h($u['ESTADO']) ?></span></td>
                            <td><?= h($u['FECHA_CREACION'] ?? '—') ?></td>
                            <td class="actions">
                                <?php if ((int)$u['ID_USUARIO'] !== (int)($_SESSION['user']['id'] ?? 0)): ?>
                                    <form method="post" class="inline" onsubmit="return confirm('¿Cambiar el estado de este usuario?')">
                                        <input type="hidden" name="op" value="state">
                                        <input type="hidden" name="id_usuario" value="<?= h($u['ID_USUARIO']) ?>">
                                        <input type="hidden" name="estado" value="<?= $u['ESTADO'] === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO' ?>">
                                        <button class="btn ghost small"><?= $u['ESTADO'] === 'ACTIVO' ? 'Desactivar' : 'Activar' ?></button>
                                    </form>
                                <?php else: ?>
                                    <span class="muted">Sesion actual</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </section>

<?php
/* -------------------------------------------------------------------------
 * GESTORES
 * ------------------------------------------------------------------------- */
} elseif ($page === 'g_viaje') {
    ?>
    <section class="panel form-panel">
        <span class="eyebrow">PLANIFICACION</span><h3>Programar nuevo viaje</h3>
        <p>Invoca <b>LEHZ_PS_GES_PROGRAMAR_VIAJE</b>. Oracle valida la fecha, la ruta y el horario.</p>
        <form method="post" class="form-grid">
            <label>Fecha del viaje<input type="date" name="fecha" required></label>
            <label>Horario
                <select name="horario" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['horarios'] ?? [] as $r): ?>
                        <option value="<?= h($r['ID_HORARIO']) ?>"><?= h($r['HORA_SALIDA']) ?> → <?= h($r['HORA_LLEGADA']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Ruta
                <select name="ruta" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['rutas'] ?? [] as $r): ?>
                        <option value="<?= h($r['ID_RUTA']) ?>">Ruta #<?= h($r['ID_RUTA']) ?> · <?= h($r['TRAYECTO']) ?> (<?= h($r['DISTANCIA']) ?> km)</option>
                    <?php endforeach; ?>
                </select>
            </label>
            <div class="form-actions"><button class="btn primary">Programar viaje →</button></div>
        </form>
    </section>

<?php } elseif ($page === 'g_venta') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">BOLETERIA</span><h3>Registrar venta de boleto</h3>
        <p>El procedimiento registra el boleto y su pago en una sola operacion.</p>
        <form method="post" class="form-grid">
            <label>Pasajero
                <select name="pasajero" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['pasajeros'] ?? [] as $r): ?>
                        <option value="<?= h($r['RUT_PASAJERO']) ?>"><?= h($r['NOMBRE_COMPLETO']) ?> · <?= h($r['RUT_PASAJERO']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Viaje
                <select name="viaje" id="ventaViaje" required onchange="syncBusVenta()">
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['viajes'] ?? [] as $r):
                        if (($r['PATENTE_BUS'] ?? 'SIN ASIGNAR') === 'SIN ASIGNAR') continue;
                    ?>
                        <option value="<?= h($r['ID_VIAJE']) ?>" data-bus="<?= h($r['PATENTE_BUS']) ?>">#<?= h($r['ID_VIAJE']) ?> · <?= h($r['FECHA_VIAJE']) ?> · <?= h($r['TRAYECTO']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Bus
                <select name="bus" id="ventaBus" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['buses'] ?? [] as $r): ?>
                        <option value="<?= h($r['PATENTE_BUS']) ?>"><?= h($r['PATENTE_BUS']) ?> · <?= h(trim(($r['MARCA'] ?? '') . ' ' . ($r['MODELO'] ?? ''))) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Numero de asiento<input type="number" name="asiento" min="1" required></label>
            <label>Valor del boleto ($)<input type="number" name="valor" min="1" required></label>
            <label>Metodo de pago
                <select name="metodo" required>
                    <option value="EFECTIVO">Efectivo</option>
                    <option value="TARJETA">Tarjeta</option>
                    <option value="TRANSFERENCIA">Transferencia</option>
                </select>
            </label>
            <div class="form-actions"><button class="btn primary">Confirmar venta →</button></div>
        </form>
        <div class="notice">Solo se muestran viajes con bus asignado. Oracle verifica que el asiento exista y que no este vendido para ese viaje.</div>
    </section>

<?php } elseif ($page === 'g_conduce') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">ASIGNACION OPERACIONAL</span><h3>Asignar conductor, bus y viaje</h3>
        <p>Invoca <b>LEHZ_PS_GES_ASIGNAR_CONDUCE</b>. Conductor y bus deben pertenecer a la misma empresa.</p>
        <form method="post" class="form-grid">
            <label>Conductor
                <select name="conductor" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['conductores'] ?? [] as $r): ?>
                        <option value="<?= h($r['RUT_CONDUCTOR']) ?>"><?= h($r['NOMBRE_CONDUCTOR'] . ' ' . $r['APELLIDO1_CONDUCTOR']) ?> · <?= h($r['RUT_CONDUCTOR']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Bus
                <select name="bus" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['buses'] ?? [] as $r): ?>
                        <option value="<?= h($r['PATENTE_BUS']) ?>"><?= h($r['PATENTE_BUS']) ?> · <?= h(trim(($r['MARCA'] ?? '') . ' ' . ($r['MODELO'] ?? ''))) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Viaje
                <select name="viaje" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['viajes'] ?? [] as $r): ?>
                        <option value="<?= h($r['ID_VIAJE']) ?>">#<?= h($r['ID_VIAJE']) ?> · <?= h($r['FECHA_VIAJE']) ?> · <?= h($r['TRAYECTO']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <div class="form-actions"><button class="btn primary">Guardar asignacion →</button></div>
        </form>
    </section>

<?php } elseif ($page === 'g_mantencion') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">MANTENCION DE FLOTA</span><h3>Registrar mantención</h3>
        <p>Invoca <b>LEHZ_PS_GES_REGISTRAR_MANTENCION</b>. Mecanico y bus deben pertenecer a la misma empresa.</p>
        <form method="post" class="form-grid">
            <label>Fecha<input type="date" name="fecha" max="<?= date('Y-m-d') ?>" required></label>
            <label>Mecanico
                <select name="mecanico" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['mecanicos'] ?? [] as $r): ?>
                        <option value="<?= h($r['RUT_MECANICO']) ?>"><?= h($r['NOMBRE_MECANICO'] . ' ' . $r['APELLIDO1_MECANICO']) ?> · <?= h($r['RUT_MECANICO']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Bus
                <select name="bus" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['buses'] ?? [] as $r): ?>
                        <option value="<?= h($r['PATENTE_BUS']) ?>"><?= h($r['PATENTE_BUS']) ?> · <?= h(trim(($r['MARCA'] ?? '') . ' ' . ($r['MODELO'] ?? ''))) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Costo ($)<input type="number" name="costo" min="0" required></label>
            <label class="span-2">Descripcion<textarea name="descripcion" rows="3" required></textarea></label>
            <div class="form-actions"><button class="btn primary">Registrar mantención →</button></div>
        </form>
    </section>

<?php } elseif ($page === 'g_terminal') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">RED DE TERMINALES</span><h3>Asociar terminal a empresa</h3>
        <p>Invoca <b>LEHZ_PS_GES_ASOCIAR_TERMINAL</b>.</p>
        <form method="post" class="form-grid">
            <label>Terminal
                <select name="terminal" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['terminales'] ?? [] as $r): ?>
                        <option value="<?= h($r['ID_TERMINAL']) ?>"><?= h($r['NOMBRE']) ?> · <?= h($r['NOMBRE_COMUNA']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Empresa
                <select name="empresa" required>
                    <option value="">Seleccionar...</option>
                    <?php foreach ($lookups['empresas'] ?? [] as $r): ?>
                        <option value="<?= h($r['RUT_EMPRESA']) ?>"><?= h($r['RAZON_SOCIAL']) ?> · <?= h($r['RUT_EMPRESA']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <div class="form-actions"><button class="btn primary">Asociar terminal →</button></div>
        </form>
    </section>

<?php
/* -------------------------------------------------------------------------
 * REPORTES
 * ------------------------------------------------------------------------- */
} elseif (str_starts_with($page, 'r_')) {
    $rk = substr($page, 2);
    if (!isset($reports[$rk])) {
        echo '<section class="panel"><h3>Reporte no encontrado</h3><a href="?page=dashboard">Volver al panel</a></section>';
        layout_end();
        exit;
    }
    $cols = $reportRows ? array_keys($reportRows[0]) : [];
    ?>
    <section class="panel">
        <div class="panel-head">
            <div><span class="eyebrow">ANALISIS Y CONTROL</span><h3><?= h($reports[$rk]['title']) ?></h3><p>Datos obtenidos desde <b><?= h($reports[$rk]['proc']) ?></b>.</p></div>
            <button class="btn ghost" onclick="window.print()">↧ Imprimir / PDF</button>
        </div>
        <?php if ($reportRows): ?>
            <div class="report-summary">
                <div><span>Registros del reporte</span><b><?= count($reportRows) ?></b></div>
                <?php if ($rk === 'recaudacion'):
                    $sum = array_sum(array_map(fn($r) => (float)($r['RECAUDACION_TOTAL'] ?? 0), $reportRows));
                ?>
                    <div><span>Recaudacion acumulada</span><b>$<?= number_format($sum, 0, ',', '.') ?></b></div>
                <?php elseif ($rk === 'mantenciones'):
                    $sum = array_sum(array_map(fn($r) => (float)($r['COSTO_TOTAL_MANTENCIONES'] ?? $r['COSTO_TOTAL_MANTENCION'] ?? 0), $reportRows));
                ?>
                    <div><span>Costo acumulado</span><b>$<?= number_format($sum, 0, ',', '.') ?></b></div>
                <?php endif; ?>
            </div>
            <?php if (in_array($rk, ['recaudacion', 'mantenciones'], true)): ?>
                <div class="chart-box"><canvas id="reportChart" height="95"></canvas></div>
            <?php endif; ?>
            <div class="table-tools">
                <input type="search" placeholder="Buscar en el reporte..." oninput="filterTable(this, 'tbl_report')">
                <span class="muted"><?= count($reportRows) ?> fila(s)</span>
            </div>
            <div class="table-wrap">
                <table id="tbl_report">
                    <thead><tr><?php foreach ($cols as $col): ?><th><?= h(pretty_col($col)) ?></th><?php endforeach; ?></tr></thead>
                    <tbody>
                        <?php foreach ($reportRows as $r): ?>
                            <tr><?php foreach ($cols as $col): ?><td><?= h($r[$col] ?? '—') ?></td><?php endforeach; ?></tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php else: ?>
            <div class="empty-state"><b>No hay datos para mostrar</b><p>Cuando existan registros operacionales, apareceran en este reporte.</p></div>
        <?php endif; ?>
    </section>
    <?php if ($reportRows && in_array($rk, ['recaudacion', 'mantenciones'], true)): ?>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script>
        new Chart(document.getElementById('reportChart'), {
            type: 'bar',
            data: {
                labels: <?= json_encode(array_map(fn($r) => $rk === 'recaudacion' ? ('Viaje ' . $r['ID_VIAJE']) : $r['PATENTE_BUS'], $reportRows)) ?>,
                datasets: [{
                    label: <?= json_encode($rk === 'recaudacion' ? 'Recaudacion' : 'Costo de mantenciones') ?>,
                    data: <?= json_encode(array_map(fn($r) => (float)($rk === 'recaudacion' ? ($r['RECAUDACION_TOTAL'] ?? 0) : ($r['COSTO_TOTAL_MANTENCIONES'] ?? $r['COSTO_TOTAL_MANTENCION'] ?? 0)), $reportRows)) ?>,
                    borderRadius: 7,
                    backgroundColor: '#4778e8'
                }]
            },
            options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
        });
        </script>
    <?php endif; ?>

<?php } else { ?>
    <section class="panel"><h3>Modulo no encontrado</h3><a href="?page=dashboard">Volver al panel</a></section>
<?php }
layout_end();
