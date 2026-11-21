ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- =========================================================================
-- DASHBOARD: LAS METRICAS QUE VE CADA USUARIO SE DECIDEN EN ORACLE
-- =========================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_DASHBOARD(
    p_perfil IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) IS
    v_perfil VARCHAR2(30) := UPPER(TRIM(p_perfil));
BEGIN
    IF v_perfil = 'ADMINISTRADOR' THEN
        OPEN p_cursor FOR
            SELECT 'Empresas' AS METRICA, COUNT(*) AS TOTAL, 1 AS ORDEN FROM LEHZ_EMPRESA
            UNION ALL
            SELECT 'Buses', COUNT(*), 2 FROM LEHZ_BUS
            UNION ALL
            SELECT 'Viajes programados', COUNT(*), 3 FROM LEHZ_VIAJE
            UNION ALL
            SELECT 'Pasajeros', COUNT(*), 4 FROM LEHZ_PASAJERO
            UNION ALL
            SELECT 'Boletos vendidos', COUNT(*), 5 FROM LEHZ_BOLETO
            UNION ALL
            SELECT 'Recaudacion total', NVL(SUM(MONTO_PAGO), 0), 6 FROM LEHZ_PAGO
            ORDER BY ORDEN;

    ELSIF v_perfil = 'OPERACIONES' THEN
        OPEN p_cursor FOR
            SELECT 'Buses' AS METRICA, COUNT(*) AS TOTAL, 1 AS ORDEN FROM LEHZ_BUS
            UNION ALL
            SELECT 'Conductores', COUNT(*), 2 FROM LEHZ_CONDUCTOR
            UNION ALL
            SELECT 'Mecanicos', COUNT(*), 3 FROM LEHZ_MECANICO
            UNION ALL
            SELECT 'Viajes programados', COUNT(*), 4 FROM LEHZ_VIAJE
            UNION ALL
            SELECT 'Mantenciones', COUNT(*), 5 FROM LEHZ_MANTENCION
            UNION ALL
            SELECT 'Costo mantenciones', NVL(SUM(COSTO_MANTENCION), 0), 6 FROM LEHZ_MANTENCION
            ORDER BY ORDEN;

    ELSIF v_perfil = 'VENDEDOR' THEN
        OPEN p_cursor FOR
            SELECT 'Pasajeros' AS METRICA, COUNT(*) AS TOTAL, 1 AS ORDEN FROM LEHZ_PASAJERO
            UNION ALL
            SELECT 'Viajes programados', COUNT(*), 2 FROM LEHZ_VIAJE
            UNION ALL
            SELECT 'Boletos vendidos', COUNT(*), 3 FROM LEHZ_BOLETO
            UNION ALL
            SELECT 'Recaudacion total', NVL(SUM(MONTO_PAGO), 0), 4 FROM LEHZ_PAGO
            ORDER BY ORDEN;

    ELSE
        OPEN p_cursor FOR
            SELECT 'Sin metricas disponibles' AS METRICA, 0 AS TOTAL, 1 AS ORDEN
            FROM DUAL;
    END IF;
END LEHZ_PS_DASHBOARD;
/
