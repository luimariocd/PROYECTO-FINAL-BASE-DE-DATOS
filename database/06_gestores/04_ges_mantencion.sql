ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_REGISTRAR_MANTENCION(
    p_fecha        IN DATE,
    p_descripcion  IN VARCHAR2,
    p_costo        IN NUMBER,
    p_rut_mecanico IN VARCHAR2,
    p_patente_bus  IN VARCHAR2,
    p_id_mant_out  OUT NUMBER
) IS
    v_rut      VARCHAR2(12);
    v_patente  VARCHAR2(8);
    v_existe   NUMBER := 0;
    v_emp_mec  VARCHAR2(12);
    v_emp_bus  VARCHAR2(12);
BEGIN
    LOCK TABLE LEHZ_MANTENCION IN EXCLUSIVE MODE;

    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_mecanico);
    v_patente := UPPER(TRIM(p_patente_bus));

    IF p_fecha IS NULL THEN
        RAISE_APPLICATION_ERROR(-20280, 'La fecha de la mantencion es obligatoria.');
    END IF;

    IF p_fecha > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20281,
            'La fecha de la mantencion no puede ser posterior a la fecha actual.');
    END IF;

    IF p_costo IS NULL OR p_costo < 0 THEN
        RAISE_APPLICATION_ERROR(-20282, 'El costo de la mantencion no puede ser negativo.');
    END IF;

    SELECT COUNT(*), MAX(RUT_EMPRESA)
    INTO v_existe, v_emp_mec
    FROM LEHZ_MECANICO
    WHERE RUT_MECANICO = v_rut;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20283, 'El mecanico no existe.');
    END IF;

    SELECT COUNT(*), MAX(RUT_EMPRESA)
    INTO v_existe, v_emp_bus
    FROM LEHZ_BUS
    WHERE PATENTE_BUS = v_patente;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20284, 'El bus no existe.');
    END IF;

    IF v_emp_mec <> v_emp_bus THEN
        RAISE_APPLICATION_ERROR(-20285,
            'El mecanico y el bus deben pertenecer a la misma empresa.');
    END IF;

    p_id_mant_out := LEHZ_SEQ_MANTENCION.NEXTVAL;

    INSERT INTO LEHZ_MANTENCION (
        ID_MANTENCION, FECHA_MANTENCION, DESCRIPCION_MANTENCION, COSTO_MANTENCION,
        RUT_MECANICO, PATENTE_BUS
    ) VALUES (
        p_id_mant_out, p_fecha, LEHZ_FN_TITULO(p_descripcion), p_costo,
        v_rut, v_patente
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_REGISTRAR_MANTENCION;
/
