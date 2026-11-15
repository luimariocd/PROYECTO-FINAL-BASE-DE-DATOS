ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_ASIENTO(
    p_opcion       IN VARCHAR2,
    p_id_asiento   IN OUT NUMBER,
    p_nro_asiento  IN NUMBER DEFAULT NULL,
    p_tipo_asiento IN VARCHAR2 DEFAULT NULL,
    p_patente      IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_ASIENTO IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        p_id_asiento := LEHZ_SEQ_ASIENTO.NEXTVAL;
        INSERT INTO LEHZ_ASIENTO (ID_ASIENTO, NRO_ASIENTO, TIPO_ASIENTO, PATENTE_BUS)
        VALUES (p_id_asiento, p_nro_asiento, UPPER(TRIM(p_tipo_asiento)), UPPER(TRIM(p_patente)));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_ASIENTO
        SET NRO_ASIENTO = p_nro_asiento,
            TIPO_ASIENTO = UPPER(TRIM(p_tipo_asiento)),
            PATENTE_BUS = UPPER(TRIM(p_patente))
        WHERE ID_ASIENTO = p_id_asiento;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'No se encontro el asiento a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_ASIENTO
        WHERE ID_ASIENTO = p_id_asiento;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'No se encontro el asiento a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_ASIENTO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_ASIENTOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT a.ID_ASIENTO, a.NRO_ASIENTO, a.TIPO_ASIENTO, a.PATENTE_BUS, b.MARCA || ' ' || b.MODELO AS BUS_DETALLE
        FROM LEHZ_ASIENTO a
        INNER JOIN LEHZ_BUS b ON a.PATENTE_BUS = b.PATENTE_BUS
        ORDER BY a.ID_ASIENTO ASC;
END LEHZ_PS_LISTAR_ASIENTOS;
/