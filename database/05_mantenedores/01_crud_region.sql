ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_REGION(
    p_opcion        IN VARCHAR2,
    p_id_region     IN OUT NUMBER,
    p_nombre_region IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_REGION IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_region := LEHZ_SEQ_REGION.NEXTVAL;
        INSERT INTO LEHZ_REGION (ID_REGION, NOMBRE_REGION)
        VALUES (p_id_region, UPPER(TRIM(p_nombre_region)));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_REGION
        SET NOMBRE_REGION = UPPER(TRIM(p_nombre_region))
        WHERE ID_REGION = p_id_region;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'No se encontro la region a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_REGION
        WHERE ID_REGION = p_id_region;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'No se encontro la region a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_REGION;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_REGIONES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_REGION, NOMBRE_REGION
        FROM LEHZ_REGION
        ORDER BY ID_REGION ASC;
END LEHZ_PS_LISTAR_REGIONES;
/