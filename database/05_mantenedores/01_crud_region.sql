ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de crear el mantenedor de regiones.
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_REGION(
    p_opcion        IN VARCHAR2,
    p_id_region     IN OUT NUMBER,
    p_nombre_region IN VARCHAR2 DEFAULT NULL
) IS
    v_nombre VARCHAR2(60);
BEGIN
    LOCK TABLE LEHZ_REGION IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_NORMALIZAR_TEXTO(p_nombre_region);

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        IF v_nombre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20020, 'El nombre de la region es obligatorio.');
        END IF;
        p_id_region := LEHZ_SEQ_REGION.NEXTVAL;
        INSERT INTO LEHZ_REGION (ID_REGION, NOMBRE_REGION)
        VALUES (p_id_region, v_nombre);

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_id_region IS NULL OR p_id_region <= 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'Debe indicar la region a actualizar.');
        END IF;
        IF v_nombre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20020, 'El nombre de la region es obligatorio.');
        END IF;
        UPDATE LEHZ_REGION
           SET NOMBRE_REGION = v_nombre
         WHERE ID_REGION = p_id_region;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'No se encontro la region a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        IF p_id_region IS NULL OR p_id_region <= 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Debe indicar la region a eliminar.');
        END IF;
        DELETE FROM LEHZ_REGION
         WHERE ID_REGION = p_id_region;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'No se encontro la region a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20020, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, 'Ya existe una region con ese identificador.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20021, 'No se puede eliminar la region: tiene comunas asociadas.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_REGION;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_REGIONES(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT ID_REGION, NOMBRE_REGION
        FROM LEHZ_REGION
        ORDER BY NOMBRE_REGION ASC;
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
        SELECT ID_REGION, NOMBRE_REGION
        FROM LEHZ_REGION
        ORDER BY NOMBRE_REGION ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_LISTAR_REGIONES: ' || SQLERRM);
END LEHZ_PS_LISTAR_REGIONES;
/
