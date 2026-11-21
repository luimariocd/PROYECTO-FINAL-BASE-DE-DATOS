ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_VENDER_BOLETO(
    p_valor_boleto   IN NUMBER,
    p_rut_pasajero   IN NUMBER,
    p_id_viaje       IN NUMBER,
    p_numero_asiento IN NUMBER,
    p_patente_bus    IN VARCHAR2,
    p_metodo_pago    IN VARCHAR2,
    p_id_boleto_out  OUT NUMBER
) IS
    v_asiento_existe NUMBER := 0;
    v_id_pago        NUMBER;
BEGIN

    LOCK TABLE LEHZ_BOLETO IN EXCLUSIVE MODE;
    LOCK TABLE LEHZ_PAGO IN EXCLUSIVE MODE;


    SELECT COUNT(*) INTO v_asiento_existe
    FROM LEHZ_ASIENTO
    WHERE NUMERO_ASIENTO = p_numero_asiento 
      AND PATENTE_BUS = UPPER(TRIM(p_patente_bus));

    IF v_asiento_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'El asiento especificado no existe para este bus.');
    END IF;

    SELECT LEHZ_SEQ_BOLETO.NEXTVAL INTO p_id_boleto_out FROM DUAL;

    INSERT INTO LEHZ_BOLETO (
        ID_BOLETO, FECHA_EMISION_BOLETO, HORA_EMISION_BOLETO, VALOR_BOLETO, 
        RUT_PASAJERO, ID_VIAJE, NUMERO_ASIENTO, PATENTE_BUS
    ) VALUES (
        p_id_boleto_out, SYSDATE, SYSTIMESTAMP, p_valor_boleto, 
        p_rut_pasajero, p_id_viaje, p_numero_asiento, UPPER(TRIM(p_patente_bus))
    );

    SELECT LEHZ_SEQ_PAGO.NEXTVAL INTO v_id_pago FROM DUAL;

    INSERT INTO LEHZ_PAGO (
        ID_PAGO, FECHA_PAGO, MONTO_PAGO, METODO_PAGO, ID_BOLETO, RUT_PASAJERO
    ) VALUES (
        v_id_pago, SYSDATE, p_valor_boleto, UPPER(TRIM(p_metodo_pago)), p_id_boleto_out, p_rut_pasajero
    );

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20102, 'Este asiento ya se encuentra ocupado para este viaje o el boleto ya existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_VENDER_BOLETO;
/