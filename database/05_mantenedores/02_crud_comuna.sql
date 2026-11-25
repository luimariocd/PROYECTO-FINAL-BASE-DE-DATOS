ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- MANTENEDOR 02: COMUNAS
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_COMUNA(
    p_opcion        IN VARCHAR2,
    p_id_comuna     IN OUT NUMBER,
    p_nombre_comuna IN VARCHAR2 DEFAULT NULL
) IS
    v_nombre     VARCHAR2(60);
    v_id_region  NUMBER;
    v_count      NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_COMUNA IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_NORMALIZAR_TEXTO(p_nombre_comuna);

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF v_nombre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20022, 'El nombre de la comuna es obligatorio.');
        END IF;

        BEGIN
            SELECT r.ID_REGION
              INTO v_id_region
              FROM LEHZ_VW_COMUNAS_CHILE_ALL c
              JOIN LEHZ_REGION r ON UPPER(r.NOMBRE_REGION) = UPPER(c.NOMBRE_REGION)
             WHERE UPPER(c.NOMBRE_COMUNA) = UPPER(v_nombre);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20022, 'La comuna seleccionada no existe en el catalogo de Chile o su region no esta cargada.');
        END;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        p_id_comuna := LEHZ_SEQ_COMUNA.NEXTVAL;
        INSERT INTO LEHZ_COMUNA (ID_COMUNA, NOMBRE_COMUNA, ID_REGION)
        VALUES (p_id_comuna, v_nombre, v_id_region);

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_id_comuna IS NULL OR p_id_comuna <= 0 THEN
            RAISE_APPLICATION_ERROR(-20022, 'Debe indicar la comuna a actualizar.');
        END IF;
        UPDATE LEHZ_COMUNA
           SET NOMBRE_COMUNA = v_nombre,
               ID_REGION = v_id_region
         WHERE ID_COMUNA = p_id_comuna;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20022, 'No se encontro la comuna a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        IF p_id_comuna IS NULL OR p_id_comuna <= 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'Debe indicar la comuna a eliminar.');
        END IF;
        DELETE FROM LEHZ_COMUNA WHERE ID_COMUNA = p_id_comuna;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'No se encontro la comuna a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20022, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Ya existe una comuna con ese identificador.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20023, 'No se puede eliminar la comuna: tiene terminales asociados.');
        END IF;
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
        ORDER BY r.NOMBRE_REGION ASC, c.NOMBRE_COMUNA ASC;
END LEHZ_PS_LISTAR_COMUNAS;
/
