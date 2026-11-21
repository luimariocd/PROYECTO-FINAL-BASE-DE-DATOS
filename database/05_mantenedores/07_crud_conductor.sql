ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_CONDUCTOR(
    p_opcion        IN VARCHAR2,
    p_rut           IN OUT VARCHAR2,
    p_nombre        IN VARCHAR2 DEFAULT NULL,
    p_apellido1     IN VARCHAR2 DEFAULT NULL,
    p_apellido2     IN VARCHAR2 DEFAULT NULL,
    p_telefono      IN VARCHAR2 DEFAULT NULL,
    p_tipo_licencia IN VARCHAR2 DEFAULT NULL,
    p_vencimiento   IN DATE DEFAULT NULL,
    p_rut_empresa   IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion    VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_rut       VARCHAR2(12);
    v_nombre    VARCHAR2(100);
    v_apellido1 VARCHAR2(80);
    v_apellido2 VARCHAR2(80);
    v_fono      VARCHAR2(16);
    v_licencia  VARCHAR2(5);
    v_rut_emp   VARCHAR2(12);
    v_error     VARCHAR2(400);
    v_existe    NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_CONDUCTOR IN ROW EXCLUSIVE MODE;

    v_rut       := LEHZ_FN_NORMALIZAR_RUT(p_rut);
    v_nombre    := LEHZ_FN_TITULO(p_nombre);
    v_apellido1 := LEHZ_FN_TITULO(p_apellido1);
    v_apellido2 := LEHZ_FN_TITULO(p_apellido2);
    v_fono      := LEHZ_FN_NORMALIZAR_TELEFONO(p_telefono);
    v_licencia  := UPPER(TRIM(p_tipo_licencia));
    v_rut_emp   := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa);

    IF v_opcion IN ('I', 'U') THEN
        v_error := LEHZ_FN_ERROR_RUT(v_rut, 'PERSONA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20110, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20111, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_apellido1, 'primer apellido');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20112, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TELEFONO(v_fono, 'PERSONA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20113, v_error);
        END IF;

        IF v_licencia IS NULL THEN
            RAISE_APPLICATION_ERROR(-20114, 'El tipo de licencia es obligatorio. Ejemplo: A3.');
        END IF;

        IF p_vencimiento IS NULL THEN
            RAISE_APPLICATION_ERROR(-20115, 'La fecha de vencimiento de la licencia es obligatoria.');
        END IF;

        IF p_vencimiento < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20116, 'La licencia del conductor se encuentra vencida.');
        END IF;

        v_error := LEHZ_FN_ERROR_RUT(v_rut_emp, 'EMPRESA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20117, v_error);
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut_emp;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20118, 'La empresa seleccionada no existe.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        INSERT INTO LEHZ_CONDUCTOR (
            RUT_CONDUCTOR, NOMBRE_CONDUCTOR, APELLIDO1_CONDUCTOR, APELLIDO2_CONDUCTOR,
            TELEFONO_CONDUCTOR, TIPO_LICENCIA, VENCIMIENTO_LICENCIA, RUT_EMPRESA
        ) VALUES (
            v_rut, v_nombre, v_apellido1, v_apellido2,
            v_fono, v_licencia, p_vencimiento, v_rut_emp
        );
        p_rut := v_rut;

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_CONDUCTOR
        SET NOMBRE_CONDUCTOR = v_nombre,
            APELLIDO1_CONDUCTOR = v_apellido1,
            APELLIDO2_CONDUCTOR = v_apellido2,
            TELEFONO_CONDUCTOR = v_fono,
            TIPO_LICENCIA = v_licencia,
            VENCIMIENTO_LICENCIA = p_vencimiento,
            RUT_EMPRESA = v_rut_emp
        WHERE RUT_CONDUCTOR = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20119, 'No se encontro el conductor a actualizar.');
        END IF;
        p_rut := v_rut;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_CONDUCTOR
        WHERE RUT_CONDUCTOR = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20120, 'No se encontro el conductor a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20121, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20122, 'Ya existe un conductor registrado con ese RUT.');
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
        SELECT c.RUT_CONDUCTOR,
               c.NOMBRE_CONDUCTOR,
               c.APELLIDO1_CONDUCTOR,
               c.APELLIDO2_CONDUCTOR,
               c.TELEFONO_CONDUCTOR,
               c.TIPO_LICENCIA,
               TO_CHAR(c.VENCIMIENTO_LICENCIA, 'YYYY-MM-DD') AS VENCIMIENTO_LICENCIA,
               c.RUT_EMPRESA,
               e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_CONDUCTOR c
        INNER JOIN LEHZ_EMPRESA e ON c.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY c.APELLIDO1_CONDUCTOR ASC, c.NOMBRE_CONDUCTOR ASC;
END LEHZ_PS_LISTAR_CONDUCTORES;
/
