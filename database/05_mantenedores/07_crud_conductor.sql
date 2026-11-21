ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_CONDUCTOR(
    p_opcion              IN VARCHAR2,
    -- ==================== [MODIFICADO] RUT VARCHAR2 y nuevo TELEFONO ====================
    p_rut                 IN VARCHAR2,
    p_nombre              IN VARCHAR2 DEFAULT NULL,
    p_apellido1           IN VARCHAR2 DEFAULT NULL,
    p_apellido2           IN VARCHAR2 DEFAULT NULL,
    p_telefono            IN VARCHAR2 DEFAULT NULL,
    p_tipo_licencia       IN VARCHAR2 DEFAULT NULL,
    p_vencimiento         IN DATE DEFAULT NULL,
    p_rut_empresa         IN VARCHAR2 DEFAULT NULL
    -- ====================================================================================
) IS
BEGIN
    LOCK TABLE LEHZ_CONDUCTOR IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        INSERT INTO LEHZ_CONDUCTOR (RUT_CONDUCTOR, NOMBRE_CONDUCTOR, APELLIDO1_CONDUCTOR, APELLIDO2_CONDUCTOR, TELEFONO, TIPO_LICENCIA, VENCIMIENTO_LICENCIA, RUT_EMPRESA)
        VALUES (TRIM(p_rut), TRIM(p_nombre), TRIM(p_apellido1), TRIM(p_apellido2), TRIM(p_telefono), UPPER(TRIM(p_tipo_licencia)), p_vencimiento, UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', '')));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_CONDUCTOR
        SET NOMBRE_CONDUCTOR = TRIM(p_nombre),
            APELLIDO1_CONDUCTOR = TRIM(p_apellido1),
            APELLIDO2_CONDUCTOR = TRIM(p_apellido2),
            TELEFONO = TRIM(p_telefono),
            TIPO_LICENCIA = UPPER(TRIM(p_tipo_licencia)),
            VENCIMIENTO_LICENCIA = p_vencimiento,
            RUT_EMPRESA = UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', ''))
        WHERE RUT_CONDUCTOR = UPPER(REGEXP_REPLACE(TRIM(p_rut), '\.', ''));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20061, 'No se encontro el conductor a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_CONDUCTOR
        WHERE RUT_CONDUCTOR = UPPER(REGEXP_REPLACE(TRIM(p_rut), '\.', ''));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20062, 'No se encontro el conductor a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20060, 'Ya existe un conductor registrado con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_CONDUCTOR;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_CONDUCTORES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        -- ==================== [MODIFICADO] Se incluye c.TELEFONO ====================
        SELECT c.RUT_CONDUCTOR, c.NOMBRE_CONDUCTOR, c.APELLIDO1_CONDUCTOR, c.APELLIDO2_CONDUCTOR, c.TELEFONO, c.TIPO_LICENCIA, c.VENCIMIENTO_LICENCIA, c.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        -- ============================================================================
        FROM LEHZ_CONDUCTOR c
        INNER JOIN LEHZ_EMPRESA e ON c.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY c.APELLIDO1_CONDUCTOR ASC;
END LEHZ_PS_LISTAR_CONDUCTORES;
/