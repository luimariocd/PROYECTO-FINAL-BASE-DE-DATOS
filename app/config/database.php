<?php

function db(): mixed {
    static $conn = null;
    if ($conn) return $conn;
    if (!function_exists('oci_connect')) {
        throw new RuntimeException('La extensión OCI8 no está instalada o habilitada en PHP.');
    }
    $cfg = require __DIR__ . '/config.php';
    $dsn = "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST={$cfg['host']})(PORT={$cfg['port']}))(CONNECT_DATA=(SERVICE_NAME={$cfg['service']})))";
    $conn = @oci_connect($cfg['user'], $cfg['password'], $dsn, $cfg['charset']);
    if (!$conn) {
        $e = oci_error();
        throw new RuntimeException('No fue posible conectar con Oracle: ' . ($e['message'] ?? 'error desconocido'));
    }
    return $conn;
}

function db_bind_values($statement, array $values): array {
    $vars = [];
    foreach ($values as $name => $value) {
        $vars[$name] = $value;
        $length = (is_string($vars[$name]) || $vars[$name] === null)
            ? max(4000, strlen((string)$vars[$name]) + 1)
            : -1;
        oci_bind_by_name($statement, ':' . $name, $vars[$name], $length);
    }
    return $vars;
}

/**
 * Ejecuta un bloque PL/SQL que recibe parámetros y devuelve un cursor
 * en el parámetro :p_cursor. Toda la lógica vive en Oracle.
 */
function db_cursor(string $plsql, array $values = []): array {
    $c   = db();
    $cur = oci_new_cursor($c);
    $st  = oci_parse($c, $plsql);
    db_bind_values($st, $values);
    oci_bind_by_name($st, ':p_cursor', $cur, -1, OCI_B_CURSOR);

    if (!@oci_execute($st)) {
        $e = oci_error($st);
        oci_free_statement($st);
        throw new RuntimeException($e['message'] ?? 'Error al ejecutar la consulta.');
    }
    if (!@oci_execute($cur)) {
        $e = oci_error($cur);
        oci_free_statement($cur);
        oci_free_statement($st);
        throw new RuntimeException($e['message'] ?? 'Error al leer el cursor.');
    }

    $rows = [];
    while (($r = oci_fetch_assoc($cur)) !== false) {
        $rows[] = $r;
    }
    oci_free_statement($cur);
    oci_free_statement($st);
    return $rows;
}

/**
 * Ejecuta un procedimiento que solo recibe el cursor de salida.
 */
function db_rows(string $procedure): array {
    return db_cursor("BEGIN {$procedure}(:p_cursor); END;");
}

/**
 * Ejecuta un bloque PL/SQL con parámetros de entrada/salida.
 */
function db_call(string $plsql, array $values): array {
    $c   = db();
    $st  = oci_parse($c, $plsql);
    $vars = db_bind_values($st, $values);

    if (!@oci_execute($st, OCI_COMMIT_ON_SUCCESS)) {
        $e = oci_error($st);
        oci_free_statement($st);
        throw new RuntimeException($e['message'] ?? 'Error al ejecutar el procedimiento.');
    }

    oci_free_statement($st);
    return $vars;
}
