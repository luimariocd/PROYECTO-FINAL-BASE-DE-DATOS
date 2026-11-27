ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de gestionar la venta, anulacion y ciclo de vida de boletos.

-- Esta parte del código se encarga de validar pasajero, viaje, bus, asiento y capacidad al vender.
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_VENDER_BOLETO(
    p_rut_pasajero       IN VARCHAR2,
    p_id_viaje           IN NUMBER,
    p_numero_asiento     IN NUMBER,
    p_patente_bus        IN VARCHAR2,
    p_metodo_pago        IN VARCHAR2,
    p_id_terminal_bajada IN NUMBER DEFAULT NULL,
    p_id_boleto_out      OUT NUMBER
) IS
    v_rut             VARCHAR2(12);
    v_patente         VARCHAR2(8);
    v_metodo          VARCHAR2(20);
    v_terminal_bajada NUMBER;
    v_terminal_nombre VARCHAR2(80);
    v_fecha_viaje     DATE;
    v_capacidad       NUMBER;
    v_asignado        NUMBER := 0;
    v_pasajero        NUMBER := 0;
    v_asiento         NUMBER := 0;
    v_ocupados        NUMBER := 0;
    v_tarifa          NUMBER;
BEGIN
    LOCK TABLE LEHZ_BOLETO IN EXCLUSIVE MODE;
    LOCK TABLE LEHZ_PAGO IN EXCLUSIVE MODE;
    LOCK TABLE LEHZ_PASAJE_BAJADA IN EXCLUSIVE MODE;

    v_rut     := LEHZ_FN_NORMALIZAR_RUT(p_rut_pasajero, 'PERSONA');
    v_patente := LEHZ_FN_NORMALIZAR_PATENTE(p_patente_bus);
    v_metodo  := UPPER(TRIM(p_metodo_pago));
    v_terminal_bajada := NULLIF(p_id_terminal_bajada, 0);

    IF p_id_viaje IS NULL OR p_id_viaje <= 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'Debe seleccionar un viaje valido.');
    END IF;
    IF p_numero_asiento IS NULL OR p_numero_asiento <= 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'Debe seleccionar un numero de asiento valido.');
    END IF;
    IF v_metodo NOT IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA') THEN
        RAISE_APPLICATION_ERROR(-20104, 'Metodo de pago invalido: use EFECTIVO, TARJETA o TRANSFERENCIA.');
    END IF;

    v_pasajero := LEHZ_FN_EXISTE_PASAJERO(v_rut);
    IF v_pasajero = 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El pasajero no existe. Registrelo antes de vender el boleto.');
    END IF;

    v_fecha_viaje := LEHZ_FN_OBTENER_FECHA_VIAJE(p_id_viaje);
    IF v_fecha_viaje IS NULL THEN
        RAISE_APPLICATION_ERROR(-20104, 'El viaje indicado no existe.');
    END IF;
    IF TRUNC(v_fecha_viaje) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20104, 'No se puede vender un boleto para un viaje cuya fecha ya paso.');
    END IF;

    v_asignado := LEHZ_FN_BUS_ASIGNADO(p_id_viaje, v_patente);    IF v_asignado = 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El bus no esta asignado al viaje seleccionado.');
    END IF;

    v_capacidad := LEHZ_FN_OBTENER_CAPACIDAD_BUS(v_patente);

    v_asiento := LEHZ_FN_EXISTE_ASIENTO(v_patente, p_numero_asiento);    IF v_asiento = 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El asiento ' || p_numero_asiento || ' no existe en el bus ' || v_patente || '.');
    END IF;

    v_ocupados := LEHZ_FN_CONTAR_BOLETOS_OCUPADOS(p_id_viaje, v_patente);    IF v_ocupados >= NVL(v_capacidad, 0) THEN
        RAISE_APPLICATION_ERROR(-20104, 'No hay disponibilidad: el bus alcanzo su capacidad maxima (' || v_capacidad || ' asientos).');
    END IF;

    v_ocupados := LEHZ_FN_ASIENTO_OCUPADO(p_id_viaje, v_patente, p_numero_asiento);    IF v_ocupados > 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El asiento ' || p_numero_asiento || ' ya esta ocupado para este viaje y bus.');
    END IF;

    v_tarifa := LEHZ_FN_CALCULAR_TARIFA_BUS(p_id_viaje, v_patente, v_terminal_bajada);

    p_id_boleto_out := LEHZ_SEQ_BOLETO.NEXTVAL;

    INSERT INTO LEHZ_BOLETO (
        ID_BOLETO, FECHA_EMISION_BOLETO, HORA_EMISION_BOLETO, VALOR_BOLETO,
        RUT_PASAJERO, ID_VIAJE, NUMERO_ASIENTO, PATENTE_BUS, ESTADO
    ) VALUES (
        p_id_boleto_out, SYSDATE, SYSTIMESTAMP, v_tarifa,
        v_rut, p_id_viaje, p_numero_asiento, v_patente, 'EMITIDO'
    );

    INSERT INTO LEHZ_PAGO (
        ID_PAGO, FECHA_PAGO, MONTO_PAGO, METODO_PAGO, ID_BOLETO, RUT_PASAJERO
    ) VALUES (
        LEHZ_SEQ_PAGO.NEXTVAL, SYSDATE, v_tarifa, v_metodo, p_id_boleto_out, v_rut
    );

    IF v_terminal_bajada IS NOT NULL THEN
        v_terminal_nombre := LEHZ_FN_OBTENER_NOMBRE_TERMINAL(v_terminal_bajada);
        IF v_terminal_nombre IS NULL THEN
            RAISE_APPLICATION_ERROR(-20104, 'El terminal de bajada indicado no existe.');
        END IF;

        INSERT INTO LEHZ_PASAJE_BAJADA (
            ID_BAJADA, ID_BOLETO, ID_TERMINAL_BAJADA, OBSERVACION, FECHA_REGISTRO
        ) VALUES (
            LEHZ_SEQ_PASAJE_BAJADA.NEXTVAL, p_id_boleto_out, v_terminal_bajada,
            'Bajada en ' || v_terminal_nombre, SYSDATE
        );
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20105, 'El asiento ya fue vendido para este viaje. Seleccione otro asiento.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2291 THEN
            RAISE_APPLICATION_ERROR(-20104, 'Alguno de los datos seleccionados (pasajero, viaje, bus, asiento o terminal) no existe.');
        END IF;
        RAISE;
