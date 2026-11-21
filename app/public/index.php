<?php
session_start();
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../auth/auth.php';

$maintainers = [
    'regiones' => [
        'title'   => 'Regiones',
        'proc'    => 'LEHZ_PS_IUD_REGION',
        'list'    => 'LEHZ_PS_LISTAR_REGIONES',
        'id'      => 'ID_REGION',
        'idparam' => 'p_id_region',
        'fields'  => [
            [
                'name'        => 'NOMBRE_REGION',
                'label'       => 'Nombre de la región (escribe para filtrar o haz clic)',
                'param'       => 'p_nombre_region',
                'type'        => 'text',
                'placeholder' => 'Ej. Región del Maule',
                'strict'      => true,
                'options'     => [
                    'Región de Arica y Parinacota',
                    'Región de Tarapacá',
                    'Región de Antofagasta',
                    'Región de Atacama',
                    'Región de Coquimbo',
                    'Región de Valparaíso',
                    'Región Metropolitana de Santiago',
                    "Región del Libertador General Bernardo O'Higgins",
                    'Región del Maule',
                    'Región de Ñuble',
                    'Región del Biobío',
                    'Región de La Araucanía',
                    'Región de Los Ríos',
                    'Región de Los Lagos',
                    'Región Aysén del General Carlos Ibáñez del Campo',
                    'Región de Magallanes y de la Antártica Chilena'
                ]
            ]
        ]
    ],
    'comunas' => [
        'title'   => 'Comunas',
        'proc'    => 'LEHZ_PS_IUD_COMUNA',
        'list'    => 'LEHZ_PS_LISTAR_COMUNAS',
        'id'      => 'ID_COMUNA',
        'idparam' => 'p_id_comuna',
        'fields'  => [
            ['name' => 'NOMBRE_COMUNA', 'label' => 'Nombre de la comuna', 'param' => 'p_nombre_comuna', 'type' => 'text'],
            ['name' => 'ID_REGION', 'label' => 'Región', 'param' => 'p_id_region', 'type' => 'lookup', 'source' => 'regiones', 'display' => 'NOMBRE_REGION', 'value' => 'ID_REGION']
        ]
    ],
    'terminales' => [
        'title'   => 'Terminales',
        'proc'    => 'LEHZ_PS_IUD_TERMINAL',
        'list'    => 'LEHZ_PS_LISTAR_TERMINALES',
        'id'      => 'ID_TERMINAL',
        'idparam' => 'p_id_terminal',
        'fields'  => [
            ['name' => 'NOMBRE', 'label' => 'Nombre', 'param' => 'p_nombre', 'type' => 'text'],
            ['name' => 'CALLE', 'label' => 'Calle', 'param' => 'p_calle', 'type' => 'text'],
            ['name' => 'NUMERO', 'label' => 'Número', 'param' => 'p_numero', 'type' => 'number', 'min' => 1],
            ['name' => 'ID_COMUNA', 'label' => 'Comuna', 'param' => 'p_id_comuna', 'type' => 'lookup', 'source' => 'comunas', 'display' => 'NOMBRE_COMUNA', 'value' => 'ID_COMUNA']
        ]
    ],
    'empresas' => [
        'title'       => 'Empresas',
        'proc'        => 'LEHZ_PS_IUD_EMPRESA',
        'list'        => 'LEHZ_PS_LISTAR_EMPRESAS',
        'id'          => 'RUT_EMPRESA',
        'idparam'     => 'p_rut_empresa',
        'manualid'    => 'RUT_EMPRESA',
        'manuallabel' => 'RUT de la empresa (7 u 8 dígitos, sin DV)',
        'idpattern'   => '^\d{7,8}$',
        'idtitle'     => 'Ingresa 7 u 8 dígitos numéricos sin puntos ni dígito verificador',
        'fields'      => [
            ['name' => 'RAZON_SOCIAL', 'label' => 'Razón social', 'param' => 'p_razon_social', 'type' => 'text'],
            [
                'name'    => 'TELEFONO_EMPRESA',
                'label'   => 'Teléfono empresa (9 dígitos: fijo o móvil)',
                'param'   => 'p_telefono',
                'type'    => 'tel',
                'pattern' => '^(2\d{8}|[3-7]\d{8}|9\d{8})$',
                'title'   => '9 dígitos en Chile: fijo (ej. 712234455, 223456789) o móvil (ej. 912345678)'
            ],
            ['name' => 'CORREO_ELECTRONICO_EMPRESA', 'label' => 'Correo electrónico', 'param' => 'p_correo', 'type' => 'email']
        ]
    ],
    'buses' => [
        'title'       => 'Buses',
        'proc'        => 'LEHZ_PS_IUD_BUS',
        'list'        => 'LEHZ_PS_LISTAR_BUSES',
        'id'          => 'PATENTE_BUS',
        'idparam'     => 'p_patente',
        'manualid'    => 'PATENTE_BUS',
        'manuallabel' => 'Patente del bus (ej. ABCD12)',
        'idpattern'   => '^[A-Za-z0-9]{6}$',
        'idtitle'     => '6 caracteres alfanuméricos sin guion (ej. ABCD12)',
        'fields'      => [
            ['name' => 'MARCA', 'label' => 'Marca', 'param' => 'p_marca', 'type' => 'text'],
            ['name' => 'MODELO', 'label' => 'Modelo', 'param' => 'p_modelo', 'type' => 'text'],
            ['name' => 'AÑO_FABRICACION', 'label' => 'Año de fabricación', 'param' => 'p_anio', 'type' => 'number', 'min' => 1990, 'max' => 2030],
            ['name' => 'CAPACIDAD', 'label' => 'Capacidad', 'param' => 'p_capacidad', 'type' => 'number', 'min' => 10, 'max' => 80],
            ['name' => 'RUT_EMPRESA', 'label' => 'Empresa', 'param' => 'p_rut_empresa', 'type' => 'lookup', 'source' => 'empresas', 'display' => 'RAZON_SOCIAL', 'value' => 'RUT_EMPRESA']
        ]
    ],
    'asientos' => [
        'title'       => 'Asientos',
        'proc'        => 'LEHZ_PS_IUD_ASIENTO',
        'list'        => 'LEHZ_PS_LISTAR_ASIENTOS',
        'id'          => 'NUMERO_ASIENTO',
        'idparam'     => 'p_nro_asiento',
        'manualid'    => 'NUMERO_ASIENTO',
        'manuallabel' => 'Número de asiento',
        'fields'      => [
            ['name' => 'PATENTE_BUS', 'label' => 'Bus', 'param' => 'p_patente', 'type' => 'lookup', 'source' => 'buses', 'display' => 'PATENTE_BUS', 'value' => 'PATENTE_BUS'],
            ['name' => 'UBICACION', 'label' => 'Ubicación', 'param' => 'p_ubicacion', 'type' => 'text']
        ]
    ],
    'conductores' => [
        'title'       => 'Conductores',
        'proc'        => 'LEHZ_PS_IUD_CONDUCTOR',
        'list'        => 'LEHZ_PS_LISTAR_CONDUCTORES',
        'id'          => 'RUT_CONDUCTOR',
        'idparam'     => 'p_rut',
        'manualid'    => 'RUT_CONDUCTOR',
        'manuallabel' => 'RUT del conductor (7 u 8 dígitos, sin DV)',
        'idpattern'   => '^\d{7,8}$',
        'idtitle'     => 'Ingresa 7 u 8 dígitos numéricos sin puntos ni dígito verificador',
        'fields'      => [
            ['name' => 'NOMBRE_CONDUCTOR', 'label' => 'Nombre', 'param' => 'p_nombre', 'type' => 'text'],
            ['name' => 'APELLIDO1_CONDUCTOR', 'label' => 'Primer apellido', 'param' => 'p_apellido1', 'type' => 'text'],
            ['name' => 'APELLIDO2_CONDUCTOR', 'label' => 'Segundo apellido', 'param' => 'p_apellido2', 'type' => 'text'],
            ['name' => 'TIPO_LICENCIA', 'label' => 'Tipo de licencia (ej. A3)', 'param' => 'p_tipo_licencia', 'type' => 'text'],
            ['name' => 'VENCIMIENTO_LICENCIA', 'label' => 'Vencimiento de licencia', 'param' => 'p_vencimiento', 'type' => 'date'],
            ['name' => 'RUT_EMPRESA', 'label' => 'Empresa', 'param' => 'p_rut_empresa', 'type' => 'lookup', 'source' => 'empresas', 'display' => 'RAZON_SOCIAL', 'value' => 'RUT_EMPRESA']
        ]
    ],
    'mecanicos' => [
        'title'       => 'Mecánicos',
        'proc'        => 'LEHZ_PS_IUD_MECANICO',
        'list'        => 'LEHZ_PS_LISTAR_MECANICOS',
        'id'          => 'RUT_MECANICO',
        'idparam'     => 'p_rut',
        'manualid'    => 'RUT_MECANICO',
        'manuallabel' => 'RUT del mecánico (7 u 8 dígitos, sin DV)',
        'idpattern'   => '^\d{7,8}$',
        'idtitle'     => 'Ingresa 7 u 8 dígitos numéricos sin puntos ni dígito verificador',
        'fields'      => [
            ['name' => 'NOMBRE_MECANICO', 'label' => 'Nombre', 'param' => 'p_nombre', 'type' => 'text'],
            ['name' => 'APELLIDO1_MECANICO', 'label' => 'Primer apellido', 'param' => 'p_apellido1', 'type' => 'text'],
            ['name' => 'APELLIDO2_MECANICO', 'label' => 'Segundo apellido', 'param' => 'p_apellido2', 'type' => 'text'],
            ['name' => 'ESPECIALIDAD', 'label' => 'Especialidad', 'param' => 'p_especialidad', 'type' => 'text'],
            ['name' => 'RUT_EMPRESA', 'label' => 'Empresa', 'param' => 'p_rut_empresa', 'type' => 'lookup', 'source' => 'empresas', 'display' => 'RAZON_SOCIAL', 'value' => 'RUT_EMPRESA']
        ]
    ],
    'rutas' => [
        'title'   => 'Rutas',
        'proc'    => 'LEHZ_PS_IUD_RUTA',
        'list'    => 'LEHZ_PS_LISTAR_RUTAS',
        'id'      => 'ID_RUTA',
        'idparam' => 'p_id_ruta',
        'fields'  => [
            ['name' => 'HORARIO', 'label' => 'Fecha y hora de referencia', 'param' => 'p_horario', 'type' => 'datetime-local'],
            ['name' => 'DISTANCIA', 'label' => 'Distancia (km)', 'param' => 'p_distancia', 'type' => 'number', 'min' => 1],
            ['name' => 'HORAS_ESTIMADAS', 'label' => 'Horas estimadas', 'param' => 'p_horas_est', 'type' => 'number', 'min' => 0],
            ['name' => 'MINUTOS_ESTIMADOS', 'label' => 'Minutos estimados', 'param' => 'p_minutos_est', 'type' => 'number', 'min' => 0, 'max' => 59]
        ]
    ],
    'horarios' => [
        'title'   => 'Horarios',
        'proc'    => 'LEHZ_PS_IUD_HORARIO',
        'list'    => 'LEHZ_PS_LISTAR_HORARIOS',
        'id'      => 'ID_HORARIO',
        'idparam' => 'p_id_horario',
        'fields'  => [
            ['name' => 'HORARIO', 'label' => 'Código de horario', 'param' => 'p_horario_val', 'type' => 'number', 'min' => 1],
            ['name' => 'HORA_SALIDA', 'label' => 'Hora de salida', 'param' => 'p_hora_salida', 'type' => 'datetime-local'],
            ['name' => 'HORA_LLEGADA', 'label' => 'Hora de llegada', 'param' => 'p_hora_llegada', 'type' => 'datetime-local']
        ]
    ],
];

