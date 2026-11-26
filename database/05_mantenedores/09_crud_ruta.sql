ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de crear el mantenedor de rutas.
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_RUTA(
    p_opcion              IN VARCHAR2,
    p_id_ruta             IN OUT NUMBER,
    p_nombre_ruta         IN VARCHAR2 DEFAULT NULL,
    p_id_terminal_origen  IN NUMBER DEFAULT NULL,
    p_id_terminal_destino IN NUMBER DEFAULT NULL,
    p_horario             IN TIMESTAMP DEFAULT NULL,
    p_distancia           IN NUMBER DEFAULT NULL,
    p_horas_est           IN NUMBER DEFAULT NULL,
    p_minutos_est         IN NUMBER DEFAULT NULL
) IS
    v_nombre VARCHAR2(120);
    v_count  NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_RUTA IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_NORMALIZAR_TEXTO(p_nombre_ruta);

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF v_nombre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20080, 'El nombre de la ruta es obligatorio.');
        END IF;
        IF p_id_terminal_origen IS NULL OR p_id_terminal_destino IS NULL THEN
            RAISE_APPLICATION_ERROR(-20080, 'Debe indicar el terminal de origen y el de destino.');
        END IF;
        IF p_id_terminal_origen = p_id_terminal_destino THEN
            RAISE_APPLICATION_ERROR(-20080, 'El terminal de origen y destino deben ser diferentes.');
        END IF;
        IF p_distancia IS NULL OR p_distancia <= 0 THEN
            RAISE_APPLICATION_ERROR(-20080, 'La distancia de la ruta debe ser mayor que cero.');
        END IF;
        IF p_horas_est IS NULL OR p_horas_est < 0 THEN
            RAISE_APPLICATION_ERROR(-20080, 'Las horas estimadas deben ser mayores o iguales a cero.');
        END IF;
        IF p_minutos_est IS NULL OR p_minutos_est < 0 OR p_minutos_est >= 60 THEN
            RAISE_APPLICATION_ERROR(-20080, 'Los minutos estimados deben estar entre 0 y 59.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal_origen;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20080, 'El terminal de origen no existe.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal_destino;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20080, 'El terminal de destino no existe.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        p_id_ruta := LEHZ_SEQ_RUTA.NEXTVAL;
        INSERT INTO LEHZ_RUTA (
            ID_RUTA, HORARIO, DISTANCIA, HORAS_ESTIMADAS, MINUTOS_ESTIMADOS,
            NOMBRE_RUTA, ID_TERMINAL_ORIGEN, ID_TERMINAL_DESTINO
        ) VALUES (
            p_id_ruta, p_horario, p_distancia, p_horas_est, p_minutos_est,
            v_nombre, p_id_terminal_origen, p_id_terminal_destino
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_id_ruta IS NULL OR p_id_ruta <= 0 THEN
            RAISE_APPLICATION_ERROR(-20080, 'Debe indicar la ruta a actualizar.');
        END IF;
        UPDATE LEHZ_RUTA
           SET HORARIO = p_horario,
               DISTANCIA = p_distancia,
               HORAS_ESTIMADAS = p_horas_est,
               MINUTOS_ESTIMADOS = p_minutos_est,
               NOMBRE_RUTA = v_nombre,
               ID_TERMINAL_ORIGEN = p_id_terminal_origen,
               ID_TERMINAL_DESTINO = p_id_terminal_destino
         WHERE ID_RUTA = p_id_ruta;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20081, 'No se encontro la ruta a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        IF p_id_ruta IS NULL OR p_id_ruta <= 0 THEN
            RAISE_APPLICATION_ERROR(-20082, 'Debe indicar la ruta a eliminar.');
        END IF;
        DELETE FROM LEHZ_RUTA WHERE ID_RUTA = p_id_ruta;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20082, 'No se encontro la ruta a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20080, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20080, 'Ya existe una ruta con ese identificador.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20082, 'No se puede eliminar la ruta: tiene viajes asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_RUTA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_RUTAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT r.ID_RUTA, r.NOMBRE_RUTA,
               TO_CHAR(r.HORARIO, 'YYYY-MM-DD"T"HH24:MI') AS HORARIO,
               TO_CHAR(r.HORARIO, 'DD/MM/YYYY HH24:MI') AS HORARIO_TEXTO,
               r.DISTANCIA,
               r.HORAS_ESTIMADAS, r.MINUTOS_ESTIMADOS,
               r.ID_TERMINAL_ORIGEN, o.NOMBRE AS TERMINAL_ORIGEN,
               r.ID_TERMINAL_DESTINO, d.NOMBRE AS TERMINAL_DESTINO,
               (SELECT COUNT(*) FROM LEHZ_RUTA_PARADA rp WHERE rp.ID_RUTA = r.ID_RUTA) AS TOTAL_PARADAS
        FROM LEHZ_RUTA r
        INNER JOIN LEHZ_TERMINAL o ON r.ID_TERMINAL_ORIGEN = o.ID_TERMINAL
        INNER JOIN LEHZ_TERMINAL d ON r.ID_TERMINAL_DESTINO = d.ID_TERMINAL
        ORDER BY r.NOMBRE_RUTA ASC;
END LEHZ_PS_LISTAR_RUTAS;
/
