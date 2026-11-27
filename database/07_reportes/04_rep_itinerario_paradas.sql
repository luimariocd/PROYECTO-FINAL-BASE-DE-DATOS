ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de entregar el itinerario con paradas y bajadas.
CREATE OR REPLACE PROCEDURE LEHZ_PS_REP_ITINERARIO_PARADAS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        WITH PARADAS AS (
        SELECT r.ID_RUTA,
        r.NOMBRE_RUTA,
        rp.ORDEN_PARADA,
        rp.ID_TERMINAL,
        t.NOMBRE AS TERMINAL,
        c.NOMBRE_COMUNA,
        rp.MINUTOS_DESDE_ORIG,
        rp.PERMITE_BAJADA
        FROM LEHZ_RUTA r
        INNER JOIN LEHZ_RUTA_PARADA rp ON rp.ID_RUTA = r.ID_RUTA
        INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = rp.ID_TERMINAL
        INNER JOIN LEHZ_COMUNA c ON c.ID_COMUNA = t.ID_COMUNA
        ),
        RESUMEN_RUTA AS (
        SELECT p.ID_RUTA,
        COUNT(*) AS TOTAL_PARADAS,
        COUNT(DISTINCT p.ID_TERMINAL) AS TOTAL_TERMINALES,
        COUNT(DISTINCT p.NOMBRE_COMUNA) AS TOTAL_CIUDADES
        FROM PARADAS p
        GROUP BY p.ID_RUTA
        )
        SELECT p.ID_RUTA,
        p.NOMBRE_RUTA,
        rr.TOTAL_PARADAS,
        rr.TOTAL_TERMINALES,
        rr.TOTAL_CIUDADES,
        p.ORDEN_PARADA,
        p.TERMINAL,
        p.NOMBRE_COMUNA AS CIUDAD,
        p.MINUTOS_DESDE_ORIG,
        CASE WHEN p.PERMITE_BAJADA = 'S' THEN 'SI' ELSE 'NO' END AS PERMITE_BAJADA,
        (SELECT COUNT(*)
        FROM LEHZ_PASAJE_BAJADA pb
        INNER JOIN LEHZ_BOLETO b ON b.ID_BOLETO = pb.ID_BOLETO
        INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
        WHERE v.ID_RUTA = p.ID_RUTA
        AND pb.ID_TERMINAL_BAJADA = p.ID_TERMINAL
        AND b.ESTADO <> 'ANULADO') AS TOTAL_BAJADAS
        FROM PARADAS p
        INNER JOIN RESUMEN_RUTA rr ON rr.ID_RUTA = p.ID_RUTA
        ORDER BY p.NOMBRE_RUTA ASC, p.ORDEN_PARADA ASC;
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
        WITH PARADAS AS (
            SELECT r.ID_RUTA,
                   r.NOMBRE_RUTA,
                   rp.ORDEN_PARADA,
                   rp.ID_TERMINAL,
                   t.NOMBRE AS TERMINAL,
                   c.NOMBRE_COMUNA,
                   rp.MINUTOS_DESDE_ORIG,
                   rp.PERMITE_BAJADA
              FROM LEHZ_RUTA r
              INNER JOIN LEHZ_RUTA_PARADA rp ON rp.ID_RUTA = r.ID_RUTA
              INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = rp.ID_TERMINAL
              INNER JOIN LEHZ_COMUNA c ON c.ID_COMUNA = t.ID_COMUNA
        ),
        RESUMEN_RUTA AS (
            SELECT p.ID_RUTA,
                   COUNT(*) AS TOTAL_PARADAS,
                   COUNT(DISTINCT p.ID_TERMINAL) AS TOTAL_TERMINALES,
                   COUNT(DISTINCT p.NOMBRE_COMUNA) AS TOTAL_CIUDADES
              FROM PARADAS p
             GROUP BY p.ID_RUTA
        )
        SELECT p.ID_RUTA,
               p.NOMBRE_RUTA,
               rr.TOTAL_PARADAS,
               rr.TOTAL_TERMINALES,
               rr.TOTAL_CIUDADES,
               p.ORDEN_PARADA,
               p.TERMINAL,
               p.NOMBRE_COMUNA AS CIUDAD,
               p.MINUTOS_DESDE_ORIG,
               CASE WHEN p.PERMITE_BAJADA = 'S' THEN 'SI' ELSE 'NO' END AS PERMITE_BAJADA,
               (SELECT COUNT(*)
                  FROM LEHZ_PASAJE_BAJADA pb
                  INNER JOIN LEHZ_BOLETO b ON b.ID_BOLETO = pb.ID_BOLETO
                  INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
                 WHERE v.ID_RUTA = p.ID_RUTA
                   AND pb.ID_TERMINAL_BAJADA = p.ID_TERMINAL
                   AND b.ESTADO <> 'ANULADO') AS TOTAL_BAJADAS
          FROM PARADAS p
          INNER JOIN RESUMEN_RUTA rr ON rr.ID_RUTA = p.ID_RUTA
         ORDER BY p.NOMBRE_RUTA ASC, p.ORDEN_PARADA ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_REP_ITINERARIO_PARADAS: ' || SQLERRM);
END LEHZ_PS_REP_ITINERARIO_PARADAS;
/
