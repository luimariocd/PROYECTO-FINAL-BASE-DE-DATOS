ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_PASAJERO(
    p_opcion    IN VARCHAR2,
    p_rut       IN OUT VARCHAR2,
    p_nombre    IN VARCHAR2 DEFAULT NULL,
    p_apellido1 IN VARCHAR2 DEFAULT NULL,
    p_apellido2 IN VARCHAR2 DEFAULT NULL,
    p_telefono  IN VARCHAR2 DEFAULT NULL,
    p_correo    IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion    VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_rut       VARCHAR2(12);
    v_nombre    VARCHAR2(100);
    v_apellido1 VARCHAR2(80);
    v_apellido2 VARCHAR2(80);
    v_fono      VARCHAR2(16);
    v_correo    VARCHAR2(80);
    v_error     VARCHAR2(400);
BEGIN
    LOCK TABLE LEHZ_PASAJERO IN ROW EXCLUSIVE MODE;

    v_rut       := LEHZ_FN_NORMALIZAR_RUT(p_rut);
    v_nombre    := LEHZ_FN_TITULO(p_nombre);
    v_apellido1 := LEHZ_FN_TITULO(p_apellido1);
    v_apellido2 := LEHZ_FN_TITULO(p_apellido2);
    v_fono      := LEHZ_FN_NORMALIZAR_TELEFONO(p_telefono);
    v_correo    := LOWER(TRIM(p_correo));

    IF v_opcion IN ('I', 'U') THEN
        v_error := LEHZ_FN_ERROR_RUT(v_rut, 'PERSONA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20180, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20181, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_apellido1, 'primer apellido');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20182, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_TELEFONO(v_fono, 'PERSONA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20183, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_EMAIL(v_correo, 'N');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20184, v_error);
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        INSERT INTO LEHZ_PASAJERO (
            RUT_PASAJERO, NOMBRE_PASAJERO, APELLIDO1_PASAJERO, APELLIDO2_PASAJERO,
            TELEFONO_PASAJERO, CORREO_ELECTRONICO_PASAJERO
        ) VALUES (
            v_rut, v_nombre, v_apellido1, v_apellido2, v_fono, v_correo
        );
        p_rut := v_rut;

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_PASAJERO
        SET NOMBRE_PASAJERO = v_nombre,
            APELLIDO1_PASAJERO = v_apellido1,
            APELLIDO2_PASAJERO = v_apellido2,
            TELEFONO_PASAJERO = v_fono,
            CORREO_ELECTRONICO_PASAJERO = v_correo
        WHERE RUT_PASAJERO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20185, 'No se encontro el pasajero a actualizar.');
        END IF;
        p_rut := v_rut;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_PASAJERO
        WHERE RUT_PASAJERO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20186, 'No se encontro el pasajero a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20187, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20188, 'Ya existe un pasajero registrado con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20189,
                'No se puede eliminar el pasajero porque tiene boletos o pagos asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_PASAJERO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_PASAJEROS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT RUT_PASAJERO,
               NOMBRE_PASAJERO,
               APELLIDO1_PASAJERO,
               APELLIDO2_PASAJERO,
               TELEFONO_PASAJERO,
               CORREO_ELECTRONICO_PASAJERO,
               NOMBRE_PASAJERO || ' ' || APELLIDO1_PASAJERO ||
                   NVL(' ' || APELLIDO2_PASAJERO, '') AS NOMBRE_COMPLETO
        FROM LEHZ_PASAJERO
        ORDER BY APELLIDO1_PASAJERO ASC, NOMBRE_PASAJERO ASC;
END LEHZ_PS_LISTAR_PASAJEROS;
/
