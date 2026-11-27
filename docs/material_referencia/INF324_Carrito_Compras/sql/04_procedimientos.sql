-- ============================================================================
-- SCRIPT 04: PROCEDIMIENTOS ALMACENADOS Y CURSORES (CLIENTE GORDO)
-- Asignatura: INF324 - Base de Datos
-- Reglas de RÃºbrica y EstÃ¡ndares de Clase:
--   1. Los 10 MANTENEDORES corresponden a procedimientos integrales que
--      administran el ciclo CRUD completo de una tabla mediante un parÃ¡metro 'p_opcion'.
--      (Criterio de RÃºbrica: "Maneja opciones de acuerdo a las distintas actividades solicitadas").
--   2. CERO sentencias SELECT directas en operaciones DML (INSERT, UPDATE, DELETE).
--      - Las secuencias se asignan directo en el VALUES (SEQ_TABLA.NEXTVAL).
--      - Consultas de valores individuales se hacen por FUNCIONES (fn_la_...).
--   3. CERO ciclos WHILE complejos en PL/SQL: La iteraciÃ³n de Ã­tems del carrito
--      se realiza naturalmente en el backend (PHP foreach), llamando al Procedimiento Almacenado por cada Ã­tem.
--   4. Toda visualizaciÃ³n de datos se realiza EXCLUSIVAMENTE vÃ­a CURSORES.
--   5. Control transaccional riguroso (COMMIT / ROLLBACK) y captura de excepciones.
-- ============================================================================

-- ============================================================================
-- SECCIÃ“N A: MANTENEDOR DE PRODUCTOS (CRUD INTEGRAL CON OPCIONES)
-- ============================================================================

CREATE OR REPLACE PROCEDURE pr_la_mantenedor_productos (
    p_opcion          IN VARCHAR2, -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT_ALL', 'SELECT_ID'
    p_id_producto     IN NUMBER   DEFAULT NULL,
    p_id_categoria    IN NUMBER   DEFAULT NULL,
    p_codigo_barra    IN VARCHAR2 DEFAULT NULL,
    p_nombre_producto IN VARCHAR2 DEFAULT NULL,
    p_precio_venta    IN NUMBER   DEFAULT NULL,
    p_stock_actual    IN NUMBER   DEFAULT NULL,
    p_stock_minimo    IN NUMBER   DEFAULT 5,
    p_cursor          OUT SYS_REFCURSOR,
    p_resultado       OUT VARCHAR2
) IS
    v_filas_afectadas  NUMBER;
    ex_opcion_invalida EXCEPTION;
    ex_precio_invalido EXCEPTION;