$managers = [
    'venta'      => 'Venta de boleto',
    'viaje'      => 'Programar viaje',
    'conduce'    => 'Asignar conductor y bus',
    'mantencion' => 'Registrar mantención',
    'terminal'   => 'Asociar terminal a empresa'
];

$reports = [
    'recaudacion'  => ['title' => 'Recaudación por viajes', 'proc' => 'LEHZ_PS_REP_RECAUDACION_VIAJES'],
    'mantenciones' => ['title' => 'Costos de mantención', 'proc' => 'LEHZ_PS_REP_COSTOS_MANTENCION'],
    'ocupacion'    => ['title' => 'Ocupación de asientos', 'proc' => 'LEHZ_PS_REP_OCUPACION_ASIENTOS']
];

$page    = $_GET['page'] ?? (empty($_SESSION['user']) ? 'login' : 'dashboard');
$error   = '';
$success = '';

function h($v): string {
    return htmlspecialchars((string)($v ?? ''), ENT_QUOTES, 'UTF-8');
}

function friendly_error(Throwable $e): string {
    $msg = $e->getMessage();

    if (str_contains($msg, 'CK_EMPRESA_TEL')) {
        return 'Dato inválido: El Teléfono de la empresa debe tener 9 dígitos válidos en Chile (fijo ej. 712234455, Santiago 22XXXXXXX o móvil 9XXXXXXXX).';
    }
    if (str_contains($msg, 'CK_EMPRESA_RUT')) {
        return 'Dato inválido: El RUT de la empresa debe ser un número entre 5.000.000 y 99.999.999 (7 u 8 dígitos sin puntos ni dígito verificador).';
    }
    if (str_contains($msg, 'CK_CONDUCTOR_RUT')) {
        return 'Dato inválido: El RUT del conductor debe tener entre 7 y 8 dígitos numéricos (sin puntos ni dígito verificador).';
    }
    if (str_contains($msg, 'CK_MECANICO_RUT')) {
        return 'Dato inválido: El RUT del mecánico debe tener entre 7 y 8 dígitos numéricos (sin puntos ni dígito verificador).';
    }
    if (preg_match('/ORA-20\d{3}:\s*(.+?)(?:\s*ORA-|\s*Help:|$)/s', $msg, $m)) {
        return 'Dato inválido: ' . trim($m[1]);
    }
    if (str_contains($msg, 'ORA-00001')) {
        return 'Dato inválido: Ya existe un registro con ese mismo identificador (RUT, patente o código duplicado).';
    }
    if (str_contains($msg, 'ORA-02292')) {
        return 'No se puede eliminar: Este registro está siendo utilizado en otros módulos (viajes, buses, comunas, etc.).';
    }
    if (str_contains($msg, 'ORA-02291')) {
        return 'Dato inválido: Uno de los valores seleccionados (bus, ruta, empresa o pasajero) no existe en el sistema.';
    }

    return $msg;
}

