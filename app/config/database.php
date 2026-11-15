<?php
function db(): mixed {
    static $conn = null;
    if ($conn) return $conn;
    if (!function_exists('oci_connect')) {
        throw new RuntimeException('La extensión OCI8 no está instalada o habilitada en PHP. Revisa INSTALACION_PHP_ORACLE.md.');
    }
    $cfg = require __DIR__ . '/config.php';
    $dsn = "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST={$cfg['host']})(PORT={$cfg['port']}))(CONNECT_DATA=(SERVICE_NAME={$cfg['service']})))";
    $conn = @oci_connect($cfg['user'], $cfg['password'], $dsn, $cfg['charset']);
    if (!$conn) { $e = oci_error(); throw new RuntimeException('No fue posible conectar con Oracle: ' . ($e['message'] ?? 'error desconocido')); }
    return $conn;
}
function db_rows(string $procedure): array {
    $c=db(); $cur=oci_new_cursor($c); $st=oci_parse($c, "BEGIN {$procedure}(:p_cursor); END;");
    oci_bind_by_name($st, ':p_cursor', $cur, -1, OCI_B_CURSOR);
    if (!oci_execute($st) || !oci_execute($cur)) { $e=oci_error($st); throw new RuntimeException($e['message'] ?? 'Error al consultar.'); }
    $rows=[]; while(($r=oci_fetch_assoc($cur))!==false) $rows[]=$r;
    oci_free_statement($cur); oci_free_statement($st); return $rows;
}
function db_call(string $plsql, array $values): array {
    $c=db(); $st=oci_parse($c,$plsql); $vars=[];
    foreach($values as $name=>$value) { $vars[$name]=$value; oci_bind_by_name($st, ':'.$name, $vars[$name], is_string($vars[$name]) ? max(4000,strlen($vars[$name])+1) : -1); }
    if(!@oci_execute($st, OCI_COMMIT_ON_SUCCESS)) { $e=oci_error($st); oci_free_statement($st); throw new RuntimeException($e['message'] ?? 'Error al ejecutar procedimiento.'); }
    oci_free_statement($st); return $vars;
}
function db_cursor_call(string $procedure): array { return db_rows($procedure); }