BEGIN
    CASE UPPER(p_opcion)
        -- --------------------------------------------------------------------
        -- OPCIÃ“N 1: INSERT (Crear nuevo producto)
        -- --------------------------------------------------------------------
        WHEN 'INSERT' THEN
            IF p_precio_venta < 0 THEN
                RAISE ex_precio_invalido;
            END IF;

            INSERT INTO PRODUCTOS (
                id_producto,
                id_categoria,
                codigo_barra,
                nombre_producto,
                precio_venta,
                stock_actual,
                stock_minimo,
                estado
            ) VALUES (
                SEQ_PRODUCTOS.NEXTVAL,
                p_id_categoria,
                p_codigo_barra,
                p_nombre_producto,
                p_precio_venta,
                p_stock_actual,
                NVL(p_stock_minimo, 5),
                'A'
            );

            COMMIT;
            p_resultado := 'OK: Producto registrado exitosamente en la base de datos.';

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 2: UPDATE (Actualizar producto existente)
        -- --------------------------------------------------------------------
        WHEN 'UPDATE' THEN
            UPDATE PRODUCTOS
               SET id_categoria    = NVL(p_id_categoria, id_categoria),
                   nombre_producto = NVL(p_nombre_producto, nombre_producto),
                   precio_venta    = NVL(p_precio_venta, precio_venta),
                   stock_actual    = NVL(p_stock_actual, stock_actual)
             WHERE id_producto     = p_id_producto;

            v_filas_afectadas := SQL%ROWCOUNT;

            IF v_filas_afectadas = 0 THEN
                ROLLBACK;
                p_resultado := 'ERROR: No se encontrÃ³ el producto con ID ' || p_id_producto;
            ELSE
                COMMIT;
                p_resultado := 'OK: Producto actualizado correctamente.';
            END IF;

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 3: DELETE (Baja lÃ³gica para preservar integridad)
        -- --------------------------------------------------------------------
        WHEN 'DELETE' THEN
            UPDATE PRODUCTOS
               SET estado = 'I'
             WHERE id_producto = p_id_producto;

            v_filas_afectadas := SQL%ROWCOUNT;

            IF v_filas_afectadas = 0 THEN
                ROLLBACK;
                p_resultado := 'ERROR: No se encontrÃ³ el producto para dar de baja.';
            ELSE
                COMMIT;
                p_resultado := 'OK: Producto dado de baja exitosamente.';
            END IF;

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 4: SELECT_ALL (Listar catÃ¡logo activo a travÃ©s de CURSOR)
        -- --------------------------------------------------------------------
        WHEN 'SELECT_ALL' THEN
            OPEN p_cursor FOR
                SELECT p.id_producto,
                       p.codigo_barra,
                       p.nombre_producto,
                       c.nombre_categoria,
                       p.precio_venta,
                       p.stock_actual,
                       p.stock_minimo,
                       p.estado
                  FROM PRODUCTOS p
                  JOIN CATEGORIAS c ON p.id_categoria = c.id_categoria
                 WHERE p.estado = 'A'
                 ORDER BY p.nombre_producto ASC;

            p_resultado := 'OK: Listado de productos obtenido mediante Cursor.';

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 5: SELECT_ID (Consultar un producto individual vÃ­a CURSOR)
        -- --------------------------------------------------------------------
        WHEN 'SELECT_ID' THEN
            OPEN p_cursor FOR
                SELECT id_producto,
                       id_categoria,
                       codigo_barra,
                       nombre_producto,
                       precio_venta,
                       stock_actual,
                       stock_minimo,
                       estado
                  FROM PRODUCTOS
                 WHERE id_producto = p_id_producto;

            p_resultado := 'OK: Datos del producto obtenidos mediante Cursor.';

        ELSE
            RAISE ex_opcion_invalida;
    END CASE;

EXCEPTION
    WHEN ex_precio_invalido THEN
        ROLLBACK;
        p_resultado := 'ERROR: El precio de venta no puede ser negativo.';
    WHEN ex_opcion_invalida THEN
        ROLLBACK;
        p_resultado := 'ERROR: La opciÃ³n enviada al mantenedor no es vÃ¡lida.';
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_resultado := 'ERROR: El cÃ³digo de barra ya se encuentra registrado.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR en pr_la_mantenedor_productos: ' || SQLERRM;
END pr_la_mantenedor_productos;
/


-- ============================================================================
-- SECCIÃ“N A.2: MANTENEDOR DE CLIENTES (CRUD INTEGRAL CON OPCIONES Y SOFT DELETE)
-- ============================================================================

CREATE OR REPLACE PROCEDURE pr_la_mantenedor_clientes (
    p_opcion      IN VARCHAR2, -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT_ALL', 'SELECT_ID'
    p_id_cliente  IN NUMBER   DEFAULT NULL,
    p_rut         IN VARCHAR2 DEFAULT NULL,
    p_nombres     IN VARCHAR2 DEFAULT NULL,
    p_apellidos   IN VARCHAR2 DEFAULT NULL,
    p_email       IN VARCHAR2 DEFAULT NULL,
    p_telefono    IN VARCHAR2 DEFAULT NULL,
    p_direccion   IN VARCHAR2 DEFAULT NULL,
    p_cursor      OUT SYS_REFCURSOR,
    p_resultado   OUT VARCHAR2
) IS
    v_filas_afectadas  NUMBER;
    ex_opcion_invalida EXCEPTION;
