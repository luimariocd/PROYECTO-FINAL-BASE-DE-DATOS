ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ASIGNAR_CONDUCE(
    p_rut_conductor IN VARCHAR2,
    p_patente_bus   IN VARCHAR2,
    p_id_viaje      IN NUMBER
) IS
    v_valida     NUMBER := 0;
    v_rut_limpio VARCHAR2(12) := UPPER(REGEXP_REPLACE(TRIM(p_rut_conductor), '\.', ''));
BEGIN
    LOCK TABLE LEHZ_CONDUCE IN EXCLUSIVE MODE;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_CONDUCTOR WHERE RUT_CONDUCTOR = v_rut_limpio;
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20121, 'El conductor no existe.'); END IF;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_BUS WHERE PATENTE_BUS = UPPER(TRIM(p_patente_bus));
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20122, 'El bus no existe.'); END IF;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
    IF v_valida = 0 THEN RAISE_APPLICATION_ERROR(-20123, 'El viaje no existe.'); END IF;

    INSERT INTO LEHZ_CONDUCE (RUT_CONDUCTOR, PATENTE_BUS, ID_VIAJE)
    VALUES (v_rut_limpio, UPPER(TRIM(p_patente_bus)), p_id_viaje);

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20124, 'Este conductor o bus ya se encuentra asignado a este viaje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ASIGNAR_CONDUCE;
/