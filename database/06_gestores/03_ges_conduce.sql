ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- GESTOR 03: ASIGNACION DE CONDUCTOR, BUS Y VIAJE
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ASIGNAR_CONDUCE(
    p_rut_conductor IN VARCHAR2,
    p_patente_bus   IN VARCHAR2,
    p_id_viaje      IN NUMBER,
    p_opcion        IN VARCHAR2 DEFAULT 'I'
) IS
    v_rut     VARCHAR2(12);
    v_patente VARCHAR2(8);
    v_count   NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_CONDUCE IN EXCLUSIVE MODE;
    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_conductor, 'PERSONA');
    v_patente := LEHZ_FN_NORMALIZAR_PATENTE(p_patente_bus);

    IF p_id_viaje IS NULL OR p_id_viaje <= 0 THEN
        RAISE_APPLICATION_ERROR(-20120, 'Debe seleccionar un viaje valido.');
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        SELECT COUNT(*) INTO v_count FROM LEHZ_CONDUCTOR WHERE RUT_CONDUCTOR = v_rut;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20121, 'El conductor no existe.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM LEHZ_BUS WHERE PATENTE_BUS = v_patente;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20122, 'El bus no existe.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM LEHZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20123, 'El viaje no existe.');
        END IF;

        INSERT INTO LEHZ_CONDUCE (RUT_CONDUCTOR, PATENTE_BUS, ID_VIAJE)
        VALUES (v_rut, v_patente, p_id_viaje);

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_CONDUCE
         WHERE RUT_CONDUCTOR = v_rut
           AND PATENTE_BUS = v_patente
           AND ID_VIAJE = p_id_viaje;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20125, 'No se encontro la asignacion a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20120, 'Operacion invalida. Use I o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20124, 'Este conductor o bus ya se encuentra asignado a este viaje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ASIGNAR_CONDUCE;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_CONDUCE(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT c.RUT_CONDUCTOR,
               co.NOMBRE_CONDUCTOR || ' ' || co.APELLIDO1_CONDUCTOR AS CONDUCTOR,
               c.PATENTE_BUS, b.MARCA || ' ' || b.MODELO AS BUS,
               c.ID_VIAJE, TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
               r.NOMBRE_RUTA,
               TO_CHAR(h.HORA_SALIDA, 'HH24:MI') AS HORA_SALIDA
        FROM LEHZ_CONDUCE c
        INNER JOIN LEHZ_CONDUCTOR co ON co.RUT_CONDUCTOR = c.RUT_CONDUCTOR
        INNER JOIN LEHZ_BUS b ON b.PATENTE_BUS = c.PATENTE_BUS
        INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = c.ID_VIAJE
        INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        INNER JOIN LEHZ_HORARIO h ON h.ID_HORARIO = v.ID_HORARIO
        ORDER BY v.FECHA_VIAJE DESC, h.HORA_SALIDA ASC;
END LEHZ_PS_LISTAR_CONDUCE;
/