BEGIN
    CASE UPPER(p_opcion)
        -- --------------------------------------------------------------------
        -- OPCIÃ“N 1: INSERT (Crear nuevo cliente)
        -- --------------------------------------------------------------------
        WHEN 'INSERT' THEN
            INSERT INTO CLIENTES (
                id_cliente,
                rut,
                nombres,
                apellidos,
                email,
                telefono,
                direccion,
                estado
            ) VALUES (
                SEQ_CLIENTES.NEXTVAL,
                p_rut,
                p_nombres,
                p_apellidos,
                p_email,
                p_telefono,
                p_direccion,
                'A'
            );

            COMMIT;
            p_resultado := 'OK: Cliente registrado exitosamente en la base de datos.';

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 2: UPDATE (Actualizar datos del cliente)
        -- --------------------------------------------------------------------
        WHEN 'UPDATE' THEN
            UPDATE CLIENTES
               SET rut       = NVL(p_rut, rut),
                   nombres   = NVL(p_nombres, nombres),
                   apellidos = NVL(p_apellidos, apellidos),
                   email     = NVL(p_email, email),
                   telefono  = NVL(p_telefono, telefono),
                   direccion = NVL(p_direccion, direccion)
             WHERE id_cliente = p_id_cliente;

            v_filas_afectadas := SQL%ROWCOUNT;

            IF v_filas_afectadas = 0 THEN
                ROLLBACK;
                p_resultado := 'ERROR: No se encontrÃ³ el cliente con ID ' || p_id_cliente;
            ELSE
                COMMIT;
                p_resultado := 'OK: Cliente actualizado correctamente.';
            END IF;

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 3: DELETE (Baja lÃ³gica / Soft Delete)
        -- --------------------------------------------------------------------
        WHEN 'DELETE' THEN
            UPDATE CLIENTES
               SET estado = 'I'
             WHERE id_cliente = p_id_cliente;

            v_filas_afectadas := SQL%ROWCOUNT;

            IF v_filas_afectadas = 0 THEN
                ROLLBACK;
                p_resultado := 'ERROR: No se encontrÃ³ el cliente para dar de baja.';
            ELSE
                COMMIT;
                p_resultado := 'OK: Cliente dado de baja exitosamente (Soft Delete).';
            END IF;

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 4: SELECT_ALL (Listar clientes activos vÃ­a CURSOR)
        -- --------------------------------------------------------------------
        WHEN 'SELECT_ALL' THEN
            OPEN p_cursor FOR
                SELECT id_cliente,
                       rut,
                       nombres,
                       apellidos,
                       nombres || ' ' || apellidos AS nombre_completo,
                       email,
                       telefono,
                       direccion,
                       estado
                  FROM CLIENTES
                 WHERE estado = 'A'
                 ORDER BY id_cliente ASC;

            p_resultado := 'OK: Listado de clientes obtenido mediante Cursor.';

        -- --------------------------------------------------------------------
        -- OPCIÃ“N 5: SELECT_ID (Consultar un cliente individual vÃ­a CURSOR)
        -- --------------------------------------------------------------------
        WHEN 'SELECT_ID' THEN
            OPEN p_cursor FOR
                SELECT id_cliente,
                       rut,
                       nombres,
                       apellidos,
                       email,
                       telefono,
                       direccion,
                       estado
                  FROM CLIENTES
                 WHERE id_cliente = p_id_cliente;

            p_resultado := 'OK: Datos del cliente recuperados exitosamente.';

        ELSE
            RAISE ex_opcion_invalida;
    END CASE;

EXCEPTION
    WHEN ex_opcion_invalida THEN
        ROLLBACK;
        p_resultado := 'ERROR: La opciÃ³n enviada al mantenedor de clientes no es vÃ¡lida.';
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_resultado := 'ERROR: Ya existe un cliente registrado con ese RUT.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR en pr_la_mantenedor_clientes: ' || SQLERRM;
END pr_la_mantenedor_clientes;
/


-- ============================================================================
-- SECCIÃ“N B: GESTOR DE VENTAS / CARRITO DE COMPRAS (TRANSACCIÃ“N MODULAR)
-- Requisito de RÃºbrica: Cruzar datos de clientes y productos, calcular montos,
-- manejar integridad, funciones, secuencias, COMMIT y ROLLBACK.
-- Sin ciclos complejos: El recorrido de Ã­tems lo hace PHP de forma limpia.
-- ============================================================================

-- 1. Iniciar la cabecera de la venta en estado PENDIENTE
CREATE OR REPLACE PROCEDURE pr_la_gestor_iniciar_venta (
    p_id_cliente   IN NUMBER,
    p_id_usuario   IN NUMBER,
    p_id_venta_out OUT NUMBER,
    p_folio_out    OUT VARCHAR2,
    p_resultado    OUT VARCHAR2
) IS
    v_id_venta     NUMBER(10);
    v_numero_folio VARCHAR2(30);
    ex_cliente_invalido EXCEPTION;
