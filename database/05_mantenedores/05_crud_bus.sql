ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de crear el mantenedor de buses.
CREATE OR REPLACE PROCEDURE LEHZ_PS_IUD_BUS(
    p_opcion        IN VARCHAR2,
    p_patente       IN VARCHAR2,
    p_marca         IN VARCHAR2 DEFAULT NULL,
    p_modelo        IN VARCHAR2 DEFAULT NULL,
    p_anio          IN NUMBER DEFAULT NULL,
    p_capacidad     IN NUMBER DEFAULT NULL,
    p_rut_empresa   IN VARCHAR2 DEFAULT NULL,
    p_tipo_servicio IN VARCHAR2 DEFAULT 'NORMAL',
    p_cantidad_pisos IN NUMBER DEFAULT 1,
    p_tarifa_base   IN NUMBER DEFAULT 5000
) IS
    v_patente VARCHAR2(8);
    v_rut     VARCHAR2(12);
    v_count   NUMBER := 0;
    v_tipo    VARCHAR2(20);
BEGIN
    LOCK TABLE LEHZ_BUS IN ROW EXCLUSIVE MODE;
    v_patente := LEHZ_FN_NORMALIZAR_PATENTE(p_patente);
    v_tipo    := UPPER(TRIM(NVL(p_tipo_servicio, 'NORMAL')));

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        v_rut := LEHZ_FN_NORMALIZAR_RUT(p_rut_empresa, 'EMPRESA');
        IF p_capacidad IS NULL OR p_capacidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20040, 'La capacidad del bus debe ser mayor que cero.');
        END IF;
        IF p_anio IS NULL THEN
            RAISE_APPLICATION_ERROR(-20040, 'El anio de fabricacion es obligatorio.');
        END IF;
        IF p_cantidad_pisos NOT IN (1, 2) THEN
            RAISE_APPLICATION_ERROR(-20040, 'La cantidad de pisos debe ser 1 o 2.');
        END IF;
        IF v_tipo NOT IN ('NORMAL', 'SALON CAMA', 'CAMA') THEN
            RAISE_APPLICATION_ERROR(-20040, 'Tipo de servicio invalido: use NORMAL, SALON CAMA o CAMA.');
        END IF;
        IF p_tarifa_base IS NULL OR p_tarifa_base <= 0 THEN
            RAISE_APPLICATION_ERROR(-20040, 'La tarifa base debe ser mayor que cero.');
        END IF;

        v_count := LEHZ_FN_EXISTE_EMPRESA(v_rut);
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20040, 'La empresa seleccionada no existe.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        INSERT INTO LEHZ_BUS (
            PATENTE_BUS, MARCA, MODELO, ANIO_FABRICACION, CAPACIDAD,
            TIPO_SERVICIO, CANTIDAD_PISOS, TARIFA_BASE, RUT_EMPRESA
        ) VALUES (
            v_patente, LEHZ_FN_NORMALIZAR_TEXTO(p_marca), LEHZ_FN_NORMALIZAR_TEXTO(p_modelo),
            p_anio, p_capacidad, v_tipo, p_cantidad_pisos, ROUND(p_tarifa_base), v_rut
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        v_count := LEHZ_FN_CONTAR_ASIENTOS(v_patente);        IF p_capacidad < v_count THEN
            RAISE_APPLICATION_ERROR(-20040, 'La capacidad no puede ser menor que los ' || v_count || ' asientos ya registrados.');
        END IF;

        UPDATE LEHZ_BUS
           SET MARCA = LEHZ_FN_NORMALIZAR_TEXTO(p_marca),
               MODELO = LEHZ_FN_NORMALIZAR_TEXTO(p_modelo),
               ANIO_FABRICACION = p_anio,
               CAPACIDAD = p_capacidad,
               TIPO_SERVICIO = v_tipo,
               CANTIDAD_PISOS = p_cantidad_pisos,
               TARIFA_BASE = ROUND(p_tarifa_base),
               RUT_EMPRESA = v_rut
         WHERE PATENTE_BUS = v_patente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20041, 'No se encontro el bus a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        DELETE FROM LEHZ_BUS WHERE PATENTE_BUS = v_patente;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20042, 'No se encontro el bus a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20040, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20040, 'Ya existe un bus registrado con esa patente.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20042, 'No se puede eliminar el bus: tiene asientos, viajes o mantenciones asociadas.');
        END IF;
        RAISE;
END LEHZ_PS_IUD_BUS;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_BUSES(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT b.PATENTE_BUS, b.MARCA, b.MODELO, b.ANIO_FABRICACION, b.CAPACIDAD,
        b.TIPO_SERVICIO, b.CANTIDAD_PISOS, b.TARIFA_BASE,
        b.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_BUS b
        INNER JOIN LEHZ_EMPRESA e ON b.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY b.PATENTE_BUS ASC;
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
        SELECT b.PATENTE_BUS, b.MARCA, b.MODELO, b.ANIO_FABRICACION, b.CAPACIDAD,
               b.TIPO_SERVICIO, b.CANTIDAD_PISOS, b.TARIFA_BASE,
               b.RUT_EMPRESA, e.RAZON_SOCIAL AS NOMBRE_EMPRESA
        FROM LEHZ_BUS b
        INNER JOIN LEHZ_EMPRESA e ON b.RUT_EMPRESA = e.RUT_EMPRESA
        ORDER BY b.PATENTE_BUS ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_LISTAR_BUSES: ' || SQLERRM);
END LEHZ_PS_LISTAR_BUSES;
/
