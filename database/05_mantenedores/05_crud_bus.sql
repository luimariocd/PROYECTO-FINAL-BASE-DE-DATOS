ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_BUS(
    p_opcion      IN VARCHAR2,
    p_patente     IN VARCHAR2,
    p_marca       IN VARCHAR2 DEFAULT NULL,
    p_modelo      IN VARCHAR2 DEFAULT NULL,
    p_anio        IN NUMBER DEFAULT NULL,
    p_capacidad   IN NUMBER DEFAULT NULL,
    -- ==================== [MODIFICADO] RUT_EMPRESA a VARCHAR2 ====================
    p_rut_empresa IN VARCHAR2 DEFAULT NULL
    -- =============================================================================
) IS
BEGIN
    LOCK TABLE LEHZ_BUS IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        INSERT INTO LEHZ_BUS (PATENTE_BUS, MARCA, MODELO, AÑO_FABRICACION, CAPACIDAD, RUT_EMPRESA)
        VALUES (UPPER(TRIM(p_patente)), INITCAP(TRIM(p_marca)), INITCAP(TRIM(p_modelo)), p_anio, p_capacidad, UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', '')));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_BUS
        SET MARCA = INITCAP(TRIM(p_marca)),
            MODELO = INITCAP(TRIM(p_modelo)),
            AÑO_FABRICACION = p_anio,
            CAPACIDAD = p_capacidad,
            RUT_EMPRESA = UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', ''))
        WHERE PATENTE_BUS = UPPER(TRIM(p_patente));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20041, 'No se encontro el bus a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_BUS
        WHERE PATENTE_BUS = UPPER(TRIM(p_patente));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20042, 'No se encontro el bus a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20040, 'Ya existe un bus registrado con esa patente.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_BUS;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_BUSES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT b.PATENTE_BUS, b.MARCA, b.MODELO, b.AÑO_FABRICACION, b.CAPACIDAD, b.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_BUS b
        INNER JOIN LEHZ_EMPRESA e ON b.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY b.PATENTE_BUS ASC;
END LEHZ_PS_LISTAR_BUSES;
/