if ($page === 'logout') {
    session_destroy();
    header('Location: ?page=login');
    exit;
}

if ($page === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $c   = db();
        $sql = "SELECT u.ID_USUARIO, u.USERNAME, u.NOMBRE_COMPLETO, u.EMAIL, r.NOMBRE_ROL 
                FROM LEHZ_USUARIO u 
                JOIN LEHZ_ROL r ON r.ID_ROL = u.ID_ROL 
                WHERE LOWER(u.USERNAME) = LOWER(:username) 
                  AND u.PASSWORD_HASH = :hash 
                  AND u.ESTADO = 'ACTIVO'";
        $st       = oci_parse($c, $sql);
        $username = trim($_POST['username'] ?? '');
        $hash     = strtoupper(hash('sha256', $_POST['password'] ?? ''));

        oci_bind_by_name($st, ':username', $username);
        oci_bind_by_name($st, ':hash', $hash);
        oci_execute($st);
        $u = oci_fetch_assoc($st);

        if ($u) {
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'id'       => $u['ID_USUARIO'],
                'username' => $u['USERNAME'],
                'name'     => $u['NOMBRE_COMPLETO'],
                'email'    => $u['EMAIL'],
                'role'     => $u['NOMBRE_ROL']
            ];
            header('Location: ?page=dashboard');
            exit;
        } else {
            $error = 'Usuario o contraseña incorrectos, o cuenta inactiva.';
        }
    } catch (Throwable $e) {
        $error = friendly_error($e);
    }
}

