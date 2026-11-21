ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ASOCIAR_TERMINAL(
    p_id_terminal   IN NUMBER,
    p_rut_empresa   IN VARCHAR2
) IS
    v_valida     NUMBER := 0;
    v_rut_limpio VARCHAR2(12) := UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', ''));
BEGIN
    LOCK TABLE LEHZ_UTILIZAN IN EXCLUSIVE MODE;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal;
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20141, 'El terminal no existe.'); END IF;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut_limpio;
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20142, 'La empresa no existe.'); END IF;

    INSERT INTO LEHZ_UTILIZAN (ID_TERMINAL, RUT_EMPRESA)
    VALUES (p_id_terminal, v_rut_limpio);

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20143, 'Esta asociación entre terminal y empresa ya existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ASOCIAR_TERMINAL;
/