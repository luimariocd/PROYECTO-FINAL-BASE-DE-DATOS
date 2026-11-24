ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- MANTENEDOR 08: MECANICOS
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_MECANICO(
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
    LOCK TABLE LEHZ_MECANICO IN ROW EXCLUSIVE MODE;
    v_rut      := LEHZ_FN_NORMALIZAR_RUT(p_rut, 'PERSONA');
    v_rut_emp  := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa, 'EMPRESA');
    v_telefono := LEHZ_FN_VALIDAR_TEL_CL(p_telefono, 'PERSONA');

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
            RAISE_APPLICATION_ERROR(-20070, 'El nombre del mecanico es obligatorio.');
        END IF;
        IF p_apellido1 IS NULL OR TRIM(p_apellido1) = '' THEN
            RAISE_APPLICATION_ERROR(-20070, 'El primer apellido del mecanico es obligatorio.');
        END IF;
        IF p_especialidad IS NULL OR TRIM(p_especialidad) = '' THEN
            RAISE_APPLICATION_ERROR(-20070, 'La especialidad del mecanico es obligatoria.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut_emp;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20070, 'La empresa seleccionada no existe.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_MECANICO (
            RUT_MECANICO, NOMBRE_MECANICO, APELLIDO1_MECANICO, APELLIDO2_MECANICO,
            TELEFONO, ESPECIALIDAD, RUT_EMPRESA
        ) VALUES (
            v_rut, LEHZ_FN_NORMALIZAR_TEXTO(p_nombre), LEHZ_FN_NORMALIZAR_TEXTO(p_apellido1),
            LEHZ_FN_NORMALIZAR_TEXTO(p_apellido2), v_telefono,
            LEHZ_FN_NORMALIZAR_TEXTO(p_especialidad), v_rut_emp
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        UPDATE LEHZ_MECANICO
           SET NOMBRE_MECANICO = LEHZ_FN_NORMALIZAR_TEXTO(p_nombre),
               APELLIDO1_MECANICO = LEHZ_FN_NORMALIZAR_TEXTO(p_apellido1),
               APELLIDO2_MECANICO = LEHZ_FN_NORMALIZAR_TEXTO(p_apellido2),
               TELEFONO = v_telefono,
               ESPECIALIDAD = LEHZ_FN_NORMALIZAR_TEXTO(p_especialidad),
               RUT_EMPRESA = v_rut_emp
         WHERE RUT_MECANICO = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20071, 'No se encontro el mecanico a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_MECANICO WHERE RUT_MECANICO = v_rut;
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
END LEHZ_PS_IUD_MECANICO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_MECANICOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT m.RUT_MECANICO, m.NOMBRE_MECANICO, m.APELLIDO1_MECANICO,
               m.APELLIDO2_MECANICO, m.TELEFONO, m.ESPECIALIDAD,
               m.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_MECANICO m
        INNER JOIN LEHZ_EMPRESA e ON m.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY m.APELLIDO1_MECANICO ASC, m.APELLIDO2_MECANICO ASC;
END LEHZ_PS_LISTAR_MECANICOS;
/
