ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de calcular costos de mantencion por empresa y bus.
CREATE OR REPLACE PROCEDURE LEHZ_PS_REP_COSTOS_MANTENCION(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT e.RUT_EMPRESA,
        e.RAZON_SOCIAL,
        b.PATENTE_BUS,
        b.MARCA || ' ' || b.MODELO AS BUS,
        COUNT(m.ID_MANTENCION) AS TOTAL_MANTENCIONES,
        NVL(SUM(m.COSTO_MANTENCION), 0) AS COSTO_TOTAL_MANTENCIONES,
        NVL(ROUND(AVG(m.COSTO_MANTENCION), 0), 0) AS COSTO_PROMEDIO,
        TO_CHAR(MAX(m.FECHA_MANTENCION), 'DD/MM/YYYY') AS ULTIMA_MANTENCION
        FROM LEHZ_EMPRESA e
        INNER JOIN LEHZ_BUS b ON e.RUT_EMPRESA = b.RUT_EMPRESA
        LEFT JOIN LEHZ_MANTENCION m ON b.PATENTE_BUS = m.PATENTE_BUS
        GROUP BY e.RUT_EMPRESA, e.RAZON_SOCIAL, b.PATENTE_BUS, b.MARCA, b.MODELO
        ORDER BY COSTO_TOTAL_MANTENCIONES DESC, e.RAZON_SOCIAL ASC;
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
        SELECT e.RUT_EMPRESA,
               e.RAZON_SOCIAL,
               b.PATENTE_BUS,
               b.MARCA || ' ' || b.MODELO AS BUS,
               COUNT(m.ID_MANTENCION) AS TOTAL_MANTENCIONES,
               NVL(SUM(m.COSTO_MANTENCION), 0) AS COSTO_TOTAL_MANTENCIONES,
               NVL(ROUND(AVG(m.COSTO_MANTENCION), 0), 0) AS COSTO_PROMEDIO,
               TO_CHAR(MAX(m.FECHA_MANTENCION), 'DD/MM/YYYY') AS ULTIMA_MANTENCION
          FROM LEHZ_EMPRESA e
          INNER JOIN LEHZ_BUS b ON e.RUT_EMPRESA = b.RUT_EMPRESA
          LEFT JOIN LEHZ_MANTENCION m ON b.PATENTE_BUS = m.PATENTE_BUS
         GROUP BY e.RUT_EMPRESA, e.RAZON_SOCIAL, b.PATENTE_BUS, b.MARCA, b.MODELO
         ORDER BY COSTO_TOTAL_MANTENCIONES DESC, e.RAZON_SOCIAL ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_REP_COSTOS_MANTENCION: ' || SQLERRM);
END LEHZ_PS_REP_COSTOS_MANTENCION;
/
