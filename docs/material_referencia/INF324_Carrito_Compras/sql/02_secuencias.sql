-- ============================================================================
-- SCRIPT 02: CREACIÓN DE SECUENCIAS
-- Asignatura: INF324 - Base de Datos
-- Requisito de Rúbrica: Uso de secuencias para la generación de claves primarias
-- ============================================================================

-- Limpieza preventiva
BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ_%') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- Secuencia para Roles
CREATE SEQUENCE SEQ_ROLES
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Usuarios
CREATE SEQUENCE SEQ_USUARIOS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Categorías
CREATE SEQUENCE SEQ_CATEGORIAS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Productos
CREATE SEQUENCE SEQ_PRODUCTOS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Clientes
CREATE SEQUENCE SEQ_CLIENTES
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Ventas (Cabecera)
CREATE SEQUENCE SEQ_VENTAS
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Detalle de Ventas (Líneas)
CREATE SEQUENCE SEQ_DETALLE_VENTAS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Secuencia para Auditoría de Stock
CREATE SEQUENCE SEQ_AUDITORIA_STOCK
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

COMMIT;
