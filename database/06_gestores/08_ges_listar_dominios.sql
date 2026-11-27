ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de listar los dominios disponibles para los formularios.
CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_DOMINIOS (
    p_dominio IN  VARCHAR2,
    p_cursor  OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT VALOR, ETIQUETA
          FROM LEHZ_VW_DOMINIOS
         WHERE DOMINIO = p_dominio
         ORDER BY VALOR;
EXCEPTION
    WHEN OTHERS THEN
        IF p_cursor%ISOPEN THEN
            CLOSE p_cursor;
        END IF;
        RAISE;
END;
/