END LEHZ_PS_GES_VENDER_BOLETO;
/

-- Esta parte del código se encarga de anular el boleto sin borrar el boleto ni su pago.
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_ANULAR_BOLETO(
    p_id_boleto  IN NUMBER,
    p_motivo     IN VARCHAR2,
    p_estado_out OUT VARCHAR2
) IS
    v_estado VARCHAR2(10);
BEGIN
    LOCK TABLE LEHZ_BOLETO IN EXCLUSIVE MODE;

    IF p_id_boleto IS NULL OR p_id_boleto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20106, 'Debe indicar el boleto a anular.');
    END IF;
    IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
        RAISE_APPLICATION_ERROR(-20106, 'Debe indicar el motivo de la anulacion.');
    END IF;

    v_estado := LEHZ_FN_OBTENER_ESTADO_BOLETO(p_id_boleto);
    IF v_estado IS NULL THEN
        RAISE_APPLICATION_ERROR(-20106, 'No se encontro el boleto indicado.');
    END IF;

    IF v_estado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20106, 'El boleto ya se encuentra anulado.');
    END IF;
    IF v_estado = 'USADO' THEN
        RAISE_APPLICATION_ERROR(-20106, 'No se puede anular un boleto que ya fue utilizado.');
    END IF;

    UPDATE LEHZ_BOLETO
       SET ESTADO = 'ANULADO',
           FECHA_ANULACION = SYSDATE,
           MOTIVO_ANULACION = TRIM(p_motivo)
     WHERE ID_BOLETO = p_id_boleto;

    COMMIT;
    p_estado_out := 'ANULADO';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20106, 'No se encontro el boleto indicado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_ANULAR_BOLETO;
/

