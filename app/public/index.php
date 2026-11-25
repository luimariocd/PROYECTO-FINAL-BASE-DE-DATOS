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

function remember_old(array $post): void {
    unset($post['password'], $post['password_confirm']);
    $_SESSION['old'] = $post;
}

function fail_and_go(Throwable $e, string $url): void {
    remember_old($_POST);
    auth_flash('error', db_error_message($e));
    redirect_to($url);
}

function success_and_go(string $message, string $url): void {
    unset($_SESSION['old']);
    auth_flash('success', $message);
    redirect_to($url);
}

function handle_maintainer(array $meta): string {
    $op = strtoupper(trim((string)($_POST['op'] ?? '')));
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

    if ($meta['title'] === 'Horarios' && in_array($op, ['I', 'U'], true)) {
        $fecha = trim((string)($_POST['FECHA_HORARIO'] ?? ''));
        foreach (['HORA_SALIDA', 'HORA_LLEGADA'] as $hf) {
            $hora = trim((string)($_POST[$hf] ?? ''));
            if ($fecha !== '' && $hora !== '') {
                $_POST[$hf] = $fecha . 'T' . $hora;
            }
        }
    }

    foreach ($meta['fields'] as $field) {
        if ($field['name'] === 'FECHA_HORARIO') {
            continue;
        }
        $binds[$field['param']] = clean_input($field['type'], $_POST[$field['name']] ?? null);
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
if ($page === 'logout') {
    auth_logout();
    redirect_to('?page=login');
}

$action = (string)($_POST['action'] ?? '');

if ($action === 'login') {
    try {
        $user = auth_login((string)($_POST['username'] ?? ''), (string)($_POST['password'] ?? ''));
        unset($_SESSION['old']);
        auth_flash('success', 'Bienvenido, ' . $user['name'] . '.');
        redirect_to('?page=dashboard');
    } catch (Throwable $e) {
        fail_and_go($e, '?page=login');
    }
}

if ($action === 'register') {
    try {
        $out = db_call(
            'BEGIN LEHZ_PS_REGISTRAR_PUBLICO(:p_username, :p_password, :p_password_confirm, :p_nombre_completo, :p_email, :p_estado, :p_mensaje); END;',
            [
                'p_username' => $_POST['username'] ?? null,
                'p_password' => $_POST['password'] ?? null,
                'p_password_confirm' => $_POST['password_confirm'] ?? null,
                'p_nombre_completo' => $_POST['nombre_completo'] ?? null,
                'p_email' => $_POST['email'] ?? null,
                'p_estado' => null,
                'p_mensaje' => null,
            ]
        );
        if (($out['p_estado'] ?? '') === 'OK') {
            success_and_go((string)$out['p_mensaje'], '?page=login');
        }
        remember_old($_POST);
        auth_flash('error', (string)($out['p_mensaje'] ?? 'Oracle no pudo completar el registro.'));
        redirect_to('?page=login&tab=register');
    } catch (Throwable $e) {
        fail_and_go($e, '?page=login&tab=register');
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

    try {
        if ($action === 'maintainer') {
            $module = (string)($_POST['module'] ?? '');
            if (!isset($maintainers[$module])) {
                throw new RuntimeException('Modulo de mantenedor no reconocido.');
            }
            success_and_go(handle_maintainer($maintainers[$module]), $target);
        }

        if ($action === 'sale') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_VENDER_BOLETO(:p_rut_pasajero, :p_id_viaje, :p_numero_asiento, :p_patente_bus, :p_metodo_pago, :p_id_terminal_bajada, :p_id_boleto_out); END;',
                [
                    'p_rut_pasajero' => $_POST['rut_pasajero'] ?? null,
                    'p_id_viaje' => $_POST['id_viaje'] ?? null,
                    'p_numero_asiento' => $_POST['numero_asiento'] ?? null,
                    'p_patente_bus' => $_POST['patente_bus'] ?? null,
                    'p_metodo_pago' => $_POST['metodo_pago'] ?? null,
                    'p_id_terminal_bajada' => ($_POST['id_terminal_bajada'] ?? '') !== '' ? $_POST['id_terminal_bajada'] : null,
                    'p_id_boleto_out' => null,
                ]
            );
            $id = $out['p_id_boleto_out'] ?? null;
            $valor = db_scalar('SELECT VALOR_BOLETO FROM LEHZ_BOLETO WHERE ID_BOLETO = :p_id', ['p_id' => $id]);
            success_and_go('Boleto #' . $id . ' emitido. Tarifa calculada por Oracle: $' . number_format((float)$valor, 0, ',', '.') . '.', $target);
        }

        if ($action === 'annul') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_ANULAR_BOLETO(:p_id_boleto, :p_motivo, :p_estado_out); END;',
                [
                    'p_id_boleto' => $_POST['id_boleto'] ?? null,
                    'p_motivo' => $_POST['motivo'] ?? null,
                    'p_estado_out' => null,
                ]
            );
            success_and_go('Boleto anulado. Estado informado por Oracle: ' . ($out['p_estado_out'] ?? ''), $target);
        }

        if ($action === 'use') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_MARCAR_BOLETO_USADO(:p_id_boleto, :p_estado_out); END;',
                ['p_id_boleto' => $_POST['id_boleto'] ?? null, 'p_estado_out' => null]
            );
            success_and_go('Boleto marcado como usado. Estado: ' . ($out['p_estado_out'] ?? ''), $target);
        }

        if ($action === 'bajada') {
            db_call(
                'BEGIN LEHZ_PS_GES_REGISTRAR_BAJADA(:p_id_boleto, :p_id_terminal_bajada, :p_observacion); END;',
                [
                    'p_id_boleto' => $_POST['id_boleto'] ?? null,
                    'p_id_terminal_bajada' => $_POST['id_terminal_bajada'] ?? null,
                    'p_observacion' => $_POST['observacion'] ?? null,
                ]
            );
            success_and_go('Bajada registrada correctamente.', $target);
        }

        if ($action === 'viaje') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_PROGRAMAR_VIAJE(TO_DATE(:p_fecha_viaje, \'YYYY-MM-DD\'), :p_id_horario, :p_id_ruta, :p_id_viaje_out); END;',
                [
                    'p_fecha_viaje' => $_POST['fecha_viaje'] ?? null,
                    'p_id_horario' => $_POST['id_horario'] ?? null,
                    'p_id_ruta' => $_POST['id_ruta'] ?? null,
                    'p_id_viaje_out' => null,
                ]
            );
            success_and_go('Viaje programado con ID ' . ($out['p_id_viaje_out'] ?? '') . '.', $target);
        }

        if ($action === 'conduce' || $action === 'conduce_delete') {
            db_call(
                'BEGIN LEHZ_PS_GES_ASIGNAR_CONDUCE(:p_rut_conductor, :p_patente_bus, :p_id_viaje, :p_opcion); END;',
                [
                    'p_rut_conductor' => $_POST['rut_conductor'] ?? null,
                    'p_patente_bus' => $_POST['patente_bus'] ?? null,
                    'p_id_viaje' => $_POST['id_viaje'] ?? null,
                    'p_opcion' => $action === 'conduce' ? 'I' : 'D',
                ]
            );
            success_and_go($action === 'conduce' ? 'Asignacion registrada.' : 'Asignacion eliminada.', $target);
        }

        if ($action === 'mantencion') {
            $out = db_call(
                'BEGIN LEHZ_PS_GES_REGISTRAR_MANTENCION(TO_DATE(:p_fecha, \'YYYY-MM-DD\'), :p_descripcion, :p_costo, :p_rut_mecanico, :p_patente_bus, :p_id_mant_out); END;',
                [
                    'p_fecha' => $_POST['fecha'] ?? null,
                    'p_descripcion' => $_POST['descripcion'] ?? null,
                    'p_costo' => $_POST['costo'] ?? null,
                    'p_rut_mecanico' => $_POST['rut_mecanico'] ?? null,
                    'p_patente_bus' => $_POST['patente_bus'] ?? null,
                    'p_id_mant_out' => null,
                ]
            );
            success_and_go('Mantencion registrada con ID ' . ($out['p_id_mant_out'] ?? '') . '.', $target);
        }

        if ($action === 'utilizan' || $action === 'utilizan_delete') {
            db_call(
                'BEGIN LEHZ_PS_GES_ASOCIAR_TERMINAL(:p_id_terminal, :p_rut_empresa, :p_opcion); END;',
                [
                    'p_id_terminal' => $_POST['id_terminal'] ?? null,
                    'p_rut_empresa' => $_POST['rut_empresa'] ?? null,
                    'p_opcion' => $action === 'utilizan' ? 'I' : 'D',
                ]
            );
            success_and_go($action === 'utilizan' ? 'Terminal asociado a la empresa.' : 'Asociacion eliminada.', $target);
        }

        if ($action === 'user_create') {
            $out = db_call(
                'BEGIN LEHZ_PS_CREAR_USUARIO_ADMIN(:p_username, :p_password, :p_password_confirm, :p_nombre_completo, :p_email, :p_rol, :p_estado, :p_mensaje); END;',
                [
                    'p_username' => $_POST['username'] ?? null,
                    'p_password' => $_POST['password'] ?? null,
                    'p_password_confirm' => $_POST['password_confirm'] ?? null,
                    'p_nombre_completo' => $_POST['nombre_completo'] ?? null,
                    'p_email' => $_POST['email'] ?? null,
                    'p_rol' => $_POST['rol'] ?? null,
                    'p_estado' => null,
                    'p_mensaje' => null,
                ]
            );
            if (($out['p_estado'] ?? '') === 'OK') {
                success_and_go((string)$out['p_mensaje'], $target);
            }
            remember_old($_POST);
            auth_flash('error', (string)($out['p_mensaje'] ?? 'Oracle no pudo crear el usuario.'));
            redirect_to($target);
        }

        if ($action === 'user_state') {
            db_call(
                'BEGIN LEHZ_PS_CAMBIAR_ESTADO_USUARIO(:p_id_usuario, :p_estado); END;',
                ['p_id_usuario' => $_POST['id_usuario'] ?? null, 'p_estado' => $_POST['estado'] ?? null]
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
    clear_old();
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
    clear_old();
    exit;
}

if (isset($reports[$page])) {
    $report = $reports[$page];
    $title = $report['title'];
    layout_start($title, $page);
    require __DIR__ . '/../views/report.php';
    layout_end();
    clear_old();
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
clear_old();
