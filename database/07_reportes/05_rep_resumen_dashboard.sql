ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de entregar el resumen del tablero principal.
CREATE OR REPLACE PROCEDURE LEHZ_PS_RESUMEN_DASHBOARD (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM LEHZ_VW_RESUMEN;
EXCEPTION
    WHEN OTHERS THEN
        IF p_cursor%ISOPEN THEN
            CLOSE p_cursor;
        END IF;
        RAISE;
END;
/
