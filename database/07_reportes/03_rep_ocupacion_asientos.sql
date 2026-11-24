ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- REPORTE 03: OCUPACION DE ASIENTOS POR VIAJE Y BUS
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_REP_OCUPACION_ASIENTOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT vb.ID_VIAJE,
               vb.FECHA_VIAJE_TEXTO AS FECHA_VIAJE,
               vb.NOMBRE_RUTA,
               vb.HORA_SALIDA,
               vb.PATENTE_BUS,
               vb.CONDUCTORES,
               vb.CAPACIDAD AS CAPACIDAD_TOTAL,
               (SELECT COUNT(*)
                  FROM LEHZ_BOLETO b
                 WHERE b.ID_VIAJE = vb.ID_VIAJE
                   AND b.PATENTE_BUS = vb.PATENTE_BUS
                   AND b.ESTADO IN ('EMITIDO', 'USADO')) AS ASIENTOS_VENDIDOS,
               vb.CAPACIDAD - (SELECT COUNT(*)
                  FROM LEHZ_BOLETO b
                 WHERE b.ID_VIAJE = vb.ID_VIAJE
                   AND b.PATENTE_BUS = vb.PATENTE_BUS
                   AND b.ESTADO IN ('EMITIDO', 'USADO')) AS ASIENTOS_DISPONIBLES,
               CASE
                   WHEN vb.CAPACIDAD > 0 THEN
                       ROUND((SELECT COUNT(*)
                                FROM LEHZ_BOLETO b
                               WHERE b.ID_VIAJE = vb.ID_VIAJE
                                 AND b.PATENTE_BUS = vb.PATENTE_BUS
                                 AND b.ESTADO IN ('EMITIDO', 'USADO')) * 100 / vb.CAPACIDAD, 1)
                   ELSE 0
               END AS PORCENTAJE_OCUPACION
          FROM LEHZ_VW_VIAJE_BUSES vb
         ORDER BY vb.FECHA_VIAJE DESC, vb.HORA_SALIDA ASC, vb.PATENTE_BUS ASC;
END LEHZ_PS_REP_OCUPACION_ASIENTOS;
/
