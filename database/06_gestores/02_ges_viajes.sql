ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_PROGRAMAR_VIAJE(
    p_fecha_viaje  IN DATE,
    p_id_horario   IN NUMBER,
    p_id_ruta      IN NUMBER,
    p_id_viaje_out OUT NUMBER
) IS
    v_existe NUMBER := 0;
    v_dup    NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_VIAJE IN EXCLUSIVE MODE;

    IF p_fecha_viaje IS NULL THEN
        RAISE_APPLICATION_ERROR(-20240, 'La fecha del viaje es obligatoria.');
    END IF;

    IF p_fecha_viaje < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20241, 'No se puede programar un viaje en una fecha pasada.');
    END IF;

    SELECT COUNT(*) INTO v_existe FROM LEHZ_RUTA WHERE ID_RUTA = p_id_ruta;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20242, 'La ruta especificada no existe.');
    END IF;

    SELECT COUNT(*) INTO v_existe FROM LEHZ_HORARIO WHERE ID_HORARIO = p_id_horario;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20243, 'El horario especificado no existe.');
    END IF;

    SELECT COUNT(*) INTO v_dup
    FROM LEHZ_VIAJE
    WHERE FECHA_VIAJE = p_fecha_viaje
      AND ID_HORARIO = p_id_horario
      AND ID_RUTA = p_id_ruta;

    IF v_dup > 0 THEN
        RAISE_APPLICATION_ERROR(-20244,
            'Ya existe un viaje programado para esa fecha, horario y ruta.');
    END IF;

    p_id_viaje_out := LEHZ_SEQ_VIAJE.NEXTVAL;

    INSERT INTO LEHZ_VIAJE (ID_VIAJE, FECHA_VIAJE, ID_HORARIO, ID_RUTA)
    VALUES (p_id_viaje_out, p_fecha_viaje, p_id_horario, p_id_ruta);

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20244,
            'Ya existe un viaje programado para esa fecha, horario y ruta.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_PROGRAMAR_VIAJE;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_VIAJES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT v.ID_VIAJE,
               TO_CHAR(v.FECHA_VIAJE, 'YYYY-MM-DD') AS FECHA_VIAJE,
               v.ID_HORARIO,
               h.HORARIO AS CODIGO_HORARIO,
               v.ID_RUTA,
               LEHZ_FN_DETALLE_RUTA(v.ID_RUTA) AS TRAYECTO,
               r.DISTANCIA,
               NVL(b.PATENTE_BUS, 'SIN ASIGNAR') AS PATENTE_BUS
        FROM LEHZ_VIAJE v
        INNER JOIN LEHZ_HORARIO h ON h.ID_HORARIO = v.ID_HORARIO
        INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        LEFT JOIN (
            SELECT ID_VIAJE, MIN(PATENTE_BUS) AS PATENTE_BUS
            FROM LEHZ_CONDUCE
            GROUP BY ID_VIAJE
        ) b ON b.ID_VIAJE = v.ID_VIAJE
        ORDER BY v.FECHA_VIAJE DESC, v.ID_VIAJE DESC;
END LEHZ_PS_LISTAR_VIAJES;
/
