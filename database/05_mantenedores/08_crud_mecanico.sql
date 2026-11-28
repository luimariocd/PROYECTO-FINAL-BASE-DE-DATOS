ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de crear el mantenedor de mecanicos.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_IUD_MECANICO(
    p_opcion       IN VARCHAR2,
    p_rut          IN VARCHAR2,
    p_nombre       IN VARCHAR2 DEFAULT NULL,
    p_apellido1    IN VARCHAR2 DEFAULT NULL,
    p_apellido2    IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    p_especialidad IN VARCHAR2 DEFAULT NULL,
    p_rut_empresa  IN VARCHAR2 DEFAULT NULL
) IS
    v_rut      VARCHAR2(12);
    v_rut_emp  VARCHAR2(12);
    v_telefono VARCHAR2(20);
    v_count    NUMBER := 0;
BEGIN
    LOCK TABLE LHAOMRJZ_MECANICO IN ROW EXCLUSIVE MODE;
    v_rut      := LHAOMRJZ_FN_NORMALIZAR_RUT(p_rut, 'PERSONA');

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        v_rut_emp  := LHAOMRJZ_FN_NORMALIZAR_RUT(p_rut_empresa, 'EMPRESA');
        v_telefono := LHAOMRJZ_FN_VALIDAR_TEL_CL(p_telefono, 'PERSONA');
        IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
            RAISE_APPLICATION_ERROR(-20070, 'El nombre del mecanico es obligatorio.');
        END IF;
        IF p_apellido1 IS NULL OR TRIM(p_apellido1) = '' THEN
            RAISE_APPLICATION_ERROR(-20070, 'El primer apellido del mecanico es obligatorio.');
        END IF;
        IF p_especialidad IS NULL OR TRIM(p_especialidad) = '' THEN
            RAISE_APPLICATION_ERROR(-20070, 'La especialidad del mecanico es obligatoria.');
        END IF;
        v_count := LHAOMRJZ_FN_EXISTE_EMPRESA(v_rut_emp);
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20070, 'La empresa seleccionada no existe.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LHAOMRJZ_MECANICO (
            RUT_MECANICO, NOMBRE_MECANICO, APELLIDO1_MECANICO, APELLIDO2_MECANICO,
            TELEFONO, ESPECIALIDAD, RUT_EMPRESA
        ) VALUES (
            v_rut, LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_nombre), LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido1),
            LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido2), v_telefono,
            LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_especialidad), v_rut_emp
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        UPDATE LHAOMRJZ_MECANICO
           SET NOMBRE_MECANICO = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_nombre),
               APELLIDO1_MECANICO = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido1),
               APELLIDO2_MECANICO = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_apellido2),
               TELEFONO = v_telefono,
               ESPECIALIDAD = LHAOMRJZ_FN_NORMALIZAR_TEXTO(p_especialidad),
               RUT_EMPRESA = v_rut_emp
         WHERE RUT_MECANICO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20071, 'No se encontro el mecanico a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LHAOMRJZ_MECANICO WHERE RUT_MECANICO = v_rut;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20072, 'No se encontro el mecanico a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20070, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20070, 'Ya existe un mecanico registrado con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20072, 'No se puede eliminar el mecanico: tiene mantenciones registradas.');
        END IF;
        RAISE;
END LHAOMRJZ_PS_IUD_MECANICO;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_MECANICOS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT m.RUT_MECANICO, m.NOMBRE_MECANICO, m.APELLIDO1_MECANICO,
        m.APELLIDO2_MECANICO, m.TELEFONO, m.ESPECIALIDAD,
        m.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LHAOMRJZ_MECANICO m
        INNER JOIN LHAOMRJZ_EMPRESA e ON m.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY m.APELLIDO1_MECANICO ASC, m.APELLIDO2_MECANICO ASC;
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
        SELECT m.RUT_MECANICO, m.NOMBRE_MECANICO, m.APELLIDO1_MECANICO,
               m.APELLIDO2_MECANICO, m.TELEFONO, m.ESPECIALIDAD,
               m.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LHAOMRJZ_MECANICO m
        INNER JOIN LHAOMRJZ_EMPRESA e ON m.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY m.APELLIDO1_MECANICO ASC, m.APELLIDO2_MECANICO ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_MECANICOS: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_MECANICOS;
/
