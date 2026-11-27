ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de crear el mantenedor de comunas.
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

        v_id_region := LEHZ_FN_OBTENER_ID_REGION_COMUNA(v_nombre);
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

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT c.ID_COMUNA, c.NOMBRE_COMUNA, c.ID_REGION, r.NOMBRE_REGION
        FROM LEHZ_COMUNA c
        INNER JOIN LEHZ_REGION r ON c.ID_REGION = r.ID_REGION
        ORDER BY r.NOMBRE_REGION ASC, c.NOMBRE_COMUNA ASC;
    v_registro_cursor cur_local%ROWTYPE;
BEGIN
    -- Esta parte del código se encarga de abrir, leer y cerrar el cursor local sin consumir el SYS_REFCURSOR de salida.
    OPEN cur_local;
    FETCH cur_local INTO v_registro_cursor;
    IF cur_local%NOTFOUND THEN
        NULL;
    END IF;
    CLOSE cur_local;
    OPEN p_cursor FOR
        SELECT c.ID_COMUNA, c.NOMBRE_COMUNA, c.ID_REGION, r.NOMBRE_REGION
        FROM LEHZ_COMUNA c
        INNER JOIN LEHZ_REGION r ON c.ID_REGION = r.ID_REGION
        ORDER BY r.NOMBRE_REGION ASC, c.NOMBRE_COMUNA ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_LISTAR_COMUNAS: ' || SQLERRM);
END LEHZ_PS_LISTAR_COMUNAS;
/
