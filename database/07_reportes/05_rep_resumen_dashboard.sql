ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de entregar el resumen del tablero principal.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_RESUMEN_DASHBOARD (
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM LHAOMRJZ_VW_RESUMEN;
EXCEPTION
    WHEN OTHERS THEN
        IF p_cursor%ISOPEN THEN
            CLOSE p_cursor;
        END IF;
        RAISE;
END;
/
