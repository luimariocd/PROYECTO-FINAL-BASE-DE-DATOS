ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- MANTENEDOR 03: TERMINALES
-- ============================================================================
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_TERMINAL(
    p_opcion      IN VARCHAR2,
    p_id_terminal IN OUT NUMBER,
    p_nombre      IN VARCHAR2 DEFAULT NULL,
    p_calle       IN VARCHAR2 DEFAULT NULL,
    p_numero      IN NUMBER DEFAULT NULL,
    p_id_comuna   IN NUMBER DEFAULT NULL
) IS
    v_nombre VARCHAR2(80);
    v_calle  VARCHAR2(60);
    v_count  NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_TERMINAL IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_NORMALIZAR_TEXTO(p_nombre);
    v_calle  := LEHZ_FN_NORMALIZAR_TEXTO(p_calle);

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF v_nombre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20024, 'El nombre del terminal es obligatorio.');
        END IF;
        IF v_calle IS NULL THEN
            RAISE_APPLICATION_ERROR(-20024, 'La calle del terminal es obligatoria.');
        END IF;
        IF p_numero IS NOT NULL AND p_numero <= 0 THEN
            RAISE_APPLICATION_ERROR(-20024, 'El numero de la direccion debe ser mayor que cero.');
        END IF;
        IF p_id_comuna IS NULL OR p_id_comuna <= 0 THEN
            RAISE_APPLICATION_ERROR(-20024, 'Debe seleccionar una comuna valida.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM LEHZ_COMUNA WHERE ID_COMUNA = p_id_comuna;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20024, 'La comuna seleccionada no existe.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        p_id_terminal := LEHZ_SEQ_TERMINAL.NEXTVAL;
        INSERT INTO LEHZ_TERMINAL (ID_TERMINAL, NOMBRE, CALLE, NUMERO, ID_COMUNA)
        VALUES (p_id_terminal, v_nombre, v_calle, p_numero, p_id_comuna);

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_id_terminal IS NULL OR p_id_terminal <= 0 THEN
            RAISE_APPLICATION_ERROR(-20024, 'Debe indicar el terminal a actualizar.');
        END IF;
        UPDATE LEHZ_TERMINAL
           SET NOMBRE = v_nombre,
               CALLE = v_calle,
               NUMERO = p_numero,
               ID_COMUNA = p_id_comuna
         WHERE ID_TERMINAL = p_id_terminal;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20024, 'No se encontro el terminal a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        IF p_id_terminal IS NULL OR p_id_terminal <= 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'Debe indicar el terminal a eliminar.');
        END IF;
        DELETE FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'No se encontro el terminal a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20024, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20024, 'Ya existe un terminal con ese identificador.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20025, 'No se puede eliminar el terminal: tiene rutas, asociaciones o bajadas asociadas.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_TERMINAL;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_TERMINALES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT t.ID_TERMINAL, t.NOMBRE, t.CALLE, t.NUMERO, t.ID_COMUNA,
               c.NOMBRE_COMUNA, r.NOMBRE_REGION
        FROM LEHZ_TERMINAL t
        INNER JOIN LEHZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        INNER JOIN LEHZ_REGION r ON c.ID_REGION = r.ID_REGION
        ORDER BY r.NOMBRE_REGION ASC, c.NOMBRE_COMUNA ASC, t.NOMBRE ASC;
END LEHZ_PS_LISTAR_TERMINALES;
/
