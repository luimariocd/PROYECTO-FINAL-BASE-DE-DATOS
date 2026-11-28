ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de programar viajes a partir de horarios y rutas.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_GES_PROGRAMAR_VIAJE(
    p_fecha_viaje  IN DATE,
    p_id_horario   IN NUMBER,
    p_id_ruta      IN NUMBER,
    p_id_viaje_out OUT NUMBER
) IS
    v_count NUMBER := 0;
BEGIN
    LOCK TABLE LHAOMRJZ_VIAJE IN EXCLUSIVE MODE;

    IF p_fecha_viaje IS NULL THEN
        RAISE_APPLICATION_ERROR(-20110, 'La fecha del viaje es obligatoria.');
    END IF;
    IF TRUNC(p_fecha_viaje) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20110, 'La fecha del viaje no puede ser anterior a hoy.');
    END IF;
    IF p_id_horario IS NULL OR p_id_horario <= 0 THEN
        RAISE_APPLICATION_ERROR(-20110, 'Debe seleccionar un horario valido.');
    END IF;
    IF p_id_ruta IS NULL OR p_id_ruta <= 0 THEN
        RAISE_APPLICATION_ERROR(-20110, 'Debe seleccionar una ruta valida.');
    END IF;

    v_count := LHAOMRJZ_FN_EXISTE_RUTA(p_id_ruta);
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20111, 'La ruta especificada no existe.');
    END IF;

    v_count := LHAOMRJZ_FN_EXISTE_HORARIO(p_id_horario);
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20112, 'El horario especificado no existe.');
    END IF;

    v_count := LHAOMRJZ_FN_VIAJE_DUPLICADO(p_fecha_viaje, p_id_horario, p_id_ruta);    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20113, 'Ya existe un viaje programado para esa ruta, fecha y horario.');
    END IF;

    p_id_viaje_out := LHAOMRJZ_SEQ_VIAJE.NEXTVAL;

    INSERT INTO LHAOMRJZ_VIAJE (ID_VIAJE, FECHA_VIAJE, ID_HORARIO, ID_RUTA)
    VALUES (p_id_viaje_out, TRUNC(p_fecha_viaje), p_id_horario, p_id_ruta);

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20113, 'Ya existe un viaje programado para esa ruta, fecha y horario.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LHAOMRJZ_PS_GES_PROGRAMAR_VIAJE;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_VIAJES(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT v.ID_VIAJE,
        TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
        v.FECHA_VIAJE AS FECHA_ORDEN,
        v.ID_HORARIO,
        TO_CHAR(h.HORA_SALIDA, 'HH24:MI') AS HORA_SALIDA,
        TO_CHAR(h.HORA_LLEGADA, 'HH24:MI') AS HORA_LLEGADA,
        v.ID_RUTA, r.NOMBRE_RUTA,
        o.NOMBRE AS TERMINAL_ORIGEN,
        d.NOMBRE AS TERMINAL_DESTINO,
        r.DISTANCIA,
        (SELECT COUNT(DISTINCT c.PATENTE_BUS)
        FROM LHAOMRJZ_CONDUCE c
        WHERE c.ID_VIAJE = v.ID_VIAJE) AS TOTAL_BUSES,
        (SELECT COUNT(*)
        FROM LHAOMRJZ_BOLETO b
        WHERE b.ID_VIAJE = v.ID_VIAJE
        AND b.ESTADO IN ('EMITIDO', 'USADO')) AS BOLETOS_ACTIVOS
        FROM LHAOMRJZ_VIAJE v
        INNER JOIN LHAOMRJZ_HORARIO h ON h.ID_HORARIO = v.ID_HORARIO
        INNER JOIN LHAOMRJZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
        INNER JOIN LHAOMRJZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO
        ORDER BY v.FECHA_VIAJE DESC, h.HORA_SALIDA ASC;
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
        SELECT v.ID_VIAJE,
               TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
               v.FECHA_VIAJE AS FECHA_ORDEN,
               v.ID_HORARIO,
               TO_CHAR(h.HORA_SALIDA, 'HH24:MI') AS HORA_SALIDA,
               TO_CHAR(h.HORA_LLEGADA, 'HH24:MI') AS HORA_LLEGADA,
               v.ID_RUTA, r.NOMBRE_RUTA,
               o.NOMBRE AS TERMINAL_ORIGEN,
               d.NOMBRE AS TERMINAL_DESTINO,
               r.DISTANCIA,
               (SELECT COUNT(DISTINCT c.PATENTE_BUS)
                  FROM LHAOMRJZ_CONDUCE c
                 WHERE c.ID_VIAJE = v.ID_VIAJE) AS TOTAL_BUSES,
               (SELECT COUNT(*)
                  FROM LHAOMRJZ_BOLETO b
                 WHERE b.ID_VIAJE = v.ID_VIAJE
                   AND b.ESTADO IN ('EMITIDO', 'USADO')) AS BOLETOS_ACTIVOS
        FROM LHAOMRJZ_VIAJE v
        INNER JOIN LHAOMRJZ_HORARIO h ON h.ID_HORARIO = v.ID_HORARIO
        INNER JOIN LHAOMRJZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
        INNER JOIN LHAOMRJZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO
        ORDER BY v.FECHA_VIAJE DESC, h.HORA_SALIDA ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_VIAJES: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_VIAJES;
/
