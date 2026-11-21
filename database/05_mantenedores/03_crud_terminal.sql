ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_TERMINAL(
    p_opcion      IN VARCHAR2,
    p_id_terminal IN OUT NUMBER,
    p_nombre      IN VARCHAR2 DEFAULT NULL,
    p_calle       IN VARCHAR2 DEFAULT NULL,
    p_numero      IN NUMBER DEFAULT NULL,
    p_id_comuna   IN NUMBER DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_TERMINAL IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_terminal := LEHZ_SEQ_TERMINAL.NEXTVAL;
        INSERT INTO LEHZ_TERMINAL (ID_TERMINAL, NOMBRE, CALLE, NUMERO, ID_COMUNA)
        VALUES (p_id_terminal, UPPER(TRIM(p_nombre)), INITCAP(TRIM(p_calle)), p_numero, p_id_comuna);

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_TERMINAL
        SET NOMBRE = UPPER(TRIM(p_nombre)),
            CALLE = INITCAP(TRIM(p_calle)),
            NUMERO = p_numero,
            ID_COMUNA = p_id_comuna
        WHERE ID_TERMINAL = p_id_terminal;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20024, 'No se encontro el terminal a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_TERMINAL
        WHERE ID_TERMINAL = p_id_terminal;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'No se encontro el terminal a eliminar.');
        END IF;
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
        SELECT t.ID_TERMINAL, t.NOMBRE, t.CALLE, t.NUMERO, t.ID_COMUNA, c.NOMBRE_COMUNA
        FROM LEHZ_TERMINAL t
        INNER JOIN LEHZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        ORDER BY t.ID_TERMINAL ASC;
END LEHZ_PS_LISTAR_TERMINALES;
/