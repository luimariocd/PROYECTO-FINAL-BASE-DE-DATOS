ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de obtener el valor calculado de un boleto.
CREATE OR REPLACE PROCEDURE LEHZ_PS_OBTENER_VALOR_BOLETO (
    p_id_boleto IN  NUMBER,
    p_valor     OUT NUMBER
) IS
BEGIN
    p_valor := LEHZ_FN_OBTENER_VALOR_BOLETO(p_id_boleto);
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/
