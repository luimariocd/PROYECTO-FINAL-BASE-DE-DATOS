ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_MECANICO(
    p_opcion       IN VARCHAR2,
    -- ==================== [MODIFICADO] RUT VARCHAR2 y nuevo TELEFONO ====================
    p_rut          IN VARCHAR2,
    p_nombre       IN VARCHAR2 DEFAULT NULL,
    p_apellido1    IN VARCHAR2 DEFAULT NULL,
    p_apellido2    IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    p_especialidad IN VARCHAR2 DEFAULT NULL,
    p_rut_empresa  IN VARCHAR2 DEFAULT NULL
    -- ====================================================================================
) IS
BEGIN
    LOCK TABLE LEHZ_MECANICO IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        INSERT INTO LEHZ_MECANICO (RUT_MECANICO, NOMBRE_MECANICO, APELLIDO1_MECANICO, APELLIDO2_MECANICO, TELEFONO, ESPECIALIDAD, RUT_EMPRESA)
        VALUES (TRIM(p_rut), TRIM(p_nombre), TRIM(p_apellido1), TRIM(p_apellido2), TRIM(p_telefono), TRIM(p_especialidad), UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', '')));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_MECANICO
        SET NOMBRE_MECANICO = TRIM(p_nombre),
            APELLIDO1_MECANICO = TRIM(p_apellido1),
            APELLIDO2_MECANICO = TRIM(p_apellido2),
            TELEFONO = TRIM(p_telefono),
            ESPECIALIDAD = TRIM(p_especialidad),
            RUT_EMPRESA = UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', ''))
        WHERE RUT_MECANICO = UPPER(REGEXP_REPLACE(TRIM(p_rut), '\.', ''));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20071, 'No se encontro el mecanico a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_MECANICO
        WHERE RUT_MECANICO = UPPER(REGEXP_REPLACE(TRIM(p_rut), '\.', ''));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20072, 'No se encontro el mecanico a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20070, 'Ya existe un mecanico registrado con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_MECANICO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_MECANICOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        -- ==================== [MODIFICADO] Se incluye m.TELEFONO ====================
        SELECT m.RUT_MECANICO, m.NOMBRE_MECANICO, m.APELLIDO1_MECANICO, m.APELLIDO2_MECANICO, m.TELEFONO, m.ESPECIALIDAD, m.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        -- ============================================================================
        FROM LEHZ_MECANICO m
        INNER JOIN LEHZ_EMPRESA e ON m.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY m.APELLIDO1_MECANICO ASC;
END LEHZ_PS_LISTAR_MECANICOS;
/