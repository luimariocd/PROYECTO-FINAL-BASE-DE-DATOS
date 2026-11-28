ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de calcular la ocupacion de asientos por viaje.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_REP_OCUPACION_ASIENTOS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT vb.ID_VIAJE,
        vb.FECHA_VIAJE_TEXTO AS FECHA_VIAJE,
        vb.NOMBRE_RUTA,
        vb.HORA_SALIDA,
        vb.PATENTE_BUS,
        vb.CONDUCTORES,
        vb.CAPACIDAD AS CAPACIDAD_TOTAL,
        (SELECT COUNT(*)
        FROM LHAOMRJZ_BOLETO b
        WHERE b.ID_VIAJE = vb.ID_VIAJE
        AND b.PATENTE_BUS = vb.PATENTE_BUS
        AND b.ESTADO IN ('EMITIDO', 'USADO')) AS ASIENTOS_VENDIDOS,
        vb.CAPACIDAD - (SELECT COUNT(*)
        FROM LHAOMRJZ_BOLETO b
        WHERE b.ID_VIAJE = vb.ID_VIAJE
        AND b.PATENTE_BUS = vb.PATENTE_BUS
        AND b.ESTADO IN ('EMITIDO', 'USADO')) AS ASIENTOS_DISPONIBLES,
        CASE
        WHEN vb.CAPACIDAD > 0 THEN
        ROUND((SELECT COUNT(*)
        FROM LHAOMRJZ_BOLETO b
        WHERE b.ID_VIAJE = vb.ID_VIAJE
        AND b.PATENTE_BUS = vb.PATENTE_BUS
        AND b.ESTADO IN ('EMITIDO', 'USADO')) * 100 / vb.CAPACIDAD, 1)
        ELSE 0
        END AS PORCENTAJE_OCUPACION
        FROM LHAOMRJZ_VW_VIAJE_BUSES vb
        ORDER BY vb.FECHA_VIAJE DESC, vb.HORA_SALIDA ASC, vb.PATENTE_BUS ASC;
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
        SELECT vb.ID_VIAJE,
               vb.FECHA_VIAJE_TEXTO AS FECHA_VIAJE,
               vb.NOMBRE_RUTA,
               vb.HORA_SALIDA,
               vb.PATENTE_BUS,
               vb.CONDUCTORES,
               vb.CAPACIDAD AS CAPACIDAD_TOTAL,
               (SELECT COUNT(*)
                  FROM LHAOMRJZ_BOLETO b
                 WHERE b.ID_VIAJE = vb.ID_VIAJE
                   AND b.PATENTE_BUS = vb.PATENTE_BUS
                   AND b.ESTADO IN ('EMITIDO', 'USADO')) AS ASIENTOS_VENDIDOS,
               vb.CAPACIDAD - (SELECT COUNT(*)
                  FROM LHAOMRJZ_BOLETO b
                 WHERE b.ID_VIAJE = vb.ID_VIAJE
                   AND b.PATENTE_BUS = vb.PATENTE_BUS
                   AND b.ESTADO IN ('EMITIDO', 'USADO')) AS ASIENTOS_DISPONIBLES,
               CASE
                   WHEN vb.CAPACIDAD > 0 THEN
                       ROUND((SELECT COUNT(*)
                                FROM LHAOMRJZ_BOLETO b
                               WHERE b.ID_VIAJE = vb.ID_VIAJE
                                 AND b.PATENTE_BUS = vb.PATENTE_BUS
                                 AND b.ESTADO IN ('EMITIDO', 'USADO')) * 100 / vb.CAPACIDAD, 1)
                   ELSE 0
               END AS PORCENTAJE_OCUPACION
          FROM LHAOMRJZ_VW_VIAJE_BUSES vb
         ORDER BY vb.FECHA_VIAJE DESC, vb.HORA_SALIDA ASC, vb.PATENTE_BUS ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_REP_OCUPACION_ASIENTOS: ' || SQLERRM);
END LHAOMRJZ_PS_REP_OCUPACION_ASIENTOS;
/
