-- ============================================================================
-- SCRIPT 05: DISPARADORES / TRIGGERS (MONITOREO Y CONTROL DE LA BASE DE DATOS)
-- Asignatura: INF324 - Base de Datos
-- Requisitos de Rúbrica:
--   1. Creación correcta de disparadores (triggers) de base de datos con sigla 'LA'.
--   2. Momento adecuado (BEFORE / AFTER).
--   3. Operadores :NEW y :OLD contextualizados en INSERT / UPDATE.
--   4. Uso de secuencias ('SEQ_AUDITORIA_STOCK') y funciones de soporte.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DISPARADOR 1: Auditoría Automática de Modificaciones de Stock (AFTER UPDATE)
-- Cada vez que se modifica el stock de un producto (por venta o ajuste manual),
-- este disparador registra el evento en AUDITORIA_STOCK usando :OLD y :NEW.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_la_auditoria_cambio_stock
AFTER UPDATE OF stock_actual ON PRODUCTOS
FOR EACH ROW
DECLARE
    v_diferencia NUMBER;
    v_operacion  VARCHAR2(30);
    v_usuario    VARCHAR2(50);
BEGIN
    -- Calcular la variación producida
    v_diferencia := :NEW.stock_actual - :OLD.stock_actual;

    -- Determinar el tipo de operación según la dirección del cambio
    IF v_diferencia < 0 THEN
        v_operacion := 'DESCUENTO (VENTA)';
    ELSIF v_diferencia > 0 THEN
        v_operacion := 'INGRESO / REPOSICION';
    ELSE
        v_operacion := 'MODIFICACION SIN CAMBIO';
    END IF;

    -- Obtener usuario del sistema Oracle o variable de sesión
    v_usuario := USER;

    -- Insertar en la tabla de auditoría usando la secuencia
    INSERT INTO AUDITORIA_STOCK (
        id_auditoria,
        id_producto,
        stock_anterior,
        stock_nuevo,
        diferencia,
        operacion,
        usuario_bd,
        fecha_registro
    ) VALUES (
        SEQ_AUDITORIA_STOCK.NEXTVAL,
        :NEW.id_producto,
        :OLD.stock_actual,
        :NEW.stock_actual,
        v_diferencia,
        v_operacion,
        v_usuario,
        SYSDATE
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Registro de error para evitar que caiga la transacción principal si falla auditoría
        DBMS_OUTPUT.PUT_LINE('Error en disparador trg_la_auditoria_cambio_stock: ' || SQLERRM);
END trg_la_auditoria_cambio_stock;
/

-- ----------------------------------------------------------------------------
-- DISPARADOR 2: Validación e Integridad Preventiva de Códigos de Barra (BEFORE INSERT OR UPDATE)
-- Garantiza que el código de barra esté siempre en mayúsculas y valide stock positivo.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_la_sanitizar_producto
BEFORE INSERT OR UPDATE ON PRODUCTOS
FOR EACH ROW
BEGIN
    -- Estandarización de datos mediante :NEW
    :NEW.codigo_barra := UPPER(:NEW.codigo_barra);

    -- Validación preventiva de stock negativo
    IF :NEW.stock_actual < 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Violación de Integridad: El stock no puede quedar en números negativos.');
    END IF;
END trg_la_sanitizar_producto;
/

COMMIT;
