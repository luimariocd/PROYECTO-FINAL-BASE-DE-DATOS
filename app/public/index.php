<?php
session_start();
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/helpers.php';
require_once __DIR__ . '/../auth/auth.php';
require_once __DIR__ . '/../views/layout.php';

$config = require __DIR__ . '/../config/modules.php';
$GLOBALS['LEHZ_LOOKUPS'] = $config['lookups'];
$maintainers = $config['maintainers'];
$reports = $config['reports'];

function redirect_to(string $url): void {
    header('Location: ' . $url);
    exit;
}

function scope_from_url(string $url): string {
    parse_str((string)parse_url($url, PHP_URL_QUERY), $query);
    return (string)($query['page'] ?? 'dashboard');
}

function remember_old(array $post, string $scope): void {
    unset($post['password'], $post['password_confirm']);
    $_SESSION['old'] = ['scope' => $scope, 'data' => $post];
}

function reject_errors(array $errors, string $url): void {
    if (!$errors) {
        return;
    }
    remember_old($_POST, scope_from_url($url));
    auth_flash('error', implode(' ', $errors));
    redirect_to($url);
}

function post_value(string $name) {
    return clean_input('text', $_POST[$name] ?? null);
}

function fail_and_go(Throwable $e, string $url): void {
    remember_old($_POST, scope_from_url($url));
    auth_flash('error', db_error_message($e));
    redirect_to($url);
}

function success_and_go(string $message, string $url): void {
    clear_old(scope_from_url($url));
    auth_flash('success', $message);
    redirect_to($url);
}

function handle_maintainer(array $meta): string {
    $op = strtoupper(trim((string)($_POST['op'] ?? '')));
    if (!in_array($op, ['I', 'U', 'D'], true)) {
        throw new RuntimeException('Operacion no reconocida.');
    }
    $args = [':p_opcion'];
    $binds = ['p_opcion' => $op];

    foreach ($meta['id'] as $id) {
        $name = $id['name'];
        if (!empty($id['auto'])) {
            $value = $op === 'I' ? null : ($_POST['original_' . $name] ?? null);
        } else {
            $value = $op === 'I' ? ($_POST[$name] ?? null) : ($_POST['original_' . $name] ?? null);
        }
        $binds[$id['param']] = clean_input($id['type'] ?? 'text', $value);
        $args[] = $id['param'] . ' => :' . $id['param'];
    }

    $timeValues = [];
    if ($meta['title'] === 'Horarios' && in_array($op, ['I', 'U'], true)) {
        $fecha = trim((string)($_POST['FECHA_HORARIO'] ?? ''));
        foreach (['HORA_SALIDA', 'HORA_LLEGADA'] as $hf) {
            $hora = trim((string)($_POST[$hf] ?? ''));
            if ($fecha !== '' && $hora !== '') {
                $timeValues[$hf] = $fecha . 'T' . $hora;
            }
        }
    }

    $errors = maintainer_validation_errors($meta, $op, $_POST, $timeValues);
    if ($errors) {
        throw new RuntimeException(implode(' ', $errors));
    }

    foreach ($meta['fields'] as $field) {
        if ($field['name'] === 'FECHA_HORARIO') {
            continue;
        }
        $raw = $timeValues[$field['name']] ?? ($_POST[$field['name']] ?? null);
        $binds[$field['param']] = clean_input($field['type'], $raw);
        $args[] = $field['param'] . ' => ' . bind_expression($field['param'], $field['type'], $field['domain'] ?? '');
    }

    $plsql = 'BEGIN ' . $meta['proc'] . '(' . implode(', ', $args) . '); END;';
    $out = db_call($plsql, $binds);

    $labels = [];
    foreach ($meta['id'] as $id) {
        if (!empty($id['auto'])) {
            $labels[] = column_label($id['name']) . ' ' . ($out[$id['param']] ?? '');
        } else {
            $labels[] = column_label($id['name']) . ' ' . ($binds[$id['param']] ?? '');
        }
    }
    $action = $op === 'I' ? 'creado' : ($op === 'U' ? 'actualizado' : 'eliminado');
    return $meta['title'] . ': registro ' . $action . ' (' . implode(', ', $labels) . ').';
}

