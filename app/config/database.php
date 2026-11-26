<?php
// Esta parte del código se encarga de abrir y reutilizar la conexion con Oracle.

function db(): mixed {
    static $conn = null;
    if ($conn) {
        return $conn;
    }
    if (!function_exists('oci_connect')) {
        throw new RuntimeException('La extension OCI8 no esta instalada o habilitada en PHP.');
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

function db_bind_value($st, string $name, &$value): void {
    $len = is_string($value) ? max(4000, strlen($value) + 1) : 4000;
    oci_bind_by_name($st, ':' . $name, $value, $len);
}

// Esta parte del código se encarga de invocar un procedimiento y leer su SYS_REFCURSOR.
function db_rows(string $procedure, array $inputs = []): array {
    $c = db();
    $cur = oci_new_cursor($c);
    $args = [];
    $vars = [];
    foreach ($inputs as $name => $value) {
        $args[] = ':' . $name;
        $vars[$name] = $value;
    }
    $args[] = ':p_cursor';
    $sql = 'BEGIN ' . $procedure . '(' . implode(',', $args) . '); END;';
    $st = oci_parse($c, $sql);
    if (!$st) {
        $e = oci_error($c);
        throw new RuntimeException($e['message'] ?? 'No fue posible preparar la consulta.');
    }
    foreach ($vars as $name => &$value) {
        db_bind_value($st, $name, $value);
    }
    unset($value);
    oci_bind_by_name($st, ':p_cursor', $cur, -1, OCI_B_CURSOR);
    if (!@oci_execute($st) || !@oci_execute($cur)) {
        $e = oci_error($st);
        oci_free_statement($cur);
        oci_free_statement($st);
        throw new RuntimeException($e['message'] ?? 'Error al consultar Oracle.');
    }
    $rows = [];
    while (($r = oci_fetch_assoc($cur)) !== false) {
        $rows[] = $r;
    }
    oci_free_statement($cur);
    oci_free_statement($st);
    return $rows;
}

// Esta parte del código se encarga de ejecutar un bloque PL/SQL y recoger sus parametros OUT.
function db_call(string $plsql, array $values): array {
    $c = db();
    $st = oci_parse($c, $plsql);
    if (!$st) {
        $e = oci_error($c);
        throw new RuntimeException($e['message'] ?? 'No fue posible preparar la operacion.');
    }
    $vars = [];
    foreach ($values as $name => $value) {
        $vars[$name] = $value;
    }
    foreach ($vars as $name => &$value) {
        db_bind_value($st, $name, $value);
    }
    unset($value);
    if (!@oci_execute($st, OCI_COMMIT_ON_SUCCESS)) {
        $e = oci_error($st);
        oci_free_statement($st);
        throw new RuntimeException($e['message'] ?? 'Error al ejecutar el procedimiento.');
    }
    oci_free_statement($st);
    return $vars;
}

// Esta parte del código se encarga de consultar vistas ya formateadas en Oracle.
function db_query(string $sql, array $binds = []): array {
    $c = db();
    $st = oci_parse($c, $sql);
    if (!$st) {
        $e = oci_error($c);
        throw new RuntimeException($e['message'] ?? 'No fue posible preparar la consulta.');
    }
    $vars = [];
    foreach ($binds as $name => $value) {
        $vars[$name] = $value;
    }
    foreach ($vars as $name => &$value) {
        db_bind_value($st, $name, $value);
    }
    unset($value);
    if (!@oci_execute($st)) {
        $e = oci_error($st);
        oci_free_statement($st);
        throw new RuntimeException($e['message'] ?? 'Error al consultar Oracle.');
    }
    $rows = [];
    while (($r = oci_fetch_assoc($st)) !== false) {
        $rows[] = $r;
    }
    oci_free_statement($st);
    return $rows;
}

function db_scalar(string $sql, array $binds = []): mixed {
    $rows = db_query($sql, $binds);
    if (!$rows) {
        return null;
    }
    $values = array_values($rows[0]);
    return $values[0] ?? null;
}

// Esta parte del código se encarga de convertir errores ORA-20xxx en mensajes de negocio.
function db_error_message(Throwable $e): string {
    $msg = $e->getMessage();
    if (preg_match('/ORA-20\d{3}:\s*(.+?)(?:\s*ORA-|\s*Help:|$)/s', $msg, $m)) {
        return trim($m[1]);
    }
    if (preg_match('/ORA-(\d{5}):\s*(.+?)(?:\s*ORA-|\s*Help:|$)/s', $msg, $m)) {
        return 'Oracle ORA-' . $m[1] . ': ' . trim($m[2]);
    }
    return $msg;
}
