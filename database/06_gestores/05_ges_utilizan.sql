ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ASOCIAR_TERMINAL(
    p_id_terminal IN NUMBER,
    p_rut_empresa IN VARCHAR2
) IS
    v_rut    VARCHAR2(12);
    v_existe NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_UTILIZAN IN EXCLUSIVE MODE;

    v_rut := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa);

    SELECT COUNT(*) INTO v_existe FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20300, 'El terminal no existe.');
    END IF;

    SELECT COUNT(*) INTO v_existe FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20301, 'La empresa no existe.');
    END IF;

    INSERT INTO LEHZ_UTILIZAN (ID_TERMINAL, RUT_EMPRESA)
    VALUES (p_id_terminal, v_rut);

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20302,
            'Esta asociacion entre terminal y empresa ya existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ASOCIAR_TERMINAL;
/
