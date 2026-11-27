<?php
// ============================================================================
// CONFIGURACIÓN DE CONEXIÓN A BASE DE DATOS ORACLE (OCI8)
// Asignatura: INF324 - Base de Datos
// ============================================================================

// MODALIDAD DE TRABAJO:
// true  = Modo Demostración (Usa datos simulados para ver la interfaz sin haber corrido los SQL)
// false = Modo Real (Se conecta a Oracle Database y ejecuta los Procedimientos Almacenados reales)
define('MODO_DEMO', false);

// Parámetros de conexión a Oracle
define('DB_USER', 'PROYECTO_BD');     // Usuario de Oracle
define('DB_PASS', 'oracle');          // Contraseña del usuario Oracle
define('DB_HOST', 'localhost');       // Host (o IP donde corre Oracle)
define('DB_PORT', '1521');            // Puerto por defecto de Oracle
define('DB_SERVICE', 'XEPDB1');       // Nombre del servicio/PDB (XEPDB1 o XE)
define('DB_CHARSET', 'AL32UTF8');

// Cadena de conexión TNS
define('DB_CONNECTION_STRING', '//' . DB_HOST . ':' . DB_PORT . '/' . DB_SERVICE);

/**
 * Obtiene la conexión activa a Oracle
 */
function get_oracle_connection() {
    if (MODO_DEMO) {
        return null; // En modo demo no se requiere conexión activa
    }

    static $conn = null;
    if ($conn !== null) {
        return $conn;
    }

    if (!function_exists('oci_connect')) {
        die('Error: La extensión oci8 no está habilitada en PHP.');
    }

    $conn = @oci_connect(DB_USER, DB_PASS, DB_CONNECTION_STRING, DB_CHARSET);
    if (!$conn) {
        $e = oci_error();
        die('Error de conexión a Oracle: ' . htmlspecialchars($e['message']));
    }

    return $conn;
}

/**
 * Consulta un Procedimiento Almacenado que retorna un SYS_REFCURSOR
 */
function consultar_cursor($procedure_call, $params_in = []) {
    // Si estamos en Modo Demo, devolver datos simulados
    if (MODO_DEMO) {
        return obtener_datos_demo_cursor($procedure_call);
    }

    $conn = get_oracle_connection();
    $stmt = oci_parse($conn, $procedure_call);
    
    $cursor = oci_new_cursor($conn);
    oci_bind_by_name($stmt, ':p_cursor', $cursor, -1, OCI_B_CURSOR);

    $res_out = '';
    if (strpos($procedure_call, ':res') !== false) {
        oci_bind_by_name($stmt, ':res', $res_out, 300);
    }

    foreach ($params_in as $name => $value) {
        oci_bind_by_name($stmt, $name, $params_in[$name]);
    }

    if (!@oci_execute($stmt)) {
        $err = oci_error($stmt);
        oci_free_statement($stmt);
        throw new Exception('Error al ejecutar Procedimiento Almacenado: ' . $err['message']);
    }

    oci_execute($cursor);

    $resultados = [];
    while ($row = oci_fetch_array($cursor, OCI_ASSOC + OCI_RETURN_NULLS)) {
        $resultados[] = array_change_key_case($row, CASE_LOWER);
    }

    oci_free_statement($stmt);
    oci_free_statement($cursor);

    return $resultados;
}

/**
 * Datos simulados para previsualizar las vistas sin haber cargado la base de datos
 */