-- Esta parte del código se encarga de marcar como usado un boleto emitido.
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_MARCAR_BOLETO_USADO(
    p_id_boleto  IN NUMBER,
    p_estado_out OUT VARCHAR2
) IS
    v_estado VARCHAR2(10);
BEGIN
    LOCK TABLE LEHZ_BOLETO IN EXCLUSIVE MODE;

    IF p_id_boleto IS NULL OR p_id_boleto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20107, 'Debe indicar el boleto a marcar como usado.');
    END IF;

    v_estado := LEHZ_FN_OBTENER_ESTADO_BOLETO(p_id_boleto);
    IF v_estado IS NULL THEN
        RAISE_APPLICATION_ERROR(-20107, 'No se encontro el boleto indicado.');
    END IF;

    IF v_estado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20107, 'No se puede usar un boleto anulado.');
    END IF;
    IF v_estado = 'USADO' THEN
        RAISE_APPLICATION_ERROR(-20107, 'El boleto ya fue marcado como usado.');
    END IF;

    UPDATE LEHZ_BOLETO
       SET ESTADO = 'USADO'
     WHERE ID_BOLETO = p_id_boleto
       AND ESTADO = 'EMITIDO';

    COMMIT;
    p_estado_out := 'USADO';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20107, 'No se encontro el boleto indicado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_MARCAR_BOLETO_USADO;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_LISTAR_BOLETOS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT b.ID_BOLETO,
        TO_CHAR(b.FECHA_EMISION_BOLETO, 'DD/MM/YYYY') AS FECHA_EMISION,
        b.VALOR_BOLETO, b.ESTADO,
        b.RUT_PASAJERO,
        p.NOMBRE_PASAJERO || ' ' || p.APELLIDO1_PASAJERO AS PASAJERO,
        b.ID_VIAJE, TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
        r.NOMBRE_RUTA, b.PATENTE_BUS, b.NUMERO_ASIENTO,
        pg.METODO_PAGO,
        tb.NOMBRE AS TERMINAL_BAJADA,
        b.FECHA_ANULACION, b.MOTIVO_ANULACION
        FROM LEHZ_BOLETO b
        INNER JOIN LEHZ_PASAJERO p ON p.RUT_PASAJERO = b.RUT_PASAJERO
        INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
        INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        LEFT JOIN LEHZ_PAGO pg ON pg.ID_BOLETO = b.ID_BOLETO
        LEFT JOIN LEHZ_PASAJE_BAJADA pb ON pb.ID_BOLETO = b.ID_BOLETO
        LEFT JOIN LEHZ_TERMINAL tb ON tb.ID_TERMINAL = pb.ID_TERMINAL_BAJADA
        ORDER BY b.ID_BOLETO DESC;
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
        SELECT b.ID_BOLETO,
               TO_CHAR(b.FECHA_EMISION_BOLETO, 'DD/MM/YYYY') AS FECHA_EMISION,
               b.VALOR_BOLETO, b.ESTADO,
               b.RUT_PASAJERO,
               p.NOMBRE_PASAJERO || ' ' || p.APELLIDO1_PASAJERO AS PASAJERO,
               b.ID_VIAJE, TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
               r.NOMBRE_RUTA, b.PATENTE_BUS, b.NUMERO_ASIENTO,
               pg.METODO_PAGO,
               tb.NOMBRE AS TERMINAL_BAJADA,
               b.FECHA_ANULACION, b.MOTIVO_ANULACION
        FROM LEHZ_BOLETO b
        INNER JOIN LEHZ_PASAJERO p ON p.RUT_PASAJERO = b.RUT_PASAJERO
        INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
        INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
        LEFT JOIN LEHZ_PAGO pg ON pg.ID_BOLETO = b.ID_BOLETO
        LEFT JOIN LEHZ_PASAJE_BAJADA pb ON pb.ID_BOLETO = b.ID_BOLETO
        LEFT JOIN LEHZ_TERMINAL tb ON tb.ID_TERMINAL = pb.ID_TERMINAL_BAJADA
        ORDER BY b.ID_BOLETO DESC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LEHZ_PS_LISTAR_BOLETOS: ' || SQLERRM);
END LEHZ_PS_LISTAR_BOLETOS;
/
