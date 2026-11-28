ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de calcular la recaudacion por viaje sin boletos anulados.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_REP_RECAUDACION_VIAJES(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT v.ID_VIAJE,
        TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
        r.NOMBRE_RUTA,
        o.NOMBRE AS TERMINAL_ORIGEN,
        d.NOMBRE AS TERMINAL_DESTINO,
        COUNT(DISTINCT b.ID_BOLETO) AS TOTAL_BOLETOS_VENDIDOS,
        NVL(SUM(p.MONTO_PAGO), 0) AS RECAUDACION_TOTAL
        FROM LHAOMRJZ_VIAJE v
        INNER JOIN LHAOMRJZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
        INNER JOIN LHAOMRJZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO
        LEFT JOIN LHAOMRJZ_BOLETO b
        ON b.ID_VIAJE = v.ID_VIAJE
        AND b.ESTADO <> 'ANULADO'
        LEFT JOIN LHAOMRJZ_PAGO p ON p.ID_BOLETO = b.ID_BOLETO
        GROUP BY v.ID_VIAJE, v.FECHA_VIAJE, r.NOMBRE_RUTA, o.NOMBRE, d.NOMBRE
        ORDER BY v.FECHA_VIAJE DESC, v.ID_VIAJE DESC;
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
               r.NOMBRE_RUTA,
               o.NOMBRE AS TERMINAL_ORIGEN,
               d.NOMBRE AS TERMINAL_DESTINO,
               COUNT(DISTINCT b.ID_BOLETO) AS TOTAL_BOLETOS_VENDIDOS,
               NVL(SUM(p.MONTO_PAGO), 0) AS RECAUDACION_TOTAL
          FROM LHAOMRJZ_VIAJE v
          INNER JOIN LHAOMRJZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
          INNER JOIN LHAOMRJZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
          INNER JOIN LHAOMRJZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO
          LEFT JOIN LHAOMRJZ_BOLETO b
                 ON b.ID_VIAJE = v.ID_VIAJE
                AND b.ESTADO <> 'ANULADO'
          LEFT JOIN LHAOMRJZ_PAGO p ON p.ID_BOLETO = b.ID_BOLETO
         GROUP BY v.ID_VIAJE, v.FECHA_VIAJE, r.NOMBRE_RUTA, o.NOMBRE, d.NOMBRE
         ORDER BY v.FECHA_VIAJE DESC, v.ID_VIAJE DESC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_REP_RECAUDACION_VIAJES: ' || SQLERRM);
END LHAOMRJZ_PS_REP_RECAUDACION_VIAJES;
/
