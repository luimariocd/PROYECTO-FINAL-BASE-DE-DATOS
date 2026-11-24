ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- GESTOR 05: ASOCIACION TERMINAL - EMPRESA
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ASOCIAR_TERMINAL(
    p_id_terminal IN NUMBER,
    p_rut_empresa IN VARCHAR2,
    p_opcion      IN VARCHAR2 DEFAULT 'I'
) IS
    v_rut   VARCHAR2(12);
    v_count NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_UTILIZAN IN EXCLUSIVE MODE;
    v_rut := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa, 'EMPRESA');

    IF p_id_terminal IS NULL OR p_id_terminal <= 0 THEN
        RAISE_APPLICATION_ERROR(-20140, 'Debe seleccionar un terminal valido.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20141, 'El terminal no existe.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20142, 'La empresa no existe.');
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_UTILIZAN (ID_TERMINAL, RUT_EMPRESA)
        VALUES (p_id_terminal, v_rut);

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_UTILIZAN
         WHERE ID_TERMINAL = p_id_terminal
           AND RUT_EMPRESA = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20144, 'No se encontro la asociacion a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20140, 'Operacion invalida. Use I o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20143, 'Esta asociacion entre terminal y empresa ya existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ASOCIAR_TERMINAL;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_UTILIZAN(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT u.ID_TERMINAL, t.NOMBRE AS TERMINAL,
               c.NOMBRE_COMUNA,
               u.RUT_EMPRESA, e.RAZON_SOCIAL
        FROM LEHZ_UTILIZAN u
        INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = u.ID_TERMINAL
        INNER JOIN LEHZ_COMUNA c ON c.ID_COMUNA = t.ID_COMUNA
        INNER JOIN LEHZ_EMPRESA e ON e.RUT_EMPRESA = u.RUT_EMPRESA
        ORDER BY e.RAZON_SOCIAL ASC, t.NOMBRE ASC;
END LEHZ_PS_LISTAR_UTILIZAN;
/
