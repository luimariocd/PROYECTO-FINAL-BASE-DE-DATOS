ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_PROGRAMAR_VIAJE(
    p_fecha_viaje   IN DATE,
    p_id_horario    IN NUMBER,
    p_id_ruta       IN NUMBER,
    p_id_viaje_out  OUT NUMBER
) IS
    v_valida NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_VIAJE IN EXCLUSIVE MODE;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_RUTA WHERE ID_RUTA = p_id_ruta;
    IF v_valida = 0 THEN
        RAISE_APPLICATION_ERROR(-20111, 'La ruta especificada no existe.');
    END IF;

    SELECT COUNT(*) INTO v_valida FROM LEHZ_HORARIO WHERE ID_HORARIO = p_id_horario;
    IF v_valida = 0 THEN
        RAISE_APPLICATION_ERROR(-20112, 'El horario especificado no existe.');
    END IF;

    SELECT LEHZ_SEQ_VIAJE.NEXTVAL INTO p_id_viaje_out FROM DUAL;

    INSERT INTO LEHZ_VIAJE (ID_VIAJE, FECHA_VIAJE, ID_HORARIO, ID_RUTA)
    VALUES (p_id_viaje_out, p_fecha_viaje, p_id_horario, p_id_ruta);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_PROGRAMAR_VIAJE;
/


CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_VIAJES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT v.ID_VIAJE, 
               TO_CHAR(v.FECHA_VIAJE, 'YYYY-MM-DD') AS FECHA_VIAJE, 
               v.ID_HORARIO, 
               v.ID_RUTA
        FROM LEHZ_VIAJE v
        ORDER BY v.ID_VIAJE DESC;
END LEHZ_PS_LISTAR_VIAJES;
/