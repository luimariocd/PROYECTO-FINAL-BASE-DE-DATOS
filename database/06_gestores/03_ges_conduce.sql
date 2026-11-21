ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ASIGNAR_CONDUCE(
    p_rut_conductor IN VARCHAR2,
    p_patente_bus   IN VARCHAR2,
    p_id_viaje      IN NUMBER
) IS
    v_rut        VARCHAR2(12);
    v_patente    VARCHAR2(8);
    v_existe     NUMBER := 0;
    v_emp_cond   VARCHAR2(12);
    v_emp_bus    VARCHAR2(12);
    v_vencimiento DATE;
BEGIN
    LOCK TABLE LEHZ_CONDUCE IN EXCLUSIVE MODE;

    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_conductor);
    v_patente := UPPER(TRIM(p_patente_bus));

    SELECT COUNT(*), MAX(RUT_EMPRESA), MAX(VENCIMIENTO_LICENCIA)
    INTO v_existe, v_emp_cond, v_vencimiento
    FROM LEHZ_CONDUCTOR
    WHERE RUT_CONDUCTOR = v_rut;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20260, 'El conductor no existe.');
    END IF;

    IF v_vencimiento < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20261, 'El conductor tiene la licencia vencida y no puede ser asignado.');
    END IF;

    SELECT COUNT(*), MAX(RUT_EMPRESA)
    INTO v_existe, v_emp_bus
    FROM LEHZ_BUS
    WHERE PATENTE_BUS = v_patente;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20262, 'El bus no existe.');
    END IF;

    IF v_emp_cond <> v_emp_bus THEN
        RAISE_APPLICATION_ERROR(-20263,
            'El conductor y el bus deben pertenecer a la misma empresa.');
    END IF;

    SELECT COUNT(*) INTO v_existe FROM LEHZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20264, 'El viaje no existe.');
    END IF;

    INSERT INTO LEHZ_CONDUCE (RUT_CONDUCTOR, PATENTE_BUS, ID_VIAJE)
    VALUES (v_rut, v_patente, p_id_viaje);

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20265,
            'Este conductor o bus ya se encuentra asignado a este viaje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ASIGNAR_CONDUCE;
/