$page = (string)($_GET['page'] ?? '');
if ($page === '') {
    $page = auth_user() ? 'dashboard' : 'login';
}
$GLOBALS['LEHZ_OLD_SCOPE'] = $page;
if ($page === 'logout') {
    auth_logout();
    redirect_to('?page=login');
}

$action = (string)($_POST['action'] ?? '');

if ($action === 'login') {
    try {
        $user = auth_login((string)($_POST['username'] ?? ''), (string)($_POST['password'] ?? ''));
        clear_old('login');
        auth_flash('success', 'Bienvenido, ' . $user['name'] . '.');
        redirect_to('?page=dashboard');
    } catch (Throwable $e) {
        fail_and_go($e, '?page=login');
    }
}

if ($action !== '') {
    if (!auth_user()) {
        redirect_to('?page=login');
    }

    $target = '?page=dashboard';
    if ($action === 'maintainer') {
        $module = (string)($_POST['module'] ?? '');
        if (isset($maintainers[$module])) {
            $target = '?page=' . $module;
        }
    } elseif (in_array($action, ['sale', 'annul', 'use'], true)) {
        $target = '?page=venta';
    } elseif ($action === 'bajada') {
        $target = '?page=bajada';
    } elseif ($action === 'viaje') {
        $target = '?page=viaje';
    } elseif (in_array($action, ['conduce', 'conduce_delete'], true)) {
        $target = '?page=conduce';
    } elseif ($action === 'mantencion') {
        $target = '?page=mantencion';
    } elseif (in_array($action, ['utilizan', 'utilizan_delete'], true)) {
        $target = '?page=utilizan';
    } elseif (in_array($action, ['user_create', 'user_state'], true)) {
        $target = '?page=usuarios';
    }

    if (!can_access_action($action, (string)($_POST['module'] ?? ''))) {
        auth_flash('error', 'Tu rol no tiene permisos para esta accion.');
        redirect_to($target);
    }

    if ($action === 'maintainer') {
        if (!isset($maintainers[(string)($_POST['module'] ?? '')])) {
            reject_errors(['Modulo de mantenedor no reconocido.'], $target);
        }
    } else {
        reject_errors(action_validation_errors($action, $_POST), $target);
    }

    try {
        if ($action === 'maintainer') {
            $module = (string)($_POST['module'] ?? '');
            if (!isset($maintainers[$module])) {
                throw new RuntimeException('Modulo de mantenedor no reconocido.');
            }
            success_and_go(handle_maintainer($maintainers[$module]), $target);
        }

        if ($action === 'sale') {
            $bajada = post_value('id_terminal_bajada');
            $out = db_call(
                'BEGIN LEHZ_PS_GES_VENDER_BOLETO(:p_rut_pasajero, :p_id_viaje, :p_numero_asiento, :p_patente_bus, :p_metodo_pago, :p_id_terminal_bajada, :p_id_boleto_out); END;',
                [
                    'p_rut_pasajero' => post_value('rut_pasajero'),
                    'p_id_viaje' => post_value('id_viaje'),
                    'p_numero_asiento' => post_value('numero_asiento'),
                    'p_patente_bus' => post_value('patente_bus'),
                    'p_metodo_pago' => post_value('metodo_pago'),
                    'p_id_terminal_bajada' => $bajada !== '' ? $bajada : null,
                    'p_id_boleto_out' => null,
                ]
            );
            $id = $out['p_id_boleto_out'] ?? null;
            // Esta parte del código se encarga de usar la vista de boletos ya disponible en Oracle.
            $outValor = db_call(
                'BEGIN LEHZ_PS_OBTENER_VALOR_BOLETO(:p_id_boleto, :p_valor); END;',
                ['p_id_boleto' => $id, 'p_valor' => null]
            );
            $valor = $outValor['p_valor'] ?? 0;
            success_and_go('Boleto #' . $id . ' emitido. Tarifa calculada por Oracle: $' . number_format((float)$valor, 0, ',', '.') . '.', $target);
        }

        if ($action === 'annul') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_ANULAR_BOLETO(:p_id_boleto, :p_motivo, :p_estado_out); END;',
                [
                    'p_id_boleto' => post_value('id_boleto'),
                    'p_motivo' => post_value('motivo'),
                    'p_estado_out' => null,
                ]
            );
            success_and_go('Boleto anulado. Estado informado por Oracle: ' . ($out['p_estado_out'] ?? ''), $target);
        }

        if ($action === 'use') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_MARCAR_BOLETO_USADO(:p_id_boleto, :p_estado_out); END;',
                ['p_id_boleto' => post_value('id_boleto'), 'p_estado_out' => null]
            );
            success_and_go('Boleto marcado como usado. Estado: ' . ($out['p_estado_out'] ?? ''), $target);
        }

        if ($action === 'bajada') {
            db_call(
                'BEGIN LEHZ_PS_GES_REGISTRAR_BAJADA(:p_id_boleto, :p_id_terminal_bajada, :p_observacion); END;',
                [
                    'p_id_boleto' => post_value('id_boleto'),
                    'p_id_terminal_bajada' => post_value('id_terminal_bajada'),
                    'p_observacion' => post_value('observacion'),
                ]
            );
            success_and_go('Bajada registrada correctamente.', $target);
        }

        if ($action === 'viaje') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_PROGRAMAR_VIAJE(TO_DATE(:p_fecha_viaje, \'YYYY-MM-DD\'), :p_id_horario, :p_id_ruta, :p_id_viaje_out); END;',
                [
                    'p_fecha_viaje' => post_value('fecha_viaje'),
                    'p_id_horario' => post_value('id_horario'),
                    'p_id_ruta' => post_value('id_ruta'),
                    'p_id_viaje_out' => null,
                ]
            );
            success_and_go('Viaje programado con ID ' . ($out['p_id_viaje_out'] ?? '') . '.', $target);
        }

        if ($action === 'conduce' || $action === 'conduce_delete') {
            db_call(
                'BEGIN LEHZ_PS_GES_ASIGNAR_CONDUCE(:p_rut_conductor, :p_patente_bus, :p_id_viaje, :p_opcion); END;',
                [
                    'p_rut_conductor' => post_value('rut_conductor'),
                    'p_patente_bus' => post_value('patente_bus'),
                    'p_id_viaje' => post_value('id_viaje'),
                    'p_opcion' => $action === 'conduce' ? 'I' : 'D',
                ]
            );
            success_and_go($action === 'conduce' ? 'Asignacion registrada.' : 'Asignacion eliminada.', $target);
        }

        if ($action === 'mantencion') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_REGISTRAR_MANTENCION(TO_DATE(:p_fecha, \'YYYY-MM-DD\'), :p_descripcion, :p_costo, :p_rut_mecanico, :p_patente_bus, :p_id_mant_out); END;',
                [
                    'p_fecha' => post_value('fecha'),
                    'p_descripcion' => post_value('descripcion'),
                    'p_costo' => post_value('costo'),
                    'p_rut_mecanico' => post_value('rut_mecanico'),
                    'p_patente_bus' => post_value('patente_bus'),
                    'p_id_mant_out' => null,
                ]
            );
            success_and_go('Mantencion registrada con ID ' . ($out['p_id_mant_out'] ?? '') . '.', $target);
        }

        if ($action === 'utilizan' || $action === 'utilizan_delete') {
            db_call(
                'BEGIN LEHZ_PS_GES_ASOCIAR_TERMINAL(:p_id_terminal, :p_rut_empresa, :p_opcion); END;',
                [
                    'p_id_terminal' => post_value('id_terminal'),
                    'p_rut_empresa' => post_value('rut_empresa'),
                    'p_opcion' => $action === 'utilizan' ? 'I' : 'D',
                ]
            );
            success_and_go($action === 'utilizan' ? 'Terminal asociado a la empresa.' : 'Asociacion eliminada.', $target);
        }

        if ($action === 'user_create') {
            $out = db_call(
                'BEGIN LEHZ_PS_CREAR_USUARIO_ADMIN(:p_username, :p_password, :p_password_confirm, :p_nombre_completo, :p_email, :p_rol, :p_estado, :p_mensaje); END;',
                [
                    'p_username' => post_value('username'),
                    'p_password' => post_value('password'),
                    'p_password_confirm' => post_value('password_confirm'),
                    'p_nombre_completo' => post_value('nombre_completo'),
                    'p_email' => post_value('email'),
                    'p_rol' => post_value('rol'),
                    'p_estado' => null,
                    'p_mensaje' => null,
                ]
            );
            if (($out['p_estado'] ?? '') === 'OK') {
                success_and_go((string)$out['p_mensaje'], $target);
            }
            remember_old($_POST, scope_from_url($target));
            auth_flash('error', (string)($out['p_mensaje'] ?? 'Oracle no pudo crear el usuario.'));
            redirect_to($target);
        }

        if ($action === 'user_state') {
            db_call(
                'BEGIN LEHZ_PS_CAMBIAR_ESTADO_USUARIO(:p_id_usuario, :p_estado); END;',
                ['p_id_usuario' => post_value('id_usuario'), 'p_estado' => post_value('estado')]
            );
            success_and_go('Estado de usuario actualizado por Oracle.', $target);
        }

        throw new RuntimeException('Accion no reconocida.');
    } catch (Throwable $e) {
        fail_and_go($e, $target);
    }
}

