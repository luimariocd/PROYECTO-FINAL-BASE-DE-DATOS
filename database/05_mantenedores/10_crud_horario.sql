ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_HORARIO(
    p_opcion      IN VARCHAR2,
    p_id_horario  IN OUT NUMBER,
    p_hora_salida IN VARCHAR2 DEFAULT NULL,
    p_hora_llegada IN VARCHAR2 DEFAULT NULL,
    p_id_ruta     IN NUMBER DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_HORARIO IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_horario := LEHZ_SEQ_HORARIO.NEXTVAL;
        INSERT INTO LEHZ_HORARIO (ID_HORARIO, HORA_SALIDA, HORA_LLEGADA, ID_RUTA)
        VALUES (p_id_horario, TRIM(p_hora_salida), TRIM(p_hora_llegada), p_id_ruta);

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_HORARIO
        SET HORA_SALIDA = TRIM(p_hora_salida),
            HORA_LLEGADA = TRIM(p_hora_llegada),
            ID_RUTA = p_id_ruta
        WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20091, 'No se encontro el horario a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_HORARIO
        WHERE ID_HORARIO = p_id_horario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20092, 'No se encontro el horario a eliminar.');
        end if;
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
        SELECT h.ID_HORARIO, h.HORA_SALIDA, h.HORA_LLEGADA, h.ID_RUTA, r.ORIGEN || ' -> ' || r.DESTINO AS RUTA_DETALLE
        FROM LEHZ_HORARIO h
        INNER JOIN LEHZ_RUTA r ON h.ID_RUTA = r.ID_RUTA
        ORDER BY h.ID_HORARIO ASC;
END LEHZ_PS_LISTAR_HORARIOS;
/