if ($page !== 'login') {
    require_login();
}
if (str_starts_with($page, 'm_') || in_array($page, ['g_viaje', 'g_conduce', 'g_mantencion', 'g_terminal'], true)) {
    require_role(['ADMINISTRADOR', 'OPERACIONES']);
}
if ($page === 'g_venta') {
    require_role(['ADMINISTRADOR', 'VENDEDOR']);
}
if (isset($_SESSION['user']) && $page === 'login') {
    header('Location: ?page=dashboard');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $page !== 'login') {
    try {
        if (str_starts_with($page, 'm_')) {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            $key       = substr($page, 2);
            $m         = $maintainers[$key];
            $op        = $_POST['op'] ?? 'I';
            $fieldvals = [];

            foreach ($m['fields'] as $f) {
                $v = isset($_POST[$f['name']]) ? trim((string)$_POST[$f['name']]) : null;
                if ($v === '') {
                    $v = null;
                }

                if ($op !== 'D' && !empty($f['strict']) && !empty($f['options'])) {
                    if ($v === null || !in_array($v, $f['options'], true)) {
                        throw new RuntimeException('Dato inválido: Debes seleccionar una opción válida de la lista (' . $f['label'] . ').');
                    }
                }

                if (in_array($f['type'], ['date', 'datetime-local'], true) && $v !== null) {
                    if ($f['type'] === 'date') {
                        $expr = "TO_DATE(:{$f['param']},'YYYY-MM-DD')";
                    } else {
                        $expr = "TO_TIMESTAMP(:{$f['param']},'YYYY-MM-DD HH24:MI')";
                        $v    = str_replace('T', ' ', $v);
                    }
                    $fieldvals[$f['param']] = ['value' => $v, 'expr' => $expr];
                } else {
                    if ($f['name'] === 'PATENTE_BUS' && $v !== null) {
                        $v = strtoupper($v);
                    }
                    $fieldvals[$f['param']] = $v;
                }
            }

            $idname = $m['idparam'];
            $rawId  = isset($m['manualid']) && $op === 'I'
                ? trim((string)($_POST['manual_id'] ?? ''))
                : trim((string)($_POST['record_id'] ?? ''));

            if ($op !== 'D') {
                if (in_array($key, ['empresas', 'conductores', 'mecanicos'], true)) {
                    if (!preg_match('/^\d{7,8}$/', $rawId)) {
                        throw new RuntimeException('Dato inválido: El RUT debe contener exactamente 7 u 8 dígitos numéricos (sin puntos ni dígito verificador).');
                    }
                }
                if ($key === 'buses' && !preg_match('/^[A-Za-z0-9]{6}$/', $rawId)) {
                    throw new RuntimeException('Dato inválido: La patente del bus debe tener 6 caracteres alfanuméricos sin guion (ej. ABCD12).');
                }
                if ($key === 'empresas') {
                    $tel = trim((string)($_POST['TELEFONO_EMPRESA'] ?? ''));
                    if (!preg_match('/^(2\d{8}|[3-7]\d{8}|9\d{8})$/', $tel)) {
                        throw new RuntimeException('Dato inválido: El teléfono de empresa debe tener 9 dígitos válidos en Chile (fijo regional ej. 712234455, Santiago 22XXXXXXX o celular 9XXXXXXXX).');
                    }
                }
            }

            if (in_array($key, ['empresas', 'conductores', 'mecanicos'], true)) {
                $idvalue = (float)$rawId;
            } elseif ($key === 'buses') {
                $idvalue = strtoupper($rawId);
            } else {
                $idvalue = $rawId === '' ? 0 : (float)$rawId;
            }

            $vals = ['p_opcion' => $op, $idname => $idvalue] + $fieldvals;
            if ($key === 'asientos' && $op === 'D') {
                $vals['p_patente'] = strtoupper($_POST['PATENTE_BUS'] ?? '');
            }

            $binds = [];
            $args  = [];
            foreach ($vals as $k => $v) {
                if (is_array($v)) {
                    $args[]    = $v['expr'];
                    $binds[$k] = $v['value'];
                } else {
                    $args[]    = ':' . $k;
                    $binds[$k] = $v;
                }
            }

            $block = 'BEGIN ' . $m['proc'] . '(' . implode(',', $args) . '); END;';
            db_call($block, $binds);

            $success = $op === 'D'
                ? 'Registro eliminado correctamente.'
                : ($op === 'U' ? 'Registro actualizado correctamente.' : 'Registro creado correctamente.');

        } elseif ($page === 'g_viaje') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            $v = db_call(
                "BEGIN LEHZ_PS_GES_PROGRAMAR_VIAJE(TO_DATE(:fecha,'YYYY-MM-DD'),:horario,:ruta,:nuevo); END;",
                ['fecha' => $_POST['fecha'], 'horario' => (int)$_POST['horario'], 'ruta' => (int)$_POST['ruta'], 'nuevo' => 0]
            );
            $success = 'Viaje programado correctamente. ID: ' . $v['nuevo'];

        } elseif ($page === 'g_venta') {
            require_role(['ADMINISTRADOR', 'VENDEDOR']);
            $v = db_call(
                "BEGIN LEHZ_PS_GES_VENDER_BOLETO(:valor,:pasajero,:viaje,:asiento,:bus,:metodo,:nuevo); END;",
                [
                    'valor'    => (float)$_POST['valor'],
                    'pasajero' => (float)$_POST['pasajero'],
                    'viaje'    => (int)$_POST['viaje'],
                    'asiento'  => (int)$_POST['asiento'],
                    'bus'      => strtoupper($_POST['bus']),
                    'metodo'   => $_POST['metodo'],
                    'nuevo'    => 0
                ]
            );
            $success = 'Boleto vendido y pago registrado. Folio: ' . $v['nuevo'];

        } elseif ($page === 'g_conduce') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            db_call(
                "BEGIN LEHZ_PS_GES_ASIGNAR_CONDUCE(:conductor,:bus,:viaje); END;",
                ['conductor' => (float)$_POST['conductor'], 'bus' => strtoupper($_POST['bus']), 'viaje' => (int)$_POST['viaje']]
            );
            $success = 'Asignación registrada correctamente.';

        } elseif ($page === 'g_mantencion') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            $v = db_call(
                "BEGIN LEHZ_PS_GES_REGISTRAR_MANTENCION(TO_DATE(:fecha,'YYYY-MM-DD'),:descripcion,:costo,:mecanico,:bus,:nuevo); END;",
                [
                    'fecha'       => $_POST['fecha'],
                    'descripcion' => $_POST['descripcion'],
                    'costo'       => (float)$_POST['costo'],
                    'mecanico'    => (float)$_POST['mecanico'],
                    'bus'         => strtoupper($_POST['bus']),
                    'nuevo'       => 0
                ]
            );
            $success = 'Mantención registrada. ID: ' . $v['nuevo'];

        } elseif ($page === 'g_terminal') {
            require_role(['ADMINISTRADOR', 'OPERACIONES']);
            db_call(
                "BEGIN LEHZ_PS_GES_ASOCIAR_TERMINAL(:terminal,:empresa); END;",
                ['terminal' => (int)$_POST['terminal'], 'empresa' => (float)$_POST['empresa']]
            );
            $success = 'Terminal asociado a la empresa correctamente.';
        }
    } catch (Throwable $e) {
        $error = friendly_error($e);
    }
}

$rows       = [];
$reportRows = [];
$lookups    = [];

try {
    if (str_starts_with($page, 'm_')) {
        $key  = substr($page, 2);
        $m    = $maintainers[$key];
        $rows = db_rows($m['list']);
        foreach ($m['fields'] as $f) {
            if (($f['type'] ?? '') === 'lookup') {
                $lookups[$f['source']] = db_rows($maintainers[$f['source']]['list']);
            }
        }
    }
    if (str_starts_with($page, 'r_')) {
        $rk         = substr($page, 2);
        $reportRows = db_rows($reports[$rk]['proc']);
    }
    if (in_array($page, ['g_viaje', 'g_venta', 'g_conduce', 'g_mantencion', 'g_terminal'], true)) {
        foreach (['empresas', 'buses', 'conductores', 'mecanicos', 'rutas', 'horarios', 'terminales'] as $k) {
            $lookups[$k] = db_rows($maintainers[$k]['list']);
        }
        $c = db();

        $lookups['viajes'] = [];
        $sv = oci_parse($c, "SELECT v.ID_VIAJE, TO_CHAR(v.FECHA_VIAJE,'DD/MM/YYYY') AS FECHA_VIAJE, r.DISTANCIA FROM LEHZ_VIAJE v LEFT JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA ORDER BY v.ID_VIAJE DESC");
        oci_execute($sv);
        while ($rv = oci_fetch_assoc($sv)) {
            $lookups['viajes'][] = $rv;
        }

        $lookups['pasajeros'] = [];
        $sp = oci_parse($c, "SELECT RUT_PASAJERO, NOMBRE_PASAJERO||' '||APELLIDO1_PASAJERO AS NOMBRE FROM LEHZ_PASAJERO ORDER BY NOMBRE_PASAJERO");
        oci_execute($sp);
        while ($rp = oci_fetch_assoc($sp)) {
            $lookups['pasajeros'][] = $rp;
        }
    }
} catch (Throwable $e) {
    $error = $error ?: friendly_error($e);
}

$navGroups = [
    'GENERAL'        => [['dashboard', 'Panel principal', '⌂']],
    'ADMINISTRACIÓN' => array_map(fn($k) => ['m_' . $k, $maintainers[$k]['title'], '▦'], array_keys($maintainers)),
    'OPERACIONES'    => [
        ['g_viaje', 'Programar viaje', '↗'],
        ['g_conduce', 'Asignar conductor', '⇄'],
        ['g_mantencion', 'Mantenciones', '⚙'],
        ['g_terminal', 'Asociar terminal', '⌑']
    ],
    'VENTAS'         => [['g_venta', 'Vender boleto', '▣']],
    'REPORTES'       => [
        ['r_recaudacion', 'Recaudación', '▤'],
        ['r_mantenciones', 'Costos de mantención', '▤'],
        ['r_ocupacion', 'Ocupación', '▤']
    ]
];

