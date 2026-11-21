ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_PARADA(
    p_opcion    IN VARCHAR2,
    p_id_parada IN OUT NUMBER,
    p_id_ruta   IN NUMBER,
    p_orden     IN NUMBER,
    p_id_comuna IN NUMBER,
    p_distancia IN NUMBER DEFAULT 0,
    p_minutos   IN NUMBER DEFAULT 0
) IS
    v_opcion  VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_existe  NUMBER := 0;
    v_dup     NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_RUTA_PARADA IN ROW EXCLUSIVE MODE;

    IF v_opcion IN ('I', 'U') THEN
        SELECT COUNT(*) INTO v_existe FROM LEHZ_RUTA WHERE ID_RUTA = p_id_ruta;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20200, 'La ruta seleccionada no existe.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_COMUNA WHERE ID_COMUNA = p_id_comuna;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20201, 'La comuna seleccionada no existe.');
        END IF;

        IF p_orden IS NULL OR p_orden < 1 THEN
            RAISE_APPLICATION_ERROR(-20202, 'El orden de la parada debe ser mayor o igual a 1.');
        END IF;

        IF p_distancia IS NULL OR p_distancia < 0 THEN
            RAISE_APPLICATION_ERROR(-20203, 'La distancia desde el origen no puede ser negativa.');
        END IF;

        IF p_minutos IS NULL OR p_minutos < 0 THEN
            RAISE_APPLICATION_ERROR(-20204, 'Los minutos desde la salida no pueden ser negativos.');
        END IF;

        SELECT COUNT(*) INTO v_dup
        FROM LEHZ_RUTA_PARADA
        WHERE ID_RUTA = p_id_ruta
          AND ORDEN = p_orden
          AND ID_PARADA <> NVL(p_id_parada, -1);

        IF v_dup > 0 THEN
            RAISE_APPLICATION_ERROR(-20205,
                'Ya existe una parada con ese orden en la ruta seleccionada.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        p_id_parada := LEHZ_SEQ_PARADA.NEXTVAL;
        INSERT INTO LEHZ_RUTA_PARADA (
            ID_PARADA, ID_RUTA, ORDEN, ID_COMUNA, DISTANCIA_DESDE_ORIGEN, MINUTOS_DESDE_SALIDA
        ) VALUES (
            p_id_parada, p_id_ruta, p_orden, p_id_comuna, p_distancia, p_minutos
        );

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_RUTA_PARADA
        SET ID_RUTA = p_id_ruta,
            ORDEN = p_orden,
            ID_COMUNA = p_id_comuna,
            DISTANCIA_DESDE_ORIGEN = p_distancia,
            MINUTOS_DESDE_SALIDA = p_minutos
        WHERE ID_PARADA = p_id_parada;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20206, 'No se encontro la parada a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_RUTA_PARADA
        WHERE ID_PARADA = p_id_parada;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20207, 'No se encontro la parada a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20208, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20205,
            'Ya existe una parada con ese orden en la ruta seleccionada.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_PARADA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_PARADAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT p.ID_PARADA,
               p.ID_RUTA,
               p.ORDEN,
               p.ID_COMUNA,
               c.NOMBRE_COMUNA,
               p.DISTANCIA_DESDE_ORIGEN,
               p.MINUTOS_DESDE_SALIDA,
               LEHZ_FN_DETALLE_RUTA(p.ID_RUTA) AS TRAYECTO
        FROM LEHZ_RUTA_PARADA p
        INNER JOIN LEHZ_COMUNA c ON c.ID_COMUNA = p.ID_COMUNA
        ORDER BY p.ID_RUTA ASC, p.ORDEN ASC;
END LEHZ_PS_LISTAR_PARADAS;
/