if ($page === 'login') {
    require __DIR__ . '/../views/login.php';
    clear_old('login');
    exit;
}

require_login();

if (!can_access($page)) {
    auth_flash('error', 'Tu rol no tiene permisos para este modulo.');
    redirect_to('?page=dashboard');
}

if (isset($maintainers[$page])) {
    $key = $page;
    $meta = $maintainers[$page];
    $title = $meta['title'];
    layout_start($title, $page);
    require __DIR__ . '/../views/maintainer.php';
    layout_end();
    clear_old($page);
    exit;
}

if (isset($reports[$page])) {
    $report = $reports[$page];
    $title = $report['title'];
    layout_start($title, $page);
    require __DIR__ . '/../views/report.php';
    layout_end();
    clear_old($page);
    exit;
}

$titles = [
    'dashboard' => 'Panel principal',
    'venta' => 'Venta de boletos',
    'bajada' => 'Registrar bajada',
    'viaje' => 'Programar viaje',
    'conduce' => 'Asignar conductor y bus',
    'mantencion' => 'Mantenciones',
    'utilizan' => 'Terminales por empresa',
    'usuarios' => 'Usuarios del sistema',
];
$views = [
    'dashboard' => 'dashboard.php',
    'venta' => 'venta.php',
    'bajada' => 'bajada.php',
    'viaje' => 'viaje.php',
    'conduce' => 'conduce.php',
    'mantencion' => 'mantencion.php',
    'utilizan' => 'utilizan.php',
    'usuarios' => 'usuarios.php',
];

if (!isset($views[$page])) {
    auth_flash('error', 'Modulo no encontrado.');
    redirect_to('?page=dashboard');
}

layout_start($titles[$page] ?? $page, $page);
require __DIR__ . '/../views/' . $views[$page];
layout_end();
clear_old($page);
