ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de obtener el valor calculado de un boleto.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_OBTENER_VALOR_BOLETO (
    p_id_boleto IN  NUMBER,
    p_valor     OUT NUMBER
) IS
BEGIN
    p_valor := LHAOMRJZ_FN_OBTENER_VALOR_BOLETO(p_id_boleto);
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/
