ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_REGISTRAR_MANTENCION(
    p_fecha         IN DATE,
    p_descripcion   IN VARCHAR2,
    p_costo         IN NUMBER,
    p_rut_mecanico  IN VARCHAR2,
    p_patente_bus   IN VARCHAR2,
    p_id_mant_out   OUT NUMBER
) IS
    v_valida     NUMBER := 0;
    v_rut_limpio VARCHAR2(12) := UPPER(REGEXP_REPLACE(TRIM(p_rut_mecanico), '\.', ''));
BEGIN
    LOCK TABLE LEHZ_MANTENCION IN EXCLUSIVE MODE;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_MECANICO WHERE RUT_MECANICO = v_rut_limpio;
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20131, 'El mecánico no existe.'); END IF;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_BUS WHERE PATENTE_BUS = UPPER(TRIM(p_patente_bus));
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20132, 'El bus no existe.'); END IF;

    SELECT LEHZ_SEQ_MANTENCION.NEXTVAL INTO p_id_mant_out FROM DUAL;

    INSERT INTO LEHZ_MANTENCION (
        ID_MANTENCION, FECHA_MANTENCION, DESCRIPCION_MANTENCION, COSTO_MANTENCION, RUT_MECANICO, PATENTE_BUS
    ) VALUES (
        p_id_mant_out, p_fecha, INITCAP(TRIM(p_descripcion)), p_costo, v_rut_limpio, UPPER(TRIM(p_patente_bus))
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_REGISTRAR_MANTENCION;
/