function layout_start($title, $active, $navGroups) {
    $user = $_SESSION['user'] ?? null;
    ?><!doctype html>
    <html lang="es">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title><?= h($title) ?> · RutaGestión</title>
        <link rel="stylesheet" href="assets/css/app.css">
        <style>
            .modal input[type="text"],
            .modal input[type="email"],
            .modal textarea {
                text-transform: none !important;
            }
            .modal input#manualId[name="manual_id"] {
                text-transform: uppercase;
            }
        </style>
    </head>
    <body>
    <div class="shell">
        <aside class="sidebar">
            <a class="brand" href="?page=dashboard">
                <span class="brand-icon">R</span>
                <span><b>RutaGestión</b><small>TRANSPORTE REGIONAL</small></span>
            </a>
            <div class="side-user">
                <div class="avatar"><?= h(strtoupper(substr($user['name'] ?? 'U', 0, 1))) ?></div>
                <div><b><?= h($user['name'] ?? 'Usuario') ?></b><small><?= h($user['role'] ?? '') ?></small></div>
            </div>
            <nav>
                <?php foreach ($navGroups as $group => $items): ?>
                    <div class="nav-label"><?= $group ?></div>
                    <?php foreach ($items as $it):
                        if (in_array($it[0], ['g_venta']) && !in_array($user['role'], ['ADMINISTRADOR', 'VENDEDOR'])) continue;
                        if (in_array($it[0], ['g_viaje', 'g_conduce', 'g_mantencion', 'g_terminal']) && !in_array($user['role'], ['ADMINISTRADOR', 'OPERACIONES'])) continue;
                        if (str_starts_with($it[0], 'm_') && !in_array($user['role'], ['ADMINISTRADOR', 'OPERACIONES'])) continue;
                    ?>
                        <a class="nav-link <?= $active === $it[0] ? 'active' : '' ?>" href="?page=<?= $it[0] ?>">
                            <span><?= $it[2] ?></span><?= h($it[1]) ?>
                        </a>
                    <?php endforeach; ?>
                <?php endforeach; ?>
            </nav>
            <a class="logout" href="?page=logout">↪ Cerrar sesión</a>
        </aside>
        <main class="main">
            <header class="topbar">
                <div><span class="eyebrow">SISTEMA DE GESTIÓN INTEGRAL</span><h1><?= h($title) ?></h1></div>
                <div class="top-user"><span class="status-dot"></span> Conectado <b><?= h($user['username'] ?? '') ?></b></div>
            </header>
            <div class="content">
    <?php
}

function layout_end() {
    ?>
            </div>
            <footer>RutaGestión · Sistema de Gestión Integral de Transporte Público Regional</footer>
        </main>
    </div>
    <script src="assets/js/app.js"></script>
    </body>
    </html>
    <?php
}

