ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de crear el mantenedor de pasajeros.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_IUD_PASAJERO(
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
    LOCK TABLE LHAOMRJZ_PASAJERO IN ROW EXCLUSIVE MODE;
    v_rut      := LHAOMRJZ_FN_NORMALIZAR_RUT(p_rut, 'PERSONA');

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        v_telefono := LHAOMRJZ_FN_VALIDAR_TEL_CL(p_telefono, 'PERSONA');
        v_correo   := LOWER(TRIM(p_correo));
        IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
            RAISE_APPLICATION_ERROR(-20160, 'El nombre del pasajero es obligatorio.');
        END IF;
        IF p_apellido1 IS NULL OR TRIM(p_apellido1) = '' THEN
            RAISE_APPLICATION_ERROR(-20160, 'El primer apellido del pasajero es obligatorio.');
        END IF;
        IF v_correo IS NOT NULL
           AND NOT REGEXP_LIKE(v_correo, '^[^@]+@[^@]+\.[^@]{2,}$') THEN
            RAISE_APPLICATION_ERROR(-20160, 'El correo electronico del pasajero no tiene un formato valido (ej. usuario@dominio.cl).');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LHAOMRJZ_PASAJERO (
            RUT_PASAJERO, NOMBRE_PASAJERO, APELLIDO1_PASAJERO, APELLIDO2_PASAJERO,
            TELEFONO, CORREO_ELECTRONICO_PASAJERO
        ) VALUES (
            v_rut, LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_nombre), LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido1),
            LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido2), v_telefono, v_correo
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        UPDATE LHAOMRJZ_PASAJERO
           SET NOMBRE_PASAJERO = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_nombre),
               APELLIDO1_PASAJERO = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido1),
               APELLIDO2_PASAJERO = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido2),
               TELEFONO = v_telefono,
               CORREO_ELECTRONICO_PASAJERO = v_correo
         WHERE RUT_PASAJERO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20161, 'No se encontro el pasajero a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LHAOMRJZ_PASAJERO WHERE RUT_PASAJERO = v_rut;
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
END LHAOMRJZ_PS_IUD_PASAJERO;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_PASAJEROS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT RUT_PASAJERO, NOMBRE_PASAJERO, APELLIDO1_PASAJERO, APELLIDO2_PASAJERO,
        NOMBRE_PASAJERO || ' ' || APELLIDO1_PASAJERO AS NOMBRE_COMPLETO,
        TELEFONO, CORREO_ELECTRONICO_PASAJERO
        FROM LHAOMRJZ_PASAJERO
        ORDER BY APELLIDO1_PASAJERO ASC, APELLIDO2_PASAJERO ASC, NOMBRE_PASAJERO ASC;
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
        SELECT RUT_PASAJERO, NOMBRE_PASAJERO, APELLIDO1_PASAJERO, APELLIDO2_PASAJERO,
               NOMBRE_PASAJERO || ' ' || APELLIDO1_PASAJERO AS NOMBRE_COMPLETO,
               TELEFONO, CORREO_ELECTRONICO_PASAJERO
        FROM LHAOMRJZ_PASAJERO
        ORDER BY APELLIDO1_PASAJERO ASC, APELLIDO2_PASAJERO ASC, NOMBRE_PASAJERO ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_PASAJEROS: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_PASAJEROS;
/
