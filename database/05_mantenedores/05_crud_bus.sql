ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_BUS(
    p_opcion      IN VARCHAR2,
    p_patente     IN VARCHAR2,
    p_marca       IN VARCHAR2 DEFAULT NULL,
    p_modelo      IN VARCHAR2 DEFAULT NULL,
    p_anio        IN NUMBER DEFAULT NULL,
    p_capacidad   IN NUMBER DEFAULT NULL,
    p_rut_empresa IN VARCHAR2 DEFAULT NULL
) IS
    v_opcion  VARCHAR2(1) := UPPER(TRIM(p_opcion));
    v_patente VARCHAR2(8);
    v_marca   VARCHAR2(30);
    v_modelo  VARCHAR2(30);
    v_rut     VARCHAR2(12);
    v_error   VARCHAR2(400);
    v_existe  NUMBER := 0;
BEGIN
    LOCK TABLE LEHZ_BUS IN ROW EXCLUSIVE MODE;

    v_patente := UPPER(TRIM(p_patente));
    v_marca   := LEHZ_FN_TITULO(p_marca);
    v_modelo  := TRIM(p_modelo);
    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa);

    IF v_opcion IN ('I', 'U') THEN
        IF v_patente IS NULL OR NOT REGEXP_LIKE(v_patente, '^[A-Z0-9]{6}$') THEN
            RAISE_APPLICATION_ERROR(-20090,
                'Patente invalida: debe tener 6 caracteres alfanumericos sin guion. Ejemplo: ABCD12.');
        END IF;

        v_error := LEHZ_FN_ERROR_RUT(v_rut, 'EMPRESA');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20091, v_error);
        END IF;

        SELECT COUNT(*) INTO v_existe FROM LEHZ_EMPRESA WHERE RUT_EMPRESA = v_rut;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20092, 'La empresa seleccionada no existe.');
        END IF;

        IF p_anio IS NOT NULL AND p_anio NOT BETWEEN 1950 AND 2100 THEN
            RAISE_APPLICATION_ERROR(-20093, 'Anio de fabricacion invalido: debe estar entre 1950 y 2100.');
        END IF;

        IF p_capacidad IS NOT NULL AND p_capacidad NOT BETWEEN 1 AND 100 THEN
            RAISE_APPLICATION_ERROR(-20094, 'Capacidad invalida: debe estar entre 1 y 100 asientos.');
        END IF;
    END IF;

    IF v_opcion = 'I' THEN
        INSERT INTO LEHZ_BUS (PATENTE_BUS, MARCA, MODELO, ANIO_FABRICACION, CAPACIDAD, RUT_EMPRESA)
        VALUES (v_patente, v_marca, v_modelo, p_anio, p_capacidad, v_rut);

    ELSIF v_opcion = 'U' THEN
        UPDATE LEHZ_BUS
        SET MARCA = v_marca,
            MODELO = v_modelo,
            ANIO_FABRICACION = p_anio,
            CAPACIDAD = p_capacidad,
            RUT_EMPRESA = v_rut
        WHERE PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20095, 'No se encontro el bus a actualizar.');
        END IF;

    ELSIF v_opcion = 'D' THEN
        DELETE FROM LEHZ_BUS
        WHERE PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20096, 'No se encontro el bus a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20097, 'Operacion no valida: use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20098, 'Ya existe un bus registrado con esa patente.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_IUD_BUS;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_BUSES(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT b.PATENTE_BUS,
               b.MARCA,
               b.MODELO,
               b.ANIO_FABRICACION,
               b.CAPACIDAD,
               b.RUT_EMPRESA,
               e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_BUS b
        INNER JOIN LEHZ_EMPRESA e ON b.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY b.PATENTE_BUS ASC;
END LEHZ_PS_LISTAR_BUSES;
/
