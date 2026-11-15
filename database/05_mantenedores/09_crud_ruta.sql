ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_RUTA(
    p_opcion      IN VARCHAR2,
    p_id_ruta     IN OUT NUMBER,
    p_origen      IN VARCHAR2 DEFAULT NULL,
    p_destino     IN VARCHAR2 DEFAULT NULL,
    p_distancia   IN NUMBER DEFAULT NULL,
    p_tiempo_est  IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_RUTA IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_ruta := LEHZ_SEQ_RUTA.NEXTVAL;
        INSERT INTO LEHZ_RUTA (ID_RUTA, ORIGEN, DESTINO, DISTANCIA_KM, TIEMPO_ESTIMADO)
        VALUES (p_id_ruta, UPPER(TRIM(p_origen)), UPPER(TRIM(p_destino)), p_distancia, TRIM(p_tiempo_est));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_RUTA
        SET ORIGEN = UPPER(TRIM(p_origen)),
            DESTINO = UPPER(TRIM(p_destino)),
            DISTANCIA_KM = p_distancia,
            TIEMPO_ESTIMADO = TRIM(p_tiempo_est)
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
        SELECT ID_RUTA, ORIGEN, DESTINO, DISTANCIA_KM, TIEMPO_ESTIMADO
        FROM LEHZ_RUTA
        ORDER BY ID_RUTA ASC;
END LEHZ_PS_LISTAR_RUTAS;
/