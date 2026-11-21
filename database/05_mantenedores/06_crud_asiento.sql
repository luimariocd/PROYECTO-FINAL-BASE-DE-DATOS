ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_ASIENTO(
    p_opcion      IN VARCHAR2,
    p_nro_asiento IN NUMBER,
    p_patente     IN VARCHAR2,
    p_ubicacion   IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion  VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_patente VARCHAR2(8);
    v_ubic    VARCHAR2(20);
    v_existe  NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_ASIENTO IN ROW EXCLUSIVE MODE;

    v_patente := UPPER(TRIM(p_patente));
    v_ubic    := LEHZ_FN_TITULO(p_ubicacion);

    IF v_opcion IN ('I', 'U') THEN
        IF p_nro_asiento IS NULL OR p_nro_asiento < 1 THEN
            RAISE_APPLICATION_ERROR(-20100, 'El numero de asiento debe ser mayor o igual a 1.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_BUS WHERE PATENTE_BUS = v_patente;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20101, 'El bus seleccionado no existe.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        INSERT INTO LEHZ_ASIENTO (NUMERO_ASIENTO, PATENTE_BUS, UBICACION)
        VALUES (p_nro_asiento, v_patente, v_ubic);

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_ASIENTO
        SET UBICACION = v_ubic
        WHERE NUMERO_ASIENTO = p_nro_asiento
          AND PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'No se encontro el asiento a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_ASIENTO
        WHERE NUMERO_ASIENTO = p_nro_asiento
          AND PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20103, 'No se encontro el asiento a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20104, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20105, 'Ya existe ese numero de asiento para este bus.');
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
        SELECT a.NUMERO_ASIENTO,
               a.PATENTE_BUS,
               a.UBICACION,
               b.MARCA || ' ' || b.MODELO AS BUS_DETALLE
        FROM LEHZ_ASIENTO a
        INNER JOIN LEHZ_BUS b ON a.PATENTE_BUS = b.PATENTE_BUS
        ORDER BY a.PATENTE_BUS, a.NUMERO_ASIENTO ASC;
END LEHZ_PS_LISTAR_ASIENTOS;
/