if ($page === 'login') {
    ?><!doctype html>
    <html lang="es">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Iniciar sesión · RutaGestión</title>
        <link rel="stylesheet" href="assets/css/app.css">
    </head>
    <body class="login-body">
    <div class="login-wrap">
        <section class="login-art">
            <div class="art-brand"><span class="brand-icon">R</span> RutaGestión</div>
            <div class="art-copy">
                <span class="eyebrow">PLATAFORMA DE OPERACIONES</span>
                <h1>Conectamos<br>personas y<br><em>regiones.</em></h1>
                <p>Administra flotas, viajes, pasajeros y operaciones desde un solo lugar.</p>
            </div>
            <div class="art-footer">GESTIÓN INTELIGENTE · TRANSPORTE REGIONAL</div>
        </section>
        <section class="login-panel">
            <div class="login-form">
                <span class="eyebrow">BIENVENIDO DE VUELTA</span>
                <h2>Iniciar sesión</h2>
                <p>Ingresa tus credenciales para continuar.</p>
                <?php if ($error): ?><div class="alert error"><?= h($error) ?></div><?php endif; ?>
                <form method="post">
                    <label>Nombre de usuario<input name="username" required autocomplete="username" placeholder="Ej. admin"></label>
                    <label>Contraseña<input type="password" name="password" required autocomplete="current-password" placeholder="Tu contraseña"></label>
                    <button class="btn primary full">Ingresar al sistema <span>→</span></button>
                </form>
                <div class="login-note">Acceso protegido mediante usuarios y roles de Oracle.</div>
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
    $title = $maintainers[substr($page, 2)]['title'];
} elseif (str_starts_with($page, 'r_')) {
    $title = $reports[substr($page, 2)]['title'];
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

if ($page === 'dashboard') {
    $stats = [];
    try {
        $c = db();
        foreach (['Empresas' => 'LEHZ_EMPRESA', 'Buses' => 'LEHZ_BUS', 'Viajes' => 'LEHZ_VIAJE', 'Pasajeros' => 'LEHZ_PASAJERO', 'Boletos vendidos' => 'LEHZ_BOLETO'] as $label => $tab) {
            $s = oci_parse($c, "SELECT COUNT(*) AS TOTAL FROM {$tab}");
            oci_execute($s);
            $r = oci_fetch_assoc($s);
            $stats[$label] = $r['TOTAL'];
        }
    } catch (Throwable $e) {
        $error = friendly_error($e);
    }
    ?>
    <div class="welcome">
        <div>
            <span class="eyebrow">RESUMEN OPERACIONAL</span>
            <h2>Hola, <?= h(explode(' ', $_SESSION['user']['name'])[0]) ?> 👋</h2>
            <p>Este es el estado general de tu sistema de transporte.</p>
        </div>
        <div class="welcome-date"><?= date('d/m/Y') ?> <small>FECHA DE CONSULTA</small></div>
    </div>
    <div class="stat-grid">
        <?php foreach ($stats as $k => $v): ?>
            <article class="stat-card">
                <span><?= h($k) ?></span>
                <strong><?= number_format((float)$v, 0, ',', '.') ?></strong>
                <small>Registros en Oracle</small>
            </article>
        <?php endforeach; ?>
    </div>
    <div class="dashboard-grid">
        <section class="panel">
            <div class="panel-head"><div><span class="eyebrow">ACCESOS RÁPIDOS</span><h3>Operaciones frecuentes</h3></div></div>
            <div class="quick-grid">
                <a href="?page=g_venta"><b>▣</b><span>Vender boleto</span><small>Registrar venta y pago</small></a>
                <a href="?page=g_viaje"><b>↗</b><span>Programar viaje</span><small>Crear nueva salida</small></a>
                <a href="?page=g_mantencion"><b>⚙</b><span>Registrar mantención</span><small>Control de flota</small></a>
                <a href="?page=r_recaudacion"><b>▤</b><span>Ver recaudación</span><small>Consultar resultados</small></a>
            </div>
        </section>
        <section class="panel side-panel">
            <span class="eyebrow">ESTADO DEL SISTEMA</span>
            <h3>Base de datos</h3>
            <div class="db-status"><i></i><b>Oracle · LEHZ</b><span>Conexión activa</span></div>
            <p>Los módulos ejecutan los procedimientos almacenados definidos en el proyecto SQL.</p>
        </section>
    </div>

<?php } elseif (str_starts_with($page, 'm_')) {
    $key = substr($page, 2);
    $m   = $maintainers[$key];
    ?>
    <section class="panel">
        <div class="panel-head">
            <div><span class="eyebrow">GESTIÓN DE DATOS</span><h3><?= h($m['title']) ?></h3><p>Crear, editar y eliminar registros mediante el procedimiento <?= h($m['proc']) ?>.</p></div>
            <button class="btn primary" onclick="openCreate()">＋ Nuevo registro</button>
        </div>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <?php foreach (array_merge([$m['id']], array_column($m['fields'], 'name')) as $col): ?>
                            <th><?= h(str_replace('_', ' ', $col)) ?></th>
                        <?php endforeach; ?>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($rows as $r): ?>
                        <tr>
                            <?php foreach (array_merge([$m['id']], array_column($m['fields'], 'name')) as $col): ?>
                                <td><?= h($r[$col] ?? '—') ?></td>
                            <?php endforeach; ?>
                            <td class="actions">
                                <button class="icon-btn" title="Editar" onclick='editRow(<?= json_encode($r, JSON_HEX_APOS | JSON_HEX_QUOT) ?>)'>✎</button>
                                <form method="post" class="inline" onsubmit="return confirm('¿Eliminar este registro?')">
                                    <input type="hidden" name="op" value="D">
                                    <input type="hidden" name="record_id" value="<?= h($r[$m['id']]) ?>">
                                    <?php if ($key === 'asientos'): ?><input type="hidden" name="PATENTE_BUS" value="<?= h($r['PATENTE_BUS']) ?>"><?php endif; ?>
                                    <button class="icon-btn danger" title="Eliminar">⌫</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (!$rows): ?>
                        <tr><td colspan="<?= count($m['fields']) + 2 ?>" class="empty">Todavía no hay registros.</td></tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </section>

    <div class="modal" id="recordModal">
        <div class="modal-card" style="overflow:visible;">
            <div class="modal-head">
                <div><span class="eyebrow">FORMULARIO</span><h3 id="modalTitle">Nuevo registro</h3></div>
                <button class="icon-btn" onclick="closeModal()">×</button>
            </div>
            <form method="post" id="recordForm">
                <input type="hidden" name="op" id="formOp" value="I">
                <input type="hidden" name="record_id" id="recordId">

                <?php if (isset($m['manualid'])): ?>
                    <label><?= h($m['manuallabel']) ?>
                        <input name="manual_id" id="manualId" <?= isset($m['idpattern']) ? 'pattern="' . h($m['idpattern']) . '"' : '' ?> <?= isset($m['idtitle']) ? 'title="' . h($m['idtitle']) . '"' : '' ?> required>
                    </label>
                <?php endif; ?>

                <?php foreach ($m['fields'] as $f): ?>
                    <?php if (!empty($f['options'])): ?>
                        <div class="combo-wrap" style="grid-column:1 / -1;display:grid;gap:8px;font-size:12px;font-weight:700;color:#47546b;" data-strict="<?= !empty($f['strict']) ? '1' : '0' ?>">
                            <span><?= h($f['label']) ?></span>
                            <div style="position:relative;display:flex;align-items:center;">
                                <input type="text" id="filter_<?= h($f['name']) ?>" placeholder="Escribe para buscar (ej. Maule, Metropolitana, OH...)" autocomplete="off"
                                       style="width:100%;padding-right:34px;text-transform:none;"
                                       oninput="filterSelect('<?= h($f['name']) ?>')">
                                <button type="button" title="Limpiar filtro"
                                        onclick="clearSelectFilter('<?= h($f['name']) ?>')"
                                        style="position:absolute;right:8px;background:none;border:none;color:#64748b;cursor:pointer;font-size:16px;line-height:1;padding:4px;">×</button>
                            </div>
                            <select name="<?= h($f['name']) ?>" id="select_<?= h($f['name']) ?>" size="6" required
                                    style="width:100%;height:auto;padding:4px;border:1px solid #cbd5e1;border-radius:8px;font-size:13px;font-weight:500;color:#17243b;background:#fff;cursor:pointer;"
                                    onchange="syncFilterInput('<?= h($f['name']) ?>')">
                                <?php foreach ($f['options'] as $opt): ?>
                                    <option value="<?= h($opt) ?>" style="padding:7px 10px;border-radius:4px;"><?= h($opt) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    <?php else: ?>
                        <label><?= h($f['label']) ?>
                            <?php if (($f['type'] ?? '') === 'lookup'): $opts = $lookups[$f['source']] ?? []; ?>
                                <select name="<?= h($f['name']) ?>" required>
                                    <option value="">Seleccionar...</option>
                                    <?php foreach ($opts as $o): ?>
                                        <option value="<?= h($o[$f['value']]) ?>"><?= h($o[$f['display']]) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            <?php else: ?>
                                <input type="<?= h($f['type']) ?>" name="<?= h($f['name']) ?>" style="text-transform:none;" <?= isset($f['pattern']) ? 'pattern="' . h($f['pattern']) . '"' : '' ?> <?= isset($f['title']) ? 'title="' . h($f['title']) . '"' : '' ?> <?= isset($f['min']) ? 'min="' . h($f['min']) . '"' : '' ?> <?= isset($f['max']) ? 'max="' . h($f['max']) . '"' : '' ?> required>
                            <?php endif; ?>
                        </label>
                    <?php endif; ?>
                <?php endforeach; ?>

                <div class="modal-actions">
                    <button type="button" class="btn ghost" onclick="closeModal()">Cancelar</button>
                    <button type="submit" class="btn primary">Guardar registro</button>
                </div>
            </form>
        </div>
    </div>

    <script>
    const formFields = <?= json_encode(array_merge([$m['id']], array_column($m['fields'], 'name'))) ?>;
    const selectCache = {};

    document.querySelectorAll('select[id^="select_"]').forEach(sel => {
        const name = sel.id.replace('select_', '');
        selectCache[name] = Array.from(sel.options).map(o => ({ value: o.value, text: o.textContent }));
    });

    function normText(s) {
        return s.toLowerCase()
                .normalize("NFD")
                .replace(/[\u0300-\u036f]/g, "")
                .replace(/['’\-]/g, "")
                .trim();
    }

    function filterSelect(name) {
        const inp = document.getElementById('filter_' + name);
        const sel = document.getElementById('select_' + name);
        if (!inp || !sel || !selectCache[name]) return;
        const q = normText(inp.value);
        const currentVal = sel.value;
        sel.innerHTML = '';
        selectCache[name].forEach(item => {
            if (q === '' || normText(item.text).includes(q)) {
                const opt = document.createElement('option');
                opt.value = item.value;
                opt.textContent = item.text;
                opt.style.padding = '7px 10px';
                if (item.value === currentVal) opt.selected = true;
                sel.appendChild(opt);
            }
        });
        if (sel.options.length === 1) {
            sel.options[0].selected = true;
        }
    }

    function syncFilterInput(name) {
        const inp = document.getElementById('filter_' + name);
        const sel = document.getElementById('select_' + name);
        if (inp && sel && sel.selectedIndex >= 0) {
            inp.value = sel.options[sel.selectedIndex].text;
        }
    }

    function clearSelectFilter(name) {
        const inp = document.getElementById('filter_' + name);
        const sel = document.getElementById('select_' + name);
        if (inp) {
            inp.value = '';
            filterSelect(name);
            inp.focus();
        }
        if (sel) sel.selectedIndex = -1;
    }

    function openCreate() {
        document.getElementById('recordForm').reset();
        document.getElementById('formOp').value = 'I';
        document.getElementById('recordId').value = '';
        document.getElementById('modalTitle').textContent = 'Nuevo registro';
        Object.keys(selectCache).forEach(name => clearSelectFilter(name));
        let mid = document.getElementById('manualId');
        if (mid) { mid.disabled = false; mid.value = ''; }
        document.getElementById('recordModal').classList.add('show');
    }

    function editRow(r) {
        document.getElementById('recordForm').reset();
        document.getElementById('formOp').value = 'U';
        document.getElementById('recordId').value = r[formFields[0]];
        document.getElementById('modalTitle').textContent = 'Editar registro';
        Object.keys(selectCache).forEach(name => filterSelect(name));
        let mid = document.getElementById('manualId');
        if (mid) { mid.value = r[formFields[0]] ?? ''; mid.disabled = true; }
        formFields.slice(1).forEach(k => {
            let el = document.querySelector('[name="' + k + '"]');
            if (el) {
                el.value = (r[k] ?? '').toString().replace('T', ' ').slice(0, 16);
                if (selectCache[k]) syncFilterInput(k);
            }
        });
        document.getElementById('recordModal').classList.add('show');
    }

    function closeModal() {
        document.getElementById('recordModal').classList.remove('show');
    }
    </script>

<?php } elseif ($page === 'g_viaje') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">PLANIFICACIÓN</span><h3>Programar nuevo viaje</h3><p>Invoca LEHZ_PS_GES_PROGRAMAR_VIAJE.</p>
        <form method="post" class="form-grid">
            <label>Fecha del viaje<input type="date" name="fecha" required></label>
            <label>Horario<select name="horario" required><option value="">Seleccionar...</option><?php foreach ($lookups['horarios'] ?? [] as $r): ?><option value="<?= $r['ID_HORARIO'] ?>">#<?= $r['ID_HORARIO'] ?> · <?= h($r['HORA_SALIDA']) ?></option><?php endforeach; ?></select></label>
            <label>Ruta<select name="ruta" required><option value="">Seleccionar...</option><?php foreach ($lookups['rutas'] ?? [] as $r): ?><option value="<?= $r['ID_RUTA'] ?>">Ruta #<?= $r['ID_RUTA'] ?> · <?= h($r['DISTANCIA']) ?> km</option><?php endforeach; ?></select></label>
            <div class="form-actions"><button class="btn primary">Programar viaje →</button></div>
        </form>
    </section>

<?php } elseif ($page === 'g_venta') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">BOLETERÍA</span><h3>Registrar venta de boleto</h3><p>El procedimiento registra el boleto y su pago en una sola operación.</p>
        <form method="post" class="form-grid">
            <label>Pasajero<select name="pasajero" required><option value="">Seleccionar...</option><?php foreach ($lookups['pasajeros'] ?? [] as $r): ?><option value="<?= $r['RUT_PASAJERO'] ?>"><?= h($r['NOMBRE']) ?> · <?= h($r['RUT_PASAJERO']) ?></option><?php endforeach; ?></select></label>
            <label>Viaje<select name="viaje" required><option value="">Seleccionar...</option><?php foreach ($lookups['viajes'] ?? [] as $r): ?><option value="<?= $r['ID_VIAJE'] ?>">Viaje #<?= $r['ID_VIAJE'] ?> · <?= h($r['FECHA_VIAJE']) ?> (<?= h($r['DISTANCIA'] ?? '') ?> km)</option><?php endforeach; ?></select></label>
            <label>Bus<select name="bus" required><option value="">Seleccionar...</option><?php foreach ($lookups['buses'] ?? [] as $r): ?><option value="<?= h($r['PATENTE_BUS']) ?>"><?= h($r['PATENTE_BUS']) ?> · <?= h($r['MARCA'] . ' ' . $r['MODELO']) ?></option><?php endforeach; ?></select></label>
            <label>Número de asiento<input type="number" name="asiento" min="1" required></label>
            <label>Valor del boleto ($)<input type="number" name="valor" min="1" required></label>
            <label>Método de pago<select name="metodo" required><option value="EFECTIVO">Efectivo</option><option value="TARJETA">Tarjeta</option><option value="TRANSFERENCIA">Transferencia</option></select></label>
            <div class="form-actions"><button class="btn primary">Confirmar venta →</button></div>
        </form>
        <div class="notice">La base de datos valida que el asiento exista y que no esté vendido previamente para el viaje.</div>
    </section>

<?php } elseif ($page === 'g_conduce') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">ASIGNACIÓN OPERACIONAL</span><h3>Asignar conductor, bus y viaje</h3><p>Invoca LEHZ_PS_GES_ASIGNAR_CONDUCE.</p>
        <form method="post" class="form-grid">
            <label>Conductor<select name="conductor" required><option value="">Seleccionar...</option><?php foreach ($lookups['conductores'] ?? [] as $r): ?><option value="<?= $r['RUT_CONDUCTOR'] ?>"><?= h($r['NOMBRE_CONDUCTOR'] . ' ' . $r['APELLIDO1_CONDUCTOR']) ?> · <?= h($r['RUT_CONDUCTOR']) ?></option><?php endforeach; ?></select></label>
            <label>Bus<select name="bus" required><option value="">Seleccionar...</option><?php foreach ($lookups['buses'] ?? [] as $r): ?><option value="<?= h($r['PATENTE_BUS']) ?>"><?= h($r['PATENTE_BUS']) ?> · <?= h($r['MARCA'] . ' ' . $r['MODELO']) ?></option><?php endforeach; ?></select></label>
            <label>Viaje<select name="viaje" required><option value="">Seleccionar...</option><?php foreach ($lookups['viajes'] ?? [] as $r): ?><option value="<?= $r['ID_VIAJE'] ?>">Viaje #<?= $r['ID_VIAJE'] ?> · <?= h($r['FECHA_VIAJE']) ?> (<?= h($r['DISTANCIA'] ?? '') ?> km)</option><?php endforeach; ?></select></label>
            <div class="form-actions"><button class="btn primary">Guardar asignación →</button></div>
        </form>
    </section>

<?php } elseif ($page === 'g_mantencion') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">MANTENCIÓN DE FLOTA</span><h3>Registrar mantención</h3><p>Invoca LEHZ_PS_GES_REGISTRAR_MANTENCION.</p>
        <form method="post" class="form-grid">
            <label>Fecha<input type="date" name="fecha" required></label>
            <label>Mecánico<select name="mecanico" required><option value="">Seleccionar...</option><?php foreach ($lookups['mecanicos'] ?? [] as $r): ?><option value="<?= $r['RUT_MECANICO'] ?>"><?= h($r['NOMBRE_MECANICO'] . ' ' . $r['APELLIDO1_MECANICO']) ?></option><?php endforeach; ?></select></label>
            <label>Bus<select name="bus" required><option value="">Seleccionar...</option><?php foreach ($lookups['buses'] ?? [] as $r): ?><option value="<?= h($r['PATENTE_BUS']) ?>"><?= h($r['PATENTE_BUS']) ?> · <?= h($r['MARCA'] . ' ' . $r['MODELO']) ?></option><?php endforeach; ?></select></label>
            <label>Costo ($)<input type="number" name="costo" min="0" required></label>
            <label class="span-2">Descripción<textarea name="descripcion" rows="3" style="text-transform:none;" required></textarea></label>
            <div class="form-actions"><button class="btn primary">Registrar mantención →</button></div>
        </form>
    </section>

