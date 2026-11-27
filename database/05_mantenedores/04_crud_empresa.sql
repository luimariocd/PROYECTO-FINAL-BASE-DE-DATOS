ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de crear el mantenedor de empresas.
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_EMPRESA(
    p_opcion       IN VARCHAR2,
    p_rut_empresa  IN VARCHAR2,
    p_razon_social IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    p_correo       IN VARCHAR2 DEFAULT NULL
) IS
    v_rut      VARCHAR2(12);
    v_telefono VARCHAR2(20);
BEGIN
    LOCK TABLE LEHZ_EMPRESA IN ROW EXCLUSIVE MODE;
    v_rut      := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa, 'EMPRESA');

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        v_telefono := LEHZ_FN_VALIDAR_TEL_CL(p_telefono, 'EMPRESA');
    END IF;

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF p_razon_social IS NULL OR TRIM(p_razon_social) = '' THEN
            RAISE_APPLICATION_ERROR(-20030, 'La razon social de la empresa es obligatoria.');
        END IF;
        IF p_correo IS NOT NULL
           AND NOT REGEXP_LIKE(LOWER(TRIM(p_correo)), '^[^@]+@[^@]+\.[^@]{2,}$') THEN
            RAISE_APPLICATION_ERROR(-20030, 'El correo electronico de la empresa no tiene un formato valido.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_EMPRESA (RUT_EMPRESA, RAZON_SOCIAL, TELEFONO_EMPRESA, CORREO_ELECTRONICO_EMPRESA)
        VALUES (v_rut, LEHZ_FN_NORMALIZAR_TEXTO(p_razon_social), v_telefono, LOWER(TRIM(p_correo)));

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_razon_social IS NULL OR TRIM(p_razon_social) = '' THEN
            RAISE_APPLICATION_ERROR(-20030, 'La razon social de la empresa es obligatoria.');
        END IF;
        UPDATE LEHZ_EMPRESA
           SET RAZON_SOCIAL = LEHZ_FN_NORMALIZAR_TEXTO(p_razon_social),
               TELEFONO_EMPRESA = v_telefono,
               CORREO_ELECTRONICO_EMPRESA = LOWER(TRIM(p_correo))
         WHERE RUT_EMPRESA = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 'No se encontro la empresa a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20032, 'No se encontro la empresa a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20030, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'Ya existe una empresa registrada con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20032, 'No se puede eliminar la empresa: tiene buses, conductores, mecanicos o terminales asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_EMPRESA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_EMPRESAS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT RUT_EMPRESA, RAZON_SOCIAL, TELEFONO_EMPRESA, CORREO_ELECTRONICO_EMPRESA
        FROM LEHZ_EMPRESA
        ORDER BY RAZON_SOCIAL ASC;
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
        SELECT RUT_EMPRESA, RAZON_SOCIAL, TELEFONO_EMPRESA, CORREO_ELECTRONICO_EMPRESA
        FROM LEHZ_EMPRESA
        ORDER BY RAZON_SOCIAL ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_LISTAR_EMPRESAS: ' || SQLERRM);
END LEHZ_PS_LISTAR_EMPRESAS;
/
