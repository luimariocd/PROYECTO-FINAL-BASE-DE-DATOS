ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_TERMINAL(
    p_opcion      IN VARCHAR2,
    p_id_terminal IN OUT NUMBER,
    p_nombre      IN VARCHAR2 DEFAULT NULL,
    p_calle       IN VARCHAR2 DEFAULT NULL,
    p_numero      IN NUMBER DEFAULT NULL,
    p_id_comuna   IN NUMBER DEFAULT NULL
) IS
    v_opcion VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_nombre VARCHAR2(80);
    v_calle  VARCHAR2(60);
    v_error  VARCHAR2(400);
    v_existe NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_TERMINAL IN ROW EXCLUSIVE MODE;
    v_nombre := LEHZ_FN_TITULO(p_nombre);
    v_calle  := LEHZ_FN_TITULO(p_calle);

    IF v_opcion IN ('I', 'U') THEN
        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre del terminal');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20070, v_error);
        END IF;

        IF p_id_comuna IS NULL THEN
            RAISE_APPLICATION_ERROR(-20071, 'Debes seleccionar la comuna del terminal.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_COMUNA WHERE ID_COMUNA = p_id_comuna;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20072, 'La comuna seleccionada no existe.');
        END IF;

        IF p_numero IS NOT NULL AND p_numero <= 0 THEN
            RAISE_APPLICATION_ERROR(-20073, 'El numero de la direccion debe ser mayor que cero.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        p_id_terminal := LEHZ_SEQ_TERMINAL.NEXTVAL;
        INSERT INTO LEHZ_TERMINAL (ID_TERMINAL, NOMBRE, CALLE, NUMERO, ID_COMUNA)
        VALUES (p_id_terminal, v_nombre, v_calle, p_numero, p_id_comuna);

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_TERMINAL
        SET NOMBRE = v_nombre,
            CALLE = v_calle,
            NUMERO = p_numero,
            ID_COMUNA = p_id_comuna
        WHERE ID_TERMINAL = p_id_terminal;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20074, 'No se encontro el terminal a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_TERMINAL
        WHERE ID_TERMINAL = p_id_terminal;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20075, 'No se encontro el terminal a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20076, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_TERMINAL;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_TERMINALES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT t.ID_TERMINAL,
               t.NOMBRE,
               t.CALLE,
               t.NUMERO,
               t.ID_COMUNA,
               c.NOMBRE_COMUNA,
               r.NOMBRE_REGION
        FROM LEHZ_TERMINAL t
        INNER JOIN LEHZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        INNER JOIN LEHZ_REGION r ON c.ID_REGION = r.ID_REGION
        ORDER BY t.NOMBRE ASC;
END LEHZ_PS_LISTAR_TERMINALES;
/
