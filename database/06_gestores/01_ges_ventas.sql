ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_VENDER_BOLETO(
    p_valor_boleto   IN NUMBER,
    p_rut_pasajero   IN VARCHAR2,
    p_id_viaje       IN NUMBER,
    p_numero_asiento IN NUMBER,
    p_patente_bus    IN VARCHAR2,
    p_metodo_pago    IN VARCHAR2,
    p_id_boleto_out  OUT NUMBER
) IS
    v_rut      VARCHAR2(12);
    v_patente  VARCHAR2(8);
    v_metodo   VARCHAR2(20);
    v_error    VARCHAR2(400);
    v_existe   NUMBER := 0;
    v_ocupado  NUMBER := 0;
    v_id_pago  NUMBER;
BEGIN
    LOCK TABLE LEHZ_BOLETO IN EXCLUSIVE MODE;
    LOCK TABLE LEHZ_PAGO IN EXCLUSIVE MODE;

    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_pasajero);
    v_patente := UPPER(TRIM(p_patente_bus));
    v_metodo  := UPPER(TRIM(p_metodo_pago));

    v_error := LEHZ_FN_ERROR_RUT(v_rut, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20220, v_error);
    END IF;

    IF p_valor_boleto IS NULL OR p_valor_boleto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20221, 'El valor del boleto debe ser mayor que cero.');
    END IF;

    IF v_metodo NOT IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA') THEN
        RAISE_APPLICATION_ERROR(-20222,
            'Metodo de pago invalido: use EFECTIVO, TARJETA o TRANSFERENCIA.');
    END IF;

    SELECT COUNT(*) INTO v_existe FROM LEHZ_PASAJERO WHERE RUT_PASAJERO = v_rut;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20223, 'El pasajero indicado no existe. Debes registrarlo primero.');
    END IF;

    SELECT COUNT(*) INTO v_existe FROM LEHZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20224, 'El viaje indicado no existe.');
    END IF;

    SELECT COUNT(*) INTO v_existe
    FROM LEHZ_CONDUCE
    WHERE ID_VIAJE = p_id_viaje
      AND PATENTE_BUS = v_patente;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20225,
            'El bus indicado no esta asignado a este viaje. Primero asigna conductor y bus al viaje.');
    END IF;

    SELECT COUNT(*) INTO v_existe
    FROM LEHZ_ASIENTO
    WHERE NUMERO_ASIENTO = p_numero_asiento
      AND PATENTE_BUS = v_patente;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20226, 'El asiento indicado no existe para este bus.');
    END IF;

    SELECT COUNT(*) INTO v_ocupado
    FROM LEHZ_BOLETO
    WHERE ID_VIAJE = p_id_viaje
      AND NUMERO_ASIENTO = p_numero_asiento
      AND PATENTE_BUS = v_patente;
    IF v_ocupado > 0 THEN
        RAISE_APPLICATION_ERROR(-20227, 'El asiento ya fue vendido para este viaje.');
    END IF;

    p_id_boleto_out := LEHZ_SEQ_BOLETO.NEXTVAL;

    INSERT INTO LEHZ_BOLETO (
        ID_BOLETO, FECHA_EMISION_BOLETO, HORA_EMISION_BOLETO, VALOR_BOLETO,
        RUT_PASAJERO, ID_VIAJE, NUMERO_ASIENTO, PATENTE_BUS
    ) VALUES (
        p_id_boleto_out, SYSDATE, SYSTIMESTAMP, p_valor_boleto,
        v_rut, p_id_viaje, p_numero_asiento, v_patente
    );

    v_id_pago := LEHZ_SEQ_PAGO.NEXTVAL;

    INSERT INTO LEHZ_PAGO (
        ID_PAGO, FECHA_PAGO, MONTO_PAGO, METODO_PAGO, ID_BOLETO, RUT_PASAJERO
    ) VALUES (
        v_id_pago, SYSDATE, p_valor_boleto, v_metodo, p_id_boleto_out, v_rut
    );

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20228,
            'No se pudo vender el boleto: el asiento ya esta ocupado para este viaje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_VENDER_BOLETO;
/
