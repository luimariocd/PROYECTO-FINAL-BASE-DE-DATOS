ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de listar las paradas de bajada disponibles por viaje.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_PARADAS_BAJADA (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_VIAJE, ID_TERMINAL, TERMINAL, ORDEN_PARADA, TARIFA
          FROM LHAOMRJZ_VW_PARADAS_BAJADA
         ORDER BY ID_VIAJE, ORDEN_PARADA;
EXCEPTION
    WHEN OTHERS THEN
        IF p_cursor%ISOPEN THEN
            CLOSE p_cursor;
        END IF;
        RAISE;
END;
/
