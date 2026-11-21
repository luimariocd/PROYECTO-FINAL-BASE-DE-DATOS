ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_COMUNA(
    p_opcion        IN VARCHAR2,
    p_id_comuna     IN OUT NUMBER,
    p_nombre_comuna IN VARCHAR2 DEFAULT NULL,
    p_id_region     IN NUMBER DEFAULT NULL
) IS
    v_opcion VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_nombre VARCHAR2(60);
    v_error  VARCHAR2(400);
    v_existe NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_COMUNA IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_TITULO(p_nombre_comuna);

    IF v_opcion IN ('I', 'U') THEN
        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre de la comuna');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20060, v_error);
        END IF;

        IF p_id_region IS NULL THEN
            RAISE_APPLICATION_ERROR(-20061, 'Debes seleccionar la region de la comuna.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_REGION WHERE ID_REGION = p_id_region;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20062, 'La region seleccionada no existe.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        p_id_comuna := LEHZ_SEQ_COMUNA.NEXTVAL;
        INSERT INTO LEHZ_COMUNA (ID_COMUNA, NOMBRE_COMUNA, ID_REGION)
        VALUES (p_id_comuna, v_nombre, p_id_region);

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_COMUNA
        SET NOMBRE_COMUNA = v_nombre,
            ID_REGION = p_id_region
        WHERE ID_COMUNA = p_id_comuna;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20063, 'No se encontro la comuna a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_COMUNA
        WHERE ID_COMUNA = p_id_comuna;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20064, 'No se encontro la comuna a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20065, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20066, 'Ya existe una comuna con ese nombre en la region seleccionada.');
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
        SELECT c.ID_COMUNA,
               c.NOMBRE_COMUNA,
               c.ID_REGION,
               r.NOMBRE_REGION
        FROM LEHZ_COMUNA c
        INNER JOIN LEHZ_REGION r ON c.ID_REGION = r.ID_REGION
        ORDER BY r.NOMBRE_REGION ASC, c.NOMBRE_COMUNA ASC;
END LEHZ_PS_LISTAR_COMUNAS;
/
