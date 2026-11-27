ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de listar comunas y regiones para el autocompletado.
CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_COMUNAS_CHILE (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT NOMBRE_COMUNA, NOMBRE_REGION
          FROM LEHZ_VW_COMUNAS_CHILE
         ORDER BY NOMBRE_REGION, NOMBRE_COMUNA;
EXCEPTION
    WHEN OTHERS THEN
        IF p_cursor%ISOPEN THEN
            CLOSE p_cursor;
        END IF;
        RAISE;
END;
/
