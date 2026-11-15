ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_ASIENTO(
    p_opcion       IN VARCHAR2,
    p_nro_asiento  IN NUMBER,
    p_patente      IN VARCHAR2,
    p_ubicacion    IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
    LOCK TABLE LEHZ_ASIENTO IN ROW EXCLUSIVE MODE;

    IF UPPER(p_opcion) = 'I' THEN
        INSERT INTO LEHZ_ASIENTO (NUMERO_ASIENTO, PATENTE_BUS, UBICACION)
        VALUES (p_nro_asiento, UPPER(TRIM(p_patente)), UPPER(TRIM(p_ubicacion)));

    ELSIF UPPER(p_opcion) = 'U' THEN
        UPDATE LEHZ_ASIENTO
        SET UBICACION = UPPER(TRIM(p_ubicacion))
        WHERE NUMERO_ASIENTO = p_nro_asiento 
          AND PATENTE_BUS = UPPER(TRIM(p_patente));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'No se encontro el asiento a actualizar.');
        END IF;

    ELSIF UPPER(p_opcion) = 'D' THEN
        DELETE FROM LEHZ_ASIENTO
        WHERE NUMERO_ASIENTO = p_nro_asiento 
          AND PATENTE_BUS = UPPER(TRIM(p_patente));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'No se encontro el asiento a eliminar.');
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Ya existe ese numero de asiento para este bus.');
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
        SELECT a.NUMERO_ASIENTO, a.PATENTE_BUS, a.UBICACION, b.MARCA || ' ' || b.MODELO AS BUS_DETALLE
        FROM LEHZ_ASIENTO a
        INNER JOIN LEHZ_BUS b ON a.PATENTE_BUS = b.PATENTE_BUS
        ORDER BY a.PATENTE_BUS, a.NUMERO_ASIENTO ASC;
END LEHZ_PS_LISTAR_ASIENTOS;
/