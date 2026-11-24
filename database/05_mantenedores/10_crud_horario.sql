ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- MANTENEDOR 10: HORARIOS
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_HORARIO(
    p_opcion       IN VARCHAR2,
    p_id_horario   IN OUT NUMBER,
    p_horario_val  IN NUMBER DEFAULT NULL,
    p_hora_salida  IN TIMESTAMP DEFAULT NULL,
    p_hora_llegada IN TIMESTAMP DEFAULT NULL
) IS
    v_llegada TIMESTAMP := p_hora_llegada;
BEGIN
    LOCK TABLE LEHZ_HORARIO IN ROW EXCLUSIVE MODE;

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF p_horario_val IS NULL OR p_horario_val <= 0 THEN
            RAISE_APPLICATION_ERROR(-20090, 'El codigo de horario debe ser mayor que cero.');
        END IF;
        IF p_hora_salida IS NULL OR p_hora_llegada IS NULL THEN
            RAISE_APPLICATION_ERROR(-20090, 'Debe indicar la hora de salida y la hora de llegada.');
        END IF;
        -- Si la llegada es menor o igual a la salida, se asume que llega al dia siguiente.
        IF v_llegada <= p_hora_salida THEN
            v_llegada := v_llegada + INTERVAL '1' DAY;
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        p_id_horario := LEHZ_SEQ_HORARIO.NEXTVAL;
        INSERT INTO LEHZ_HORARIO (ID_HORARIO, HORARIO, HORA_SALIDA, HORA_LLEGADA)
        VALUES (p_id_horario, p_horario_val, p_hora_salida, v_llegada);

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_id_horario IS NULL OR p_id_horario <= 0 THEN
            RAISE_APPLICATION_ERROR(-20090, 'Debe indicar el horario a actualizar.');
        END IF;
        UPDATE LEHZ_HORARIO
           SET HORARIO = p_horario_val,
               HORA_SALIDA = p_hora_salida,
               HORA_LLEGADA = v_llegada
         WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20091, 'No se encontro el horario a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        IF p_id_horario IS NULL OR p_id_horario <= 0 THEN
            RAISE_APPLICATION_ERROR(-20092, 'Debe indicar el horario a eliminar.');
        END IF;
        DELETE FROM LEHZ_HORARIO WHERE ID_HORARIO = p_id_horario;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20092, 'No se encontro el horario a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20090, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20090, 'Ya existe un horario con ese identificador.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20092, 'No se puede eliminar el horario: tiene viajes asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_HORARIO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_HORARIOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_HORARIO, HORARIO,
               TO_CHAR(HORA_SALIDA, 'YYYY-MM-DD"T"HH24:MI') AS HORA_SALIDA,
               TO_CHAR(HORA_SALIDA, 'DD/MM/YYYY HH24:MI') AS HORA_SALIDA_TEXTO,
               TO_CHAR(HORA_LLEGADA, 'YYYY-MM-DD"T"HH24:MI') AS HORA_LLEGADA,
               TO_CHAR(HORA_LLEGADA, 'DD/MM/YYYY HH24:MI') AS HORA_LLEGADA_TEXTO,
               TO_CHAR(HORA_SALIDA, 'HH24:MI') || ' - ' || TO_CHAR(HORA_LLEGADA, 'HH24:MI') AS RANGO,
               CASE
                   WHEN TO_NUMBER(TO_CHAR(HORA_SALIDA, 'HH24')) < 12 THEN 'MANANA'
                   WHEN TO_NUMBER(TO_CHAR(HORA_SALIDA, 'HH24')) < 19 THEN 'TARDE'
                   ELSE 'NOCHE'
               END AS JORNADA
        FROM LEHZ_HORARIO
        ORDER BY HORA_SALIDA ASC;
END LEHZ_PS_LISTAR_HORARIOS;
/
