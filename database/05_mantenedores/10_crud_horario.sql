ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_HORARIO(
    p_opcion       IN VARCHAR2,
    p_id_horario   IN OUT NUMBER,
    p_horario_val  IN NUMBER DEFAULT NULL,
    p_hora_salida  IN TIMESTAMP DEFAULT NULL,
    p_hora_llegada IN TIMESTAMP DEFAULT NULL
) IS
    v_opcion VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_existe NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_HORARIO IN ROW EXCLUSIVE MODE;

    IF v_opcion IN ('I', 'U') THEN
        IF p_horario_val IS NULL OR p_horario_val <= 0 THEN
            RAISE_APPLICATION_ERROR(-20170, 'El codigo de horario debe ser un numero mayor que cero.');
        END IF;

        IF p_hora_salida IS NULL OR p_hora_llegada IS NULL THEN
            RAISE_APPLICATION_ERROR(-20171, 'Debes indicar la hora de salida y la hora de llegada.');
        END IF;

        IF p_hora_llegada <= p_hora_salida THEN
            RAISE_APPLICATION_ERROR(-20172, 'La hora de llegada debe ser posterior a la hora de salida.');
        END IF;

        SELECT COUNT(*) INTO v_existe
        FROM LEHZ_HORARIO
        WHERE HORARIO = p_horario_val
          AND ID_HORARIO <> NVL(p_id_horario, -1);

        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20173, 'Ya existe un horario con ese codigo.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        p_id_horario := LEHZ_SEQ_HORARIO.NEXTVAL;
        INSERT INTO LEHZ_HORARIO (ID_HORARIO, HORARIO, HORA_SALIDA, HORA_LLEGADA)
        VALUES (p_id_horario, p_horario_val, p_hora_salida, p_hora_llegada);

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_HORARIO
        SET HORARIO = p_horario_val,
            HORA_SALIDA = p_hora_salida,
            HORA_LLEGADA = p_hora_llegada
        WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20174, 'No se encontro el horario a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_HORARIO
        WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20175, 'No se encontro el horario a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20176, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20177, 'Ya existe un horario con ese codigo.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20178,
                'No se puede eliminar el horario porque tiene viajes asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_HORARIO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_HORARIOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_HORARIO,
               HORARIO,
               TO_CHAR(HORA_SALIDA, 'YYYY-MM-DD HH24:MI') AS HORA_SALIDA,
               TO_CHAR(HORA_LLEGADA, 'YYYY-MM-DD HH24:MI') AS HORA_LLEGADA
        FROM LEHZ_HORARIO
        ORDER BY HORARIO ASC;
END LEHZ_PS_LISTAR_HORARIOS;
/
