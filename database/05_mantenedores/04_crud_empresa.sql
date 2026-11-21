ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_EMPRESA(
    p_opcion       IN VARCHAR2,
    -- ==================== [MODIFICADO] RUT y Telefono a VARCHAR2 ====================
    p_rut_empresa  IN VARCHAR2,
    p_razon_social IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    -- ================================================================================
    p_correo       IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_EMPRESA IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        INSERT INTO LEHZ_EMPRESA (RUT_EMPRESA, RAZON_SOCIAL, TELEFONO_EMPRESA, CORREO_ELECTRONICO_EMPRESA)
        VALUES (TRIM(p_rut_empresa), TRIM(p_razon_social), TRIM(p_telefono), LOWER(TRIM(p_correo)));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_EMPRESA
        SET RAZON_SOCIAL = TRIM(p_razon_social),
            TELEFONO_EMPRESA = TRIM(p_telefono),
            CORREO_ELECTRONICO_EMPRESA = LOWER(TRIM(p_correo))
        -- ==================== [MODIFICADO] Comparacion normalizada de RUT ====================
        WHERE RUT_EMPRESA = UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', ''));
        -- =====================================================================================

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 'No se encontro la empresa a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_EMPRESA
        -- ==================== [MODIFICADO] Comparacion normalizada de RUT ====================
        WHERE RUT_EMPRESA = UPPER(REGEXP_REPLACE(TRIM(p_rut_empresa), '\.', ''));
        -- =====================================================================================

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20032, 'No se encontro la empresa a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'Ya existe una empresa registrada con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_EMPRESA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_EMPRESAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT RUT_EMPRESA, RAZON_SOCIAL, TELEFONO_EMPRESA, CORREO_ELECTRONICO_EMPRESA
        FROM LEHZ_EMPRESA
        ORDER BY RAZON_SOCIAL ASC;
END LEHZ_PS_LISTAR_EMPRESAS;
/