ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_RUTA(
    p_opcion          IN VARCHAR2,
    p_id_ruta         IN OUT NUMBER,
    p_horario         IN TIMESTAMP DEFAULT NULL,
    p_distancia       IN NUMBER DEFAULT NULL,
    p_horas_est       IN NUMBER DEFAULT NULL,
    p_minutos_est     IN NUMBER DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_RUTA IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_ruta := LEHZ_SEQ_RUTA.NEXTVAL;
        INSERT INTO LEHZ_RUTA (ID_RUTA, HORARIO, DISTANCIA, HORAS_ESTIMADAS, MINUTOS_ESTIMADOS)
        VALUES (p_id_ruta, p_horario, p_distancia, p_horas_est, p_minutos_est);

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_RUTA
        SET HORARIO = p_horario,
            DISTANCIA = p_distancia,
            HORAS_ESTIMADAS = p_horas_est,
            MINUTOS_ESTIMADOS = p_minutos_est
        WHERE ID_RUTA = p_id_ruta;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20081, 'No se encontro la ruta a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_RUTA
        WHERE ID_RUTA = p_id_ruta;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20082, 'No se encontro la ruta a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_RUTA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_RUTAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_RUTA, HORARIO, DISTANCIA, HORAS_ESTIMADAS, MINUTOS_ESTIMADOS
        FROM LEHZ_RUTA
        ORDER BY ID_RUTA ASC;
END LEHZ_PS_LISTAR_RUTAS;
/