function obtener_datos_demo_cursor($procedure_call) {
    if (strpos($procedure_call, 'pr_la_mantenedor_productos') !== false) {
        return [
            ['id_producto' => 1, 'codigo_barra' => '78010001', 'nombre_producto' => 'Leche Entera 1L Colun', 'nombre_categoria' => 'Lácteos y Huevos', 'precio_venta' => 1150, 'stock_actual' => 45, 'stock_minimo' => 10, 'estado' => 'A'],
            ['id_producto' => 2, 'codigo_barra' => '78010002', 'nombre_producto' => 'Queso Gauda Laminado 250g', 'nombre_categoria' => 'Lácteos y Huevos', 'precio_venta' => 2490, 'stock_actual' => 30, 'stock_minimo' => 8, 'estado' => 'A'],
            ['id_producto' => 3, 'codigo_barra' => '78020001', 'nombre_producto' => 'Bebida Coca Cola Original 2.5L', 'nombre_categoria' => 'Bebidas y Licores', 'precio_venta' => 2790, 'stock_actual' => 60, 'stock_minimo' => 15, 'estado' => 'A'],
            ['id_producto' => 4, 'codigo_barra' => '78020002', 'nombre_producto' => 'Jugo Néctar Andina Durazno 1.5L', 'nombre_categoria' => 'Bebidas y Licores', 'precio_venta' => 1450, 'stock_actual' => 25, 'stock_minimo' => 10, 'estado' => 'A'],
            ['id_producto' => 5, 'codigo_barra' => '78030001', 'nombre_producto' => 'Arroz Grado 1 Tucapel 1Kg', 'nombre_categoria' => 'Abarrotes', 'precio_venta' => 1690, 'stock_actual' => 80, 'stock_minimo' => 20, 'estado' => 'A'],
            ['id_producto' => 6, 'codigo_barra' => '78030002', 'nombre_producto' => 'Aceite Vegetal Belmont 900ml', 'nombre_categoria' => 'Abarrotes', 'precio_venta' => 2190, 'stock_actual' => 50, 'stock_minimo' => 12, 'estado' => 'A'],
            ['id_producto' => 7, 'codigo_barra' => '78040001', 'nombre_producto' => 'Papas Fritas Lays Clásicas 200g', 'nombre_categoria' => 'Snacks y Confites', 'precio_venta' => 1890, 'stock_actual' => 4, 'stock_minimo' => 10, 'estado' => 'A'],
        ];
    }

    if (strpos($procedure_call, 'pr_la_mantenedor_clientes') !== false) {
        return [
            ['id_cliente' => 1, 'rut' => '66.666.666-6', 'nombres' => 'Consumidor Final', 'apellidos' => '(Cliente Ocasional)', 'nombre_completo' => 'Consumidor Final (Cliente Ocasional)', 'email' => 'cliente.ocasional@ventas.cl', 'telefono' => '-', 'direccion' => 'Sin dirección registrada', 'estado' => 'A'],
            ['id_cliente' => 2, 'rut' => '18.456.789-0', 'nombres' => 'Juan', 'apellidos' => 'Pérez González', 'nombre_completo' => 'Juan Pérez González', 'email' => 'juan.perez@gmail.com', 'telefono' => '+56911223344', 'direccion' => 'Av. San Miguel 3605, Talca', 'estado' => 'A'],
            ['id_cliente' => 3, 'rut' => '19.876.543-2', 'nombres' => 'María', 'apellidos' => 'Rojas Sepúlveda', 'nombre_completo' => 'María Rojas Sepúlveda', 'email' => 'maria.rojas@gmail.com', 'telefono' => '+56988776655', 'direccion' => 'Calle 1 Oriente 1234, Talca', 'estado' => 'A'],
            ['id_cliente' => 4, 'rut' => '20.123.456-7', 'nombres' => 'Ignacio', 'apellidos' => 'Muñoz Silva', 'nombre_completo' => 'Ignacio Muñoz Silva', 'email' => 'ignacio.munoz@alumnos.ucm.cl', 'telefono' => '+56955443322', 'direccion' => '2 Norte 567, Curicó', 'estado' => 'A'],
        ];
    }

    if (strpos($procedure_call, 'pr_la_reporte_auditoria') !== false) {
        return [
            ['id_auditoria' => 101, 'nombre_producto' => 'Leche Entera 1L Colun', 'stock_anterior' => 48, 'stock_nuevo' => 45, 'diferencia' => -3, 'operacion' => 'DESCUENTO (VENTA)', 'usuario_bd' => 'PROYECTO_BD', 'fecha_formateada' => date('d/m/Y H:i:s', strtotime('-15 minutes'))],
            ['id_auditoria' => 102, 'nombre_producto' => 'Bebida Coca Cola Original 2.5L', 'stock_anterior' => 62, 'stock_nuevo' => 60, 'diferencia' => -2, 'operacion' => 'DESCUENTO (VENTA)', 'usuario_bd' => 'PROYECTO_BD', 'fecha_formateada' => date('d/m/Y H:i:s', strtotime('-14 minutes'))],
            ['id_auditoria' => 103, 'nombre_producto' => 'Arroz Grado 1 Tucapel 1Kg', 'stock_anterior' => 50, 'stock_nuevo' => 80, 'diferencia' => 30, 'operacion' => 'INGRESO / REPOSICION', 'usuario_bd' => 'PROYECTO_BD', 'fecha_formateada' => date('d/m/Y H:i:s', strtotime('-1 hour'))],
        ];
    }

    if (strpos($procedure_call, 'pr_la_reporte_top_productos') !== false) {
        return [
            ['id_producto' => 1, 'nombre_producto' => 'Leche Entera 1L Colun', 'nombre_categoria' => 'Lácteos y Huevos', 'total_unidades_vendidas' => 24, 'total_recaudado' => 27600],
            ['id_producto' => 3, 'nombre_producto' => 'Bebida Coca Cola Original 2.5L', 'nombre_categoria' => 'Bebidas y Licores', 'total_unidades_vendidas' => 18, 'total_recaudado' => 50220],
            ['id_producto' => 5, 'nombre_producto' => 'Arroz Grado 1 Tucapel 1Kg', 'nombre_categoria' => 'Abarrotes', 'total_unidades_vendidas' => 12, 'total_recaudado' => 20280],
        ];
    }

    if (strpos($procedure_call, 'pr_la_reporte_ventas_cliente') !== false) {
        return [
            ['id_cliente' => 2, 'rut' => '18.456.789-0', 'nombre_cliente' => 'Juan Pérez González', 'cantidad_compras' => 3, 'total_gastado' => 14500, 'total_comprado' => 14500, 'ultima_compra' => date('d/m/Y')],
            ['id_cliente' => 3, 'rut' => '19.876.543-2', 'nombre_cliente' => 'María Rojas Sepúlveda', 'cantidad_compras' => 2, 'total_gastado' => 9800, 'total_comprado' => 9800, 'ultima_compra' => date('d/m/Y')],
            ['id_cliente' => 1, 'rut' => '66.666.666-6', 'nombre_cliente' => 'Consumidor Final', 'cantidad_compras' => 8, 'total_gastado' => 45200, 'total_comprado' => 45200, 'ultima_compra' => date('d/m/Y')],
        ];
    }
    return [];
}