<?php } elseif ($page === 'g_terminal') { ?>
    <section class="panel form-panel">
        <span class="eyebrow">RED DE TERMINALES</span><h3>Asociar terminal a empresa</h3><p>Invoca LEHZ_PS_GES_ASOCIAR_TERMINAL.</p>
        <form method="post" class="form-grid">
            <label>Terminal<select name="terminal" required><option value="">Seleccionar...</option><?php foreach ($lookups['terminales'] ?? [] as $r): ?><option value="<?= $r['ID_TERMINAL'] ?>"><?= h($r['NOMBRE']) ?> · #<?= $r['ID_TERMINAL'] ?></option><?php endforeach; ?></select></label>
            <label>Empresa<select name="empresa" required><option value="">Seleccionar...</option><?php foreach ($lookups['empresas'] ?? [] as $r): ?><option value="<?= h($r['RUT_EMPRESA']) ?>"><?= h($r['RAZON_SOCIAL']) ?></option><?php endforeach; ?></select></label>
            <div class="form-actions"><button class="btn primary">Asociar terminal →</button></div>
        </form>
    </section>

<?php } elseif (str_starts_with($page, 'r_')) {
    $rk   = substr($page, 2);
    $cols = $reportRows ? array_keys($reportRows[0]) : [];
    ?>
    <section class="panel">
        <div class="panel-head">
            <div><span class="eyebrow">ANÁLISIS Y CONTROL</span><h3><?= h($reports[$rk]['title']) ?></h3><p>Datos obtenidos desde <?= h($reports[$rk]['proc']) ?>.</p></div>
            <button class="btn ghost" onclick="window.print()">↧ Imprimir / PDF</button>
        </div>
        <?php if ($reportRows): ?>
            <div class="report-summary">
                <div><span>Registros del reporte</span><b><?= count($reportRows) ?></b></div>
                <?php if ($rk === 'recaudacion'):
                    $sum = array_sum(array_map(fn($r) => (float)($r['RECAUDACION_TOTAL'] ?? 0), $reportRows));
                ?>
                    <div><span>Recaudación acumulada</span><b>$<?= number_format($sum, 0, ',', '.') ?></b></div>
                <?php elseif ($rk === 'mantenciones'):
                    $sum = array_sum(array_map(fn($r) => (float)($r['COSTO_TOTAL_MANTENCIONES'] ?? $r['COSTO_TOTAL_MANTENCION'] ?? 0), $reportRows));
                ?>
                    <div><span>Costo acumulado</span><b>$<?= number_format($sum, 0, ',', '.') ?></b></div>
                <?php endif; ?>
            </div>
            <?php if (in_array($rk, ['recaudacion', 'mantenciones'])): ?>
                <div class="chart-box"><canvas id="reportChart" height="95"></canvas></div>
            <?php endif; ?>
            <div class="table-wrap">
                <table>
                    <thead><tr><?php foreach ($cols as $col): ?><th><?= h(str_replace('_', ' ', $col)) ?></th><?php endforeach; ?></tr></thead>
                    <tbody>
                        <?php foreach ($reportRows as $r): ?>
                            <tr><?php foreach ($cols as $col): ?><td><?= h($r[$col]) ?></td><?php endforeach; ?></tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php else: ?>
            <div class="empty-state"><b>No hay datos para mostrar</b><p>Cuando existan registros operacionales, aparecerán en este reporte.</p></div>
        <?php endif; ?>
    </section>
    <?php if ($reportRows && in_array($rk, ['recaudacion', 'mantenciones'])): ?>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script>
        new Chart(document.getElementById('reportChart'), {
            type: 'bar',
            data: {
                labels: <?= json_encode(array_map(fn($r) => $rk === 'recaudacion' ? 'Viaje ' . $r['ID_VIAJE'] : $r['PATENTE_BUS'], $reportRows)) ?>,
                datasets: [{
                    label: <?= json_encode($rk === 'recaudacion' ? 'Recaudación' : 'Costo de mantenciones') ?>,
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
    <section class="panel"><h3>Módulo no encontrado</h3><a href="?page=dashboard">Volver al panel</a></section>
<?php }
layout_end();