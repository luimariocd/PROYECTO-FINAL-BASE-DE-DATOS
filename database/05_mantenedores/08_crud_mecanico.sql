ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_MECANICO(
    p_opcion       IN VARCHAR2,
    p_rut          IN OUT VARCHAR2,
    p_nombre       IN VARCHAR2 DEFAULT NULL,
    p_apellido1    IN VARCHAR2 DEFAULT NULL,
    p_apellido2    IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    p_especialidad IN VARCHAR2 DEFAULT NULL,
    p_rut_empresa  IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion    VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_rut       VARCHAR2(12);
    v_nombre    VARCHAR2(100);
    v_apellido1 VARCHAR2(80);
    v_apellido2 VARCHAR2(80);
    v_fono      VARCHAR2(16);
    v_especial  VARCHAR2(40);
    v_rut_emp   VARCHAR2(12);
    v_error     VARCHAR2(400);
    v_existe    NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_MECANICO IN ROW EXCLUSIVE MODE;

    v_rut       := LEHZ_FN_NORMALIZAR_RUT(p_rut);
    v_nombre    := LEHZ_FN_TITULO(p_nombre);
    v_apellido1 := LEHZ_FN_TITULO(p_apellido1);
    v_apellido2 := LEHZ_FN_TITULO(p_apellido2);
    v_fono      := LEHZ_FN_NORMALIZAR_TELEFONO(p_telefono);
    v_especial  := LEHZ_FN_TITULO(p_especialidad);
    v_rut_emp   := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa);

    IF v_opcion IN ('I', 'U') THEN
        v_error := LEHZ_FN_ERROR_RUT(v_rut, 'PERSONA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20130, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20131, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_apellido1, 'primer apellido');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20132, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TELEFONO(v_fono, 'PERSONA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20133, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_RUT(v_rut_emp, 'EMPRESA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20134, v_error);
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut_emp;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20135, 'La empresa seleccionada no existe.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        INSERT INTO LEHZ_MECANICO (
            RUT_MECANICO, NOMBRE_MECANICO, APELLIDO1_MECANICO, APELLIDO2_MECANICO,
            TELEFONO_MECANICO, ESPECIALIDAD, RUT_EMPRESA
        ) VALUES (
            v_rut, v_nombre, v_apellido1, v_apellido2,
            v_fono, v_especial, v_rut_emp
        );
        p_rut := v_rut;

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_MECANICO
        SET NOMBRE_MECANICO = v_nombre,
            APELLIDO1_MECANICO = v_apellido1,
            APELLIDO2_MECANICO = v_apellido2,
            TELEFONO_MECANICO = v_fono,
            ESPECIALIDAD = v_especial,
            RUT_EMPRESA = v_rut_emp
        WHERE RUT_MECANICO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20136, 'No se encontro el mecanico a actualizar.');
        END IF;
        p_rut := v_rut;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_MECANICO
        WHERE RUT_MECANICO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20137, 'No se encontro el mecanico a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20138, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20139, 'Ya existe un mecanico registrado con ese RUT.');
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
        SELECT m.RUT_MECANICO,
               m.NOMBRE_MECANICO,
               m.APELLIDO1_MECANICO,
               m.APELLIDO2_MECANICO,
               m.TELEFONO_MECANICO,
               m.ESPECIALIDAD,
               m.RUT_EMPRESA,
               e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_MECANICO m
        INNER JOIN LEHZ_EMPRESA e ON m.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY m.APELLIDO1_MECANICO ASC, m.NOMBRE_MECANICO ASC;
END LEHZ_PS_LISTAR_MECANICOS;
/
