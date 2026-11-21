ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_REGION(
    p_opcion        IN VARCHAR2,
    p_id_region     IN OUT NUMBER,
    p_nombre_region IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_nombre VARCHAR2(60);
    v_error  VARCHAR2(400);
BEGIN
    LOCK TABLE LEHZ_REGION IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_TITULO(p_nombre_region);

    IF v_opcion = 'I' THEN
        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre de la region');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20050, v_error);
        END IF;

        p_id_region := LEHZ_SEQ_REGION.NEXTVAL;
        INSERT INTO LEHZ_REGION (ID_REGION, NOMBRE_REGION)
        VALUES (p_id_region, v_nombre);

    ELSIF v_opcion = 'U' THEN
        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre de la region');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20050, v_error);
        END IF;

        UPDATE LEHZ_REGION
        SET NOMBRE_REGION = v_nombre
        WHERE ID_REGION = p_id_region;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'No se encontro la region a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_REGION
        WHERE ID_REGION = p_id_region;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'No se encontro la region a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20053, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20054, 'Ya existe una region registrada con ese nombre.');
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
        SELECT r.ID_REGION,
               r.NOMBRE_REGION,
               (SELECT COUNT(*) FROM LEHZ_COMUNA c WHERE c.ID_REGION = r.ID_REGION) AS TOTAL_COMUNAS
        FROM LEHZ_REGION r
        ORDER BY r.NOMBRE_REGION ASC;
END LEHZ_PS_LISTAR_REGIONES;
/
