ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_EMPRESA(
    p_opcion       IN VARCHAR2,
    p_rut_empresa  IN OUT VARCHAR2,
    p_razon_social IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    p_correo       IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion  VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_rut     VARCHAR2(12);
    v_nombre  VARCHAR2(120);
    v_fono    VARCHAR2(16);
    v_correo  VARCHAR2(80);
    v_error   VARCHAR2(400);
BEGIN
    LOCK TABLE LEHZ_EMPRESA IN ROW EXCLUSIVE MODE;

    v_rut    := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa);
    v_nombre := LEHZ_FN_TITULO(p_razon_social);
    v_fono   := LEHZ_FN_NORMALIZAR_TELEFONO(p_telefono);
    v_correo := LOWER(TRIM(p_correo));

    IF v_opcion IN ('I', 'U') THEN
        v_error := LEHZ_FN_ERROR_RUT(v_rut, 'EMPRESA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20080, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'razon social');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20081, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TELEFONO(v_fono, 'EMPRESA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20082, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_EMAIL(v_correo, 'N');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20083, v_error);
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        INSERT INTO LEHZ_EMPRESA (RUT_EMPRESA, RAZON_SOCIAL, TELEFONO_EMPRESA, CORREO_ELECTRONICO_EMPRESA)
        VALUES (v_rut, v_nombre, v_fono, v_correo);
        p_rut_empresa := v_rut;

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_EMPRESA
        SET RAZON_SOCIAL = v_nombre,
            TELEFONO_EMPRESA = v_fono,
            CORREO_ELECTRONICO_EMPRESA = v_correo
        WHERE RUT_EMPRESA = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20084, 'No se encontro la empresa a actualizar.');
        END IF;
        p_rut_empresa := v_rut;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_EMPRESA
        WHERE RUT_EMPRESA = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20085, 'No se encontro la empresa a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20086, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20087, 'Ya existe una empresa registrada con ese RUT.');
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
        SELECT e.RUT_EMPRESA,
               e.RAZON_SOCIAL,
               e.TELEFONO_EMPRESA,
               e.CORREO_ELECTRONICO_EMPRESA,
               (SELECT COUNT(*) FROM LEHZ_BUS b WHERE b.RUT_EMPRESA = e.RUT_EMPRESA) AS TOTAL_BUSES
        FROM LEHZ_EMPRESA e
        ORDER BY e.RAZON_SOCIAL ASC;
END LEHZ_PS_LISTAR_EMPRESAS;
/
