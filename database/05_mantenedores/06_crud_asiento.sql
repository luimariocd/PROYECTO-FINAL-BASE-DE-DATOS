ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de crear el mantenedor de asientos.
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_ASIENTO(
    p_opcion      IN VARCHAR2,
    p_nro_asiento IN NUMBER,
    p_patente     IN VARCHAR2,
    p_piso        IN NUMBER DEFAULT 1,
    p_ubicacion   IN VARCHAR2 DEFAULT NULL
) IS
    v_patente VARCHAR2(8);
    v_piso    NUMBER := NVL(p_piso, 1);
    v_count   NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_ASIENTO IN ROW EXCLUSIVE MODE;
    v_patente := LEHZ_FN_NORMALIZAR_PATENTE(p_patente);

    SELECT COUNT(*) INTO v_count FROM LEHZ_BUS WHERE PATENTE_BUS = v_patente;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20050, 'El bus seleccionado no existe.');
    END IF;

    IF p_nro_asiento IS NULL OR p_nro_asiento <= 0 THEN
        RAISE_APPLICATION_ERROR(-20050, 'El numero de asiento debe ser mayor que cero.');
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_ASIENTO (NUMERO_ASIENTO, PATENTE_BUS, PISO, UBICACION)
        VALUES (p_nro_asiento, v_patente, v_piso, UPPER(TRIM(p_ubicacion)));

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        UPDATE LEHZ_ASIENTO
           SET PISO = v_piso,
               UBICACION = UPPER(TRIM(p_ubicacion))
         WHERE NUMERO_ASIENTO = p_nro_asiento
           AND PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'No se encontro el asiento a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_ASIENTO
         WHERE NUMERO_ASIENTO = p_nro_asiento
           AND PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'No se encontro el asiento a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20050, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Ya existe ese numero de asiento para este bus.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20052, 'No se puede eliminar el asiento: tiene boletos asociados.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_ASIENTO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_ASIENTOS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT a.NUMERO_ASIENTO, a.PATENTE_BUS, a.PISO, a.UBICACION,
               b.MARCA || ' ' || b.MODELO AS BUS_DETALLE, b.CAPACIDAD
        FROM LEHZ_ASIENTO a
        INNER JOIN LEHZ_BUS b ON a.PATENTE_BUS = b.PATENTE_BUS
        ORDER BY a.PATENTE_BUS, a.NUMERO_ASIENTO ASC;
END LEHZ_PS_LISTAR_ASIENTOS;
/
