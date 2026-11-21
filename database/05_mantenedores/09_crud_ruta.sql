ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- -------------------------------------------------------------------------
-- Funcion que devuelve el recorrido completo de una ruta con sus paradas.
-- Ejemplo: Talca -> Curico -> San Fernando -> Rengo -> Rancagua -> Santiago
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_DETALLE_RUTA(p_id_ruta IN NUMBER) RETURN VARCHAR2 IS
    v_detalle VARCHAR2(4000);
BEGIN
    -- El origen siempre va primero y el destino siempre va al final.
    -- Las paradas intermedias se ordenan por ORDEN. Si una parada coincide
    -- con el origen o el destino, se omite para no duplicar la ciudad.
    SELECT LISTAGG(t.NOMBRE_COMUNA, ' -> ')
               WITHIN GROUP (ORDER BY t.ORDEN, t.NOMBRE_COMUNA)
    INTO v_detalle
    FROM (
        SELECT co.NOMBRE_COMUNA AS NOMBRE_COMUNA, 0 AS ORDEN
        FROM LEHZ_RUTA r
        INNER JOIN LEHZ_COMUNA co ON co.ID_COMUNA = r.ID_COMUNA_ORIGEN
        WHERE r.ID_RUTA = p_id_ruta

        UNION ALL

        SELECT c.NOMBRE_COMUNA, p.ORDEN
        FROM LEHZ_RUTA_PARADA p
        INNER JOIN LEHZ_COMUNA c ON c.ID_COMUNA = p.ID_COMUNA
        INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = p.ID_RUTA
        WHERE p.ID_RUTA = p_id_ruta
          AND p.ID_COMUNA NOT IN (r.ID_COMUNA_ORIGEN, r.ID_COMUNA_DESTINO)

        UNION ALL

        SELECT cd.NOMBRE_COMUNA, 1000000
        FROM LEHZ_RUTA r
        INNER JOIN LEHZ_COMUNA cd ON cd.ID_COMUNA = r.ID_COMUNA_DESTINO
        WHERE r.ID_RUTA = p_id_ruta
    ) t;

    RETURN v_detalle;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END LEHZ_FN_DETALLE_RUTA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_RUTA(
    p_opcion            IN VARCHAR2,
    p_id_ruta           IN OUT NUMBER,
    p_horario           IN TIMESTAMP DEFAULT NULL,
    p_distancia         IN NUMBER DEFAULT NULL,
    p_horas_est         IN NUMBER DEFAULT NULL,
    p_minutos_est       IN NUMBER DEFAULT NULL,
    p_id_comuna_origen  IN NUMBER DEFAULT NULL,
    p_id_comuna_destino IN NUMBER DEFAULT NULL
) IS
    v_opcion  VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_existe  NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_RUTA IN ROW EXCLUSIVE MODE;

    IF v_opcion IN ('I', 'U') THEN
        IF p_id_comuna_origen IS NULL OR p_id_comuna_destino IS NULL THEN
            RAISE_APPLICATION_ERROR(-20150,
                'Debes indicar la ciudad de origen y la ciudad de destino de la ruta.');
        END IF;

        IF p_id_comuna_origen = p_id_comuna_destino THEN
            RAISE_APPLICATION_ERROR(-20151,
                'La ciudad de origen y la ciudad de destino deben ser diferentes.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_COMUNA WHERE ID_COMUNA = p_id_comuna_origen;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20152, 'La comuna de origen seleccionada no existe.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_COMUNA WHERE ID_COMUNA = p_id_comuna_destino;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20153, 'La comuna de destino seleccionada no existe.');
        END IF;

        IF p_distancia IS NULL OR p_distancia <= 0 THEN
            RAISE_APPLICATION_ERROR(-20154, 'La distancia de la ruta debe ser mayor que cero kilometros.');
        END IF;

        IF p_horas_est IS NOT NULL AND p_horas_est < 0 THEN
            RAISE_APPLICATION_ERROR(-20155, 'Las horas estimadas no pueden ser negativas.');
        END IF;

        IF p_minutos_est IS NOT NULL AND p_minutos_est NOT BETWEEN 0 AND 59 THEN
            RAISE_APPLICATION_ERROR(-20156, 'Los minutos estimados deben estar entre 0 y 59.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        p_id_ruta := LEHZ_SEQ_RUTA.NEXTVAL;
        INSERT INTO LEHZ_RUTA (
            ID_RUTA, HORARIO, DISTANCIA, HORAS_ESTIMADAS, MINUTOS_ESTIMADOS,
            ID_COMUNA_ORIGEN, ID_COMUNA_DESTINO
        ) VALUES (
            p_id_ruta, p_horario, p_distancia, NVL(p_horas_est, 0), NVL(p_minutos_est, 0),
            p_id_comuna_origen, p_id_comuna_destino
        );

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_RUTA
        SET HORARIO = p_horario,
            DISTANCIA = p_distancia,
            HORAS_ESTIMADAS = NVL(p_horas_est, 0),
            MINUTOS_ESTIMADOS = NVL(p_minutos_est, 0),
            ID_COMUNA_ORIGEN = p_id_comuna_origen,
            ID_COMUNA_DESTINO = p_id_comuna_destino
        WHERE ID_RUTA = p_id_ruta;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20157, 'No se encontro la ruta a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_RUTA
        WHERE ID_RUTA = p_id_ruta;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20158, 'No se encontro la ruta a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20159, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20160,
                'No se puede eliminar la ruta porque tiene paradas o viajes asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_RUTA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_RUTAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT r.ID_RUTA,
               TO_CHAR(r.HORARIO, 'YYYY-MM-DD HH24:MI') AS HORARIO,
               r.DISTANCIA,
               r.HORAS_ESTIMADAS,
               r.MINUTOS_ESTIMADOS,
               r.ID_COMUNA_ORIGEN,
               co.NOMBRE_COMUNA AS ORIGEN,
               r.ID_COMUNA_DESTINO,
               cd.NOMBRE_COMUNA AS DESTINO,
               LEHZ_FN_DETALLE_RUTA(r.ID_RUTA) AS TRAYECTO,
               (SELECT COUNT(*) FROM LEHZ_RUTA_PARADA p WHERE p.ID_RUTA = r.ID_RUTA) AS TOTAL_PARADAS
        FROM LEHZ_RUTA r
        INNER JOIN LEHZ_COMUNA co ON co.ID_COMUNA = r.ID_COMUNA_ORIGEN
        INNER JOIN LEHZ_COMUNA cd ON cd.ID_COMUNA = r.ID_COMUNA_DESTINO
        ORDER BY co.NOMBRE_COMUNA ASC, cd.NOMBRE_COMUNA ASC, r.ID_RUTA ASC;
END LEHZ_PS_LISTAR_RUTAS;
/
