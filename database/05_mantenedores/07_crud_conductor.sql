ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- MANTENEDOR 07: CONDUCTORES
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_CONDUCTOR(
    p_opcion       IN VARCHAR2,
    p_rut          IN VARCHAR2,
    p_nombre       IN VARCHAR2 DEFAULT NULL,
    p_apellido1    IN VARCHAR2 DEFAULT NULL,
    p_apellido2    IN VARCHAR2 DEFAULT NULL,
    p_telefono     IN VARCHAR2 DEFAULT NULL,
    p_tipo_licencia IN VARCHAR2 DEFAULT NULL,
    p_vencimiento  IN DATE DEFAULT NULL,
    p_rut_empresa  IN VARCHAR2 DEFAULT NULL
) IS
    v_rut      VARCHAR2(12);
    v_rut_emp  VARCHAR2(12);
    v_telefono VARCHAR2(20);
    v_count    NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_CONDUCTOR IN ROW EXCLUSIVE MODE;
    v_rut      := LEHZ_FN_NORMALIZAR_RUT(p_rut, 'PERSONA');
    v_rut_emp  := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa, 'EMPRESA');
    v_telefono := LEHZ_FN_VALIDAR_TEL_CL(p_telefono, 'PERSONA');

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
            RAISE_APPLICATION_ERROR(-20060, 'El nombre del conductor es obligatorio.');
        END IF;
        IF p_apellido1 IS NULL OR TRIM(p_apellido1) = '' THEN
            RAISE_APPLICATION_ERROR(-20060, 'El primer apellido del conductor es obligatorio.');
        END IF;
        IF p_vencimiento IS NULL THEN
            RAISE_APPLICATION_ERROR(-20060, 'La fecha de vencimiento de la licencia es obligatoria.');
        END IF;
        IF p_tipo_licencia IS NULL OR UPPER(TRIM(p_tipo_licencia)) NOT IN ('A1', 'A2', 'A3') THEN
            RAISE_APPLICATION_ERROR(-20060, 'Tipo de licencia invalido: debe ser A1, A2 o A3.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut_emp;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20060, 'La empresa seleccionada no existe.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_CONDUCTOR (
            RUT_CONDUCTOR, NOMBRE_CONDUCTOR, APELLIDO1_CONDUCTOR, APELLIDO2_CONDUCTOR,
            TELEFONO, TIPO_LICENCIA, VENCIMIENTO_LICENCIA, RUT_EMPRESA
        ) VALUES (
            v_rut, LEHZ_FN_NORMALIZAR_TEXTO(p_nombre), LEHZ_FN_NORMALIZAR_TEXTO(p_apellido1),
            LEHZ_FN_NORMALIZAR_TEXTO(p_apellido2), v_telefono, UPPER(TRIM(p_tipo_licencia)),
            p_vencimiento, v_rut_emp
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        UPDATE LEHZ_CONDUCTOR
           SET NOMBRE_CONDUCTOR = LEHZ_FN_NORMALIZAR_TEXTO(p_nombre),
               APELLIDO1_CONDUCTOR = LEHZ_FN_NORMALIZAR_TEXTO(p_apellido1),
               APELLIDO2_CONDUCTOR = LEHZ_FN_NORMALIZAR_TEXTO(p_apellido2),
               TELEFONO = v_telefono,
               TIPO_LICENCIA = UPPER(TRIM(p_tipo_licencia)),
               VENCIMIENTO_LICENCIA = p_vencimiento,
               RUT_EMPRESA = v_rut_emp
         WHERE RUT_CONDUCTOR = v_rut;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20061, 'No se encontro el conductor a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_CONDUCTOR WHERE RUT_CONDUCTOR = v_rut;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20062, 'No se encontro el conductor a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20060, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20060, 'Ya existe un conductor registrado con ese RUT.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20062, 'No se puede eliminar el conductor: tiene viajes asignados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_CONDUCTOR;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_CONDUCTORES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT c.RUT_CONDUCTOR, c.NOMBRE_CONDUCTOR, c.APELLIDO1_CONDUCTOR,
               c.APELLIDO2_CONDUCTOR, c.TELEFONO, c.TIPO_LICENCIA,
               TO_CHAR(c.VENCIMIENTO_LICENCIA, 'YYYY-MM-DD') AS VENCIMIENTO_LICENCIA,
               TO_CHAR(c.VENCIMIENTO_LICENCIA, 'DD/MM/YYYY') AS VENCIMIENTO_TEXTO,
               c.RUT_EMPRESA,
               e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_CONDUCTOR c
        INNER JOIN LEHZ_EMPRESA e ON c.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY c.APELLIDO1_CONDUCTOR ASC, c.APELLIDO2_CONDUCTOR ASC;
END LEHZ_PS_LISTAR_CONDUCTORES;
/