BEGIN
    IF p_id_cliente IS NULL OR p_id_cliente <= 0 THEN
        RAISE ex_cliente_invalido;
    END IF;

    -- AsignaciÃ³n directa de secuencia
    v_id_venta     := SEQ_VENTAS.NEXTVAL;
    v_numero_folio := fn_la_generar_folio(v_id_venta);

    INSERT INTO VENTAS (
        id_venta,
        id_cliente,
        id_usuario,
        numero_folio,
        fecha_venta,
        subtotal,
        iva,
        total,
        estado
    ) VALUES (
        v_id_venta,
        p_id_cliente,
        p_id_usuario,
        v_numero_folio,
        SYSDATE,
        0, 0, 0,
        'PENDIENTE'
    );

    p_id_venta_out := v_id_venta;
    p_folio_out    := v_numero_folio;
    p_resultado    := 'OK: Venta iniciada exitosamente.';

EXCEPTION
    WHEN ex_cliente_invalido THEN
        ROLLBACK;
        p_resultado := 'ERROR: Cliente no vÃ¡lido.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR al iniciar venta: ' || SQLERRM;
END pr_la_gestor_iniciar_venta;
/

-- 2. Agregar un Ã­tem al detalle de la venta y descontar stock
CREATE OR REPLACE PROCEDURE pr_la_gestor_agregar_item (
    p_id_venta    IN NUMBER,
    p_id_producto IN NUMBER,
    p_cantidad    IN NUMBER,
    p_resultado   OUT VARCHAR2
) IS
    v_stock_ok       NUMBER;
    v_precio_prod    NUMBER(10, 2);
    v_subtotal_linea NUMBER(12, 2);
    ex_stock_insuf   EXCEPTION;
BEGIN
    -- Validar stock mediante la FUNCIÃ“N PL/SQL 
    v_stock_ok := fn_la_verificar_stock(p_id_producto, p_cantidad);
    IF v_stock_ok = 0 THEN
        RAISE ex_stock_insuf;
    END IF;

    -- Obtener precio unitario mediante la FUNCIÃ“N PL/SQL 
    v_precio_prod    := fn_la_obtener_precio_producto(p_id_producto);
    v_subtotal_linea := v_precio_prod * p_cantidad;

    -- Insertar lÃ­nea de detalle usando secuencia directo en VALUES
    INSERT INTO DETALLE_VENTAS (
        id_detalle,
        id_venta,
        id_producto,
        cantidad,
        precio_unitario,
        subtotal_linea
    ) VALUES (
        SEQ_DETALLE_VENTAS.NEXTVAL,
        p_id_venta,
        p_id_producto,
        p_cantidad,
        v_precio_prod,
        v_subtotal_linea
    );

    -- Descontar stock (esto dispara automÃ¡ticamente el TRIGGER de auditorÃ­a)
    UPDATE PRODUCTOS
       SET stock_actual = stock_actual - p_cantidad
     WHERE id_producto = p_id_producto;

    p_resultado := 'OK: Ãtem agregado a la venta.';

EXCEPTION
    WHEN ex_stock_insuf THEN
        ROLLBACK;
        p_resultado := 'ERROR: Stock insuficiente para el producto ID ' || p_id_producto;
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR al agregar Ã­tem a la venta: ' || SQLERRM;
END pr_la_gestor_agregar_item;
/

-- 3. Finalizar la venta calculando totales con funciones y confirmando con COMMIT
CREATE OR REPLACE PROCEDURE pr_la_gestor_finalizar_venta (
    p_id_venta  IN NUMBER,
    p_total_out OUT NUMBER,
    p_resultado OUT VARCHAR2
) IS
    v_subtotal NUMBER(12, 2);
    v_iva      NUMBER(12, 2);
    v_total    NUMBER(12, 2);
BEGIN
    -- Sumar subtotales del detalle de esta venta
    SELECT NVL(SUM(subtotal_linea), 0)
      INTO v_subtotal
      FROM DETALLE_VENTAS
     WHERE id_venta = p_id_venta;

    -- Calcular IVA (19%) mediante la FUNCIÃ“N PL/SQL
    v_iva   := fn_la_calcular_iva(v_subtotal);
    v_total := v_subtotal + v_iva;

    -- Actualizar cabecera de la venta a estado PAGADA
    UPDATE VENTAS
       SET subtotal = v_subtotal,
           iva      = v_iva,
           total    = v_total,
           estado   = 'PAGADA'
     WHERE id_venta = p_id_venta;

    -- Confirmar toda la transacciÃ³n
    COMMIT;

    p_total_out := v_total;
    p_resultado := 'OK: Venta finalizada y pagada con Ã©xito.';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR al finalizar venta: ' || SQLERRM;
