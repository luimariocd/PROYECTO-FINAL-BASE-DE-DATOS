-- ============================================================================
-- SCRIPT 03: FUNCIONES PL/SQL
-- Asignatura: INF324 - Base de Datos
-- Requisitos de Rúbrica y Regla de Arquitectura:
--   1. Las funciones son los ÚNICOS objetos donde se encapsulan consultas de datos (SELECT INTO)
--      y cálculos de negocio, evitando consultas SELECT dentro de los Procedimientos Almacenados.
--   2. PREFIJO CON SIGLA DEL AUTOR: Se usa 'fn_la_' (sigla 'LA').
--   3. Diferenciación estricta entre parámetros (p_), variables locales (v_) 
--      y nombres de columnas de las tablas.
--   4. Manejo y control explícito de Excepciones.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FUNCIÓN 1: Calcular IVA (19%) sobre un monto subtotal
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_la_calcular_iva (
    p_subtotal IN NUMBER
) RETURN NUMBER IS
    v_iva           NUMBER(12, 2);
    c_tasa_iva      CONSTANT NUMBER(3, 2) := 0.19;
    ex_monto_negativo EXCEPTION;
BEGIN
    IF p_subtotal IS NULL THEN
        RETURN 0;
    END IF;

    IF p_subtotal < 0 THEN
        RAISE ex_monto_negativo;
    END IF;

    v_iva := ROUND(p_subtotal * c_tasa_iva, 2);
    RETURN v_iva;

EXCEPTION
    WHEN ex_monto_negativo THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: El subtotal no puede ser negativo.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error inesperado al calcular IVA: ' || SQLERRM);
END fn_la_calcular_iva;
/

-- ----------------------------------------------------------------------------
-- FUNCIÓN 2: Generar número de folio formateado para la venta
-- Ejemplo de salida: FOL-2026-00001001
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_la_generar_folio (
    p_id_venta IN NUMBER
) RETURN VARCHAR2 IS
    v_folio         VARCHAR2(30);
    v_anio          VARCHAR2(4);
BEGIN
    IF p_id_venta IS NULL OR p_id_venta <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error: ID de venta inválido para generar folio.');
    END IF;

    v_anio  := TO_CHAR(SYSDATE, 'YYYY');
    v_folio := 'FOL-' || v_anio || '-' || LPAD(TO_CHAR(p_id_venta), 8, '0');
    
    RETURN v_folio;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error inesperado al generar folio: ' || SQLERRM);
END fn_la_generar_folio;
/

-- ----------------------------------------------------------------------------
-- FUNCIÓN 3: Verificar disponibilidad de stock suficiente
-- Retorna 1 si hay stock suficiente, 0 si no alcanza
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_la_verificar_stock (
    p_id_producto IN NUMBER,
    p_cantidad    IN NUMBER
) RETURN NUMBER IS
    v_stock_disponible NUMBER;
BEGIN
    IF p_cantidad <= 0 THEN
        RETURN 0;
    END IF;

    SELECT stock_actual
      INTO v_stock_disponible
      FROM PRODUCTOS
     WHERE id_producto = p_id_producto
       AND estado = 'A';

    IF v_stock_disponible >= p_cantidad THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Si el producto no existe o está inactivo
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Error al consultar stock del producto ' || p_id_producto || ': ' || SQLERRM);
END fn_la_verificar_stock;
/

-- ----------------------------------------------------------------------------
-- FUNCIÓN 4: Obtener el precio unitario de un producto
-- Esta función reemplaza la necesidad de hacer SELECT dentro de los Procedimientos Almacenados
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_la_obtener_precio_producto (
    p_id_producto IN NUMBER
) RETURN NUMBER IS
    v_precio NUMBER(10, 2);
BEGIN
    SELECT precio_venta
      INTO v_precio
      FROM PRODUCTOS
     WHERE id_producto = p_id_producto
       AND estado = 'A';

    RETURN v_precio;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error: El producto con ID ' || p_id_producto || ' no existe o está inactivo.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20007, 'Error al obtener precio del producto: ' || SQLERRM);
END fn_la_obtener_precio_producto;
/

-- ----------------------------------------------------------------------------
-- FUNCIÓN 5: Obtener total acumulado de compras de un cliente
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_la_total_compras_cliente (
    p_id_cliente IN NUMBER
) RETURN NUMBER IS
    v_total_acumulado NUMBER(12, 2) := 0;
BEGIN
    SELECT NVL(SUM(total), 0)
      INTO v_total_acumulado
      FROM VENTAS
     WHERE id_cliente = p_id_cliente
       AND estado = 'PAGADA';

    RETURN v_total_acumulado;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END fn_la_total_compras_cliente;
/

COMMIT;
