ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- MANTENEDOR 12: PASAJEROS
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_PASAJERO(
    p_opcion      IN VARCHAR2,
    p_rut         IN VARCHAR2,
    p_nombre      IN VARCHAR2 DEFAULT NULL,
    p_apellido1   IN VARCHAR2 DEFAULT NULL,
    p_apellido2   IN VARCHAR2 DEFAULT NULL,
    p_telefono    IN VARCHAR2 DEFAULT NULL,
    p_correo      IN VARCHAR2 DEFAULT NULL
) IS
    v_rut      VARCHAR2(12);
    v_telefono VARCHAR2(20);
    v_correo   VARCHAR2(80);
BEGIN
    LOCK TABLE LEHZ_PASAJERO IN ROW EXCLUSIVE MODE;
    v_rut      := LEHZ_FN_NORMALIZAR_RUT(p_rut, 'PERSONA');
    v_telefono := LEHZ_FN_VALIDAR_TEL_CL(p_telefono, 'PERSONA');
    v_correo   := LOWER(TRIM(p_correo));

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
            RAISE_APPLICATION_ERROR(-20160, 'El nombre del pasajero es obligatorio.');
        END IF;
        IF p_apellido1 IS NULL OR TRIM(p_apellido1) = '' THEN
            RAISE_APPLICATION_ERROR(-20160, 'El primer apellido del pasajero es obligatorio.');
        END IF;
        IF v_correo IS NOT NULL AND v_correo <> ''
           AND NOT REGEXP_LIKE(v_correo, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RAISE_APPLICATION_ERROR(-20160, 'El correo electronico del pasajero no tiene un formato valido (ej. usuario@dominio.cl).');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_PASAJERO (
            RUT_PASAJERO, NOMBRE_PASAJERO, APELLIDO1_PASAJERO, APELLIDO2_PASAJERO,
            TELEFONO, CORREO_ELECTRONICO_PASAJERO
        ) VALUES (
            v_rut, LEHZ_FN_NORMALIZAR_TEXTO(p_nombre), LEHZ_FN_NORMALIZAR_TEXTO(p_apellido1),
            LEHZ_FN_NORMALIZAR_TEXTO(p_apellido2), v_telefono, v_correo
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        UPDATE LEHZ_PASAJERO
           SET NOMBRE_PASAJERO = LEHZ_FN_NORMALIZAR_TEXTO(p_nombre),
               APELLIDO1_PASAJERO = LEHZ_FN_NORMALIZAR_TEXTO(p_apellido1),
               APELLIDO2_PASAJERO = LEHZ_FN_NORMALIZAR_TEXTO(p_apellido2),
               TELEFONO = v_telefono,
               CORREO_ELECTRONICO_PASAJERO = v_correo
         WHERE RUT_PASAJERO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20161, 'No se encontro el pasajero a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_PASAJERO WHERE RUT_PASAJERO = v_rut;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20162, 'No se encontro el pasajero a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20160, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20160, 'Ya existe un pasajero registrado con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20162, 'No se puede eliminar el pasajero: tiene boletos o pagos asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_PASAJERO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_PASAJEROS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT RUT_PASAJERO, NOMBRE_PASAJERO, APELLIDO1_PASAJERO, APELLIDO2_PASAJERO,
               NOMBRE_PASAJERO || ' ' || APELLIDO1_PASAJERO AS NOMBRE_COMPLETO,
               TELEFONO, CORREO_ELECTRONICO_PASAJERO
        FROM LEHZ_PASAJERO
        ORDER BY APELLIDO1_PASAJERO ASC, APELLIDO2_PASAJERO ASC, NOMBRE_PASAJERO ASC;
END LEHZ_PS_LISTAR_PASAJEROS;
/
