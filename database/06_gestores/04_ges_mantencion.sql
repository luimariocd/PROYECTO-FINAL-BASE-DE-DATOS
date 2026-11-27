ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de registrar mantenciones de buses.
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_REGISTRAR_MANTENCION(
    p_fecha        IN DATE,
    p_descripcion  IN VARCHAR2,
    p_costo        IN NUMBER,
    p_rut_mecanico IN VARCHAR2,
    p_patente_bus  IN VARCHAR2,
    p_id_mant_out  OUT NUMBER
) IS
    v_rut     VARCHAR2(12);
    v_patente VARCHAR2(8);
    v_count   NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_MANTENCION IN EXCLUSIVE MODE;
    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_mecanico, 'PERSONA');
    v_patente := LEHZ_FN_NORMALIZAR_PATENTE(p_patente_bus);

    IF p_fecha IS NULL THEN
        RAISE_APPLICATION_ERROR(-20130, 'La fecha de la mantencion es obligatoria.');
    END IF;
    IF TRUNC(p_fecha) > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20130, 'La fecha de la mantencion no puede ser futura.');
    END IF;
    IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
        RAISE_APPLICATION_ERROR(-20130, 'La descripcion de la mantencion es obligatoria.');
    END IF;
    IF p_costo IS NULL OR p_costo < 0 THEN
        RAISE_APPLICATION_ERROR(-20130, 'El costo de la mantencion debe ser mayor o igual a cero.');
    END IF;

    v_count := LEHZ_FN_EXISTE_MECANICO(v_rut);
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20131, 'El mecanico no existe.');
    END IF;

    v_count := LEHZ_FN_EXISTE_BUS(v_patente);
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20132, 'El bus no existe.');
    END IF;

    p_id_mant_out := LEHZ_SEQ_MANTENCION.NEXTVAL;

    INSERT INTO LEHZ_MANTENCION (
        ID_MANTENCION, FECHA_MANTENCION, DESCRIPCION_MANTENCION,
        COSTO_MANTENCION, RUT_MECANICO, PATENTE_BUS
    ) VALUES (
        p_id_mant_out, TRUNC(p_fecha), LEHZ_FN_NORMALIZAR_TEXTO(p_descripcion),
        p_costo, v_rut, v_patente
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2291 THEN
            RAISE_APPLICATION_ERROR(-20132, 'El mecanico o el bus seleccionado no existe.');
        END IF;
        RAISE;
END LEHZ_PS_GES_REGISTRAR_MANTENCION;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_MANTENCIONES(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT m.ID_MANTENCION,
        TO_CHAR(m.FECHA_MANTENCION, 'DD/MM/YYYY') AS FECHA_MANTENCION,
        m.DESCRIPCION_MANTENCION, m.COSTO_MANTENCION,
        m.RUT_MECANICO,
        me.NOMBRE_MECANICO || ' ' || me.APELLIDO1_MECANICO AS MECANICO,
        m.PATENTE_BUS,
        b.MARCA || ' ' || b.MODELO AS BUS,
        b.RUT_EMPRESA, e.RAZON_SOCIAL
        FROM LEHZ_MANTENCION m
        INNER JOIN LEHZ_MECANICO me ON me.RUT_MECANICO = m.RUT_MECANICO
        INNER JOIN LEHZ_BUS b ON b.PATENTE_BUS = m.PATENTE_BUS
        INNER JOIN LEHZ_EMPRESA e ON e.RUT_EMPRESA = b.RUT_EMPRESA
        ORDER BY m.FECHA_MANTENCION DESC, m.ID_MANTENCION DESC;
    v_registro_cursor cur_local%ROWTYPE;
BEGIN
    -- Esta parte del código se encarga de abrir, leer y cerrar el cursor local sin consumir el SYS_REFCURSOR de salida.
    OPEN cur_local;
    FETCH cur_local INTO v_registro_cursor;
    IF cur_local%NOTFOUND THEN
        NULL;
    END IF;
    CLOSE cur_local;
    OPEN p_cursor FOR
        SELECT m.ID_MANTENCION,
               TO_CHAR(m.FECHA_MANTENCION, 'DD/MM/YYYY') AS FECHA_MANTENCION,
               m.DESCRIPCION_MANTENCION, m.COSTO_MANTENCION,
               m.RUT_MECANICO,
               me.NOMBRE_MECANICO || ' ' || me.APELLIDO1_MECANICO AS MECANICO,
               m.PATENTE_BUS,
               b.MARCA || ' ' || b.MODELO AS BUS,
               b.RUT_EMPRESA, e.RAZON_SOCIAL
        FROM LEHZ_MANTENCION m
        INNER JOIN LEHZ_MECANICO me ON me.RUT_MECANICO = m.RUT_MECANICO
        INNER JOIN LEHZ_BUS b ON b.PATENTE_BUS = m.PATENTE_BUS
        INNER JOIN LEHZ_EMPRESA e ON e.RUT_EMPRESA = b.RUT_EMPRESA
        ORDER BY m.FECHA_MANTENCION DESC, m.ID_MANTENCION DESC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_LISTAR_MANTENCIONES: ' || SQLERRM);
END LEHZ_PS_LISTAR_MANTENCIONES;
/
