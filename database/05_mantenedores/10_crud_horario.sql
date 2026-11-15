ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_HORARIO(
    p_opcion      IN VARCHAR2,
    p_id_horario  IN OUT NUMBER,
    p_horario_val IN NUMBER DEFAULT NULL,
    p_hora_salida IN TIMESTAMP DEFAULT NULL,
    p_hora_llegada IN TIMESTAMP DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_HORARIO IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_horario := LEHZ_SEQ_HORARIO.NEXTVAL;
        INSERT INTO LEHZ_HORARIO (ID_HORARIO, HORARIO, HORA_SALIDA, HORA_LLEGADA)
        VALUES (p_id_horario, p_horario_val, p_hora_salida, p_hora_llegada);

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_HORARIO
        SET HORARIO = p_horario_val,
            HORA_SALIDA = p_hora_salida,
            HORA_LLEGADA = p_hora_llegada
        WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20091, 'No se encontro el horario a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_HORARIO
        WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20092, 'No se encontro el horario a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_HORARIO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_HORARIOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_HORARIO, HORARIO, HORA_SALIDA, HORA_LLEGADA
        FROM LEHZ_HORARIO
        ORDER BY ID_HORARIO ASC;
END LEHZ_PS_LISTAR_HORARIOS;
/