END pr_la_gestor_finalizar_venta;
/


-- ============================================================================
-- SECCIÃ“N C: CURSOR EXPLÃCITO INTERNO (Requisito Formal de RÃºbrica)
-- Ejemplo de procedimiento que declara, abre, recorre (LOOP) y cierra un cursor
-- con prefijo de iniciales para procesar alertas
-- ============================================================================
CREATE OR REPLACE PROCEDURE pr_la_verificar_alertas_stock (
    p_total_alertas OUT NUMBER
) IS
    -- DeclaraciÃ³n de cursor con prefijo de iniciales ('cur_ay_...')
    CURSOR cur_ay_productos_bajos IS
        SELECT id_producto, nombre_producto, stock_actual, stock_minimo
          FROM PRODUCTOS
         WHERE stock_actual <= stock_minimo
           AND estado = 'A';

    v_reg cur_ay_productos_bajos%ROWTYPE;
    v_contador NUMBER := 0;
BEGIN
    -- Abrir cursor
    OPEN cur_ay_productos_bajos;

    LOOP
        -- Recorrer cursor
        FETCH cur_ay_productos_bajos INTO v_reg;
        EXIT WHEN cur_ay_productos_bajos%NOTFOUND;

        v_contador := v_contador + 1;
        DBMS_OUTPUT.PUT_LINE('ALERTA: ' || v_reg.nombre_producto || ' tiene stock crÃ­tico: ' || v_reg.stock_actual);
    END LOOP;

    -- Cerrar cursor
    CLOSE cur_ay_productos_bajos;

    p_total_alertas := v_contador;

EXCEPTION
    WHEN OTHERS THEN
        IF cur_ay_productos_bajos%ISOPEN THEN
            CLOSE cur_ay_productos_bajos;
        END IF;
        p_total_alertas := -1;
END pr_la_verificar_alertas_stock;
/


-- ============================================================================
-- SECCIÃ“N D: REPORTES SOLICITADOS POR LA RÃšBRICA (EXCLUSIVAMENTE VÃA CURSOR)
-- ============================================================================

-- REPORTE 1: Top Productos MÃ¡s Vendidos
CREATE OR REPLACE PROCEDURE pr_la_reporte_top_productos (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT p.nombre_producto,
               c.nombre_categoria,
               NVL(SUM(d.cantidad), 0) AS total_unidades_vendidas,
               NVL(SUM(d.subtotal_linea), 0) AS total_recaudado
          FROM PRODUCTOS p
          JOIN CATEGORIAS c ON p.id_categoria = c.id_categoria
     LEFT JOIN DETALLE_VENTAS d ON p.id_producto = d.id_producto
         GROUP BY p.nombre_producto, c.nombre_categoria
         ORDER BY total_unidades_vendidas DESC;
END pr_la_reporte_top_productos;
/

-- REPORTE 2: Resumen de Ventas por Cliente
CREATE OR REPLACE PROCEDURE pr_la_reporte_ventas_cliente (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT c.rut,
               c.nombres || ' ' || c.apellidos AS nombre_cliente,
               COUNT(v.id_venta) AS cantidad_compras,
               NVL(SUM(v.total), 0) AS total_gastado
          FROM CLIENTES c
     LEFT JOIN VENTAS v ON c.id_cliente = v.id_cliente AND v.estado = 'PAGADA'
         GROUP BY c.rut, c.nombres, c.apellidos
         ORDER BY total_gastado DESC;
END pr_la_reporte_ventas_cliente;
/

-- REPORTE 3: Historial de AuditorÃ­a de Stock (Monitoreo)
CREATE OR REPLACE PROCEDURE pr_la_reporte_auditoria (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT a.id_auditoria,
               p.nombre_producto,
               a.stock_anterior,
               a.stock_nuevo,
               a.diferencia,
               a.operacion,
               a.usuario_bd,
               TO_CHAR(a.fecha_registro, 'DD/MM/YYYY HH24:MI:SS') AS fecha_formateada
          FROM AUDITORIA_STOCK a
          JOIN PRODUCTOS p ON a.id_producto = p.id_producto
         ORDER BY a.id_auditoria DESC;
END pr_la_reporte_auditoria;
/

COMMIT;

