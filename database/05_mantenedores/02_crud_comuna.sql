ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_COMUNA(
    p_opcion        IN VARCHAR2,
    p_id_comuna     IN OUT NUMBER,
    p_nombre_comuna IN VARCHAR2 DEFAULT NULL,
    p_id_region     IN NUMBER DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_COMUNA IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_comuna := LEHZ_SEQ_COMUNA.NEXTVAL;
        INSERT INTO LEHZ_COMUNA (ID_COMUNA, NOMBRE_COMUNA, ID_REGION)
        VALUES (p_id_comuna, UPPER(TRIM(p_nombre_comuna)), p_id_region);

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_COMUNA
        SET NOMBRE_COMUNA = UPPER(TRIM(p_nombre_comuna)),
            ID_REGION = p_id_region
        WHERE ID_COMUNA = p_id_comuna;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20022, 'No se encontro la comuna a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_COMUNA
        WHERE ID_COMUNA = p_id_comuna;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'No se encontro la comuna a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_COMUNA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_COMUNAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT c.ID_COMUNA, c.NOMBRE_COMUNA, c.ID_REGION, r.NOMBRE_REGION
        FROM LEHZ_COMUNA c
        INNER JOIN LEHZ_REGION r ON c.ID_REGION = r.ID_REGION
        ORDER BY c.ID_COMUNA ASC;
END LEHZ_PS_LISTAR_COMUNAS;
/