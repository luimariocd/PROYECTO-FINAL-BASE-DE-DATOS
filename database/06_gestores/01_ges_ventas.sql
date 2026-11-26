ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de gestionar la venta, anulacion y ciclo de vida de boletos.

-- Esta parte del código se encarga de calcular la tarifa segun el tramo recorrido.
CREATE OR REPLACE FUNCTION LEHZ_FN_CALCULAR_TARIFA_BUS (
    p_id_viaje           IN NUMBER,
    p_patente_bus        IN VARCHAR2,
    p_id_terminal_bajada IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_base       NUMBER;
    v_id_ruta    NUMBER;
    v_destino    NUMBER;
    v_total_min  NUMBER;
    v_orden      NUMBER;
    v_min_parada NUMBER;
    v_ratio      NUMBER;
    v_tarifa     NUMBER;
BEGIN
    SELECT b.TARIFA_BASE,
           v.ID_RUTA,
           r.ID_TERMINAL_DESTINO,
           NVL(r.HORAS_ESTIMADAS, 0) * 60 + NVL(r.MINUTOS_ESTIMADOS, 0)
      INTO v_base, v_id_ruta, v_destino, v_total_min
      FROM LEHZ_VIAJE v
      INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
      INNER JOIN LEHZ_CONDUCE c ON c.ID_VIAJE = v.ID_VIAJE
      INNER JOIN LEHZ_BUS b ON b.PATENTE_BUS = c.PATENTE_BUS
     WHERE v.ID_VIAJE = p_id_viaje
       AND c.PATENTE_BUS = UPPER(TRIM(p_patente_bus))
       AND ROWNUM = 1;

    IF p_id_terminal_bajada IS NULL OR p_id_terminal_bajada = v_destino THEN
        RETURN v_base;
    END IF;

    SELECT rp.ORDEN_PARADA, rp.MINUTOS_DESDE_ORIG
      INTO v_orden, v_min_parada
      FROM LEHZ_RUTA_PARADA rp
     WHERE rp.ID_RUTA = v_id_ruta
       AND rp.ID_TERMINAL = p_id_terminal_bajada
       AND rp.PERMITE_BAJADA = 'S';

    IF v_orden = 1 THEN
        RAISE_APPLICATION_ERROR(-20103, 'No se puede vender un boleto con bajada en el terminal de origen.');
    END IF;

    IF v_total_min IS NULL OR v_total_min <= 0 THEN
        v_ratio := 1;
    ELSE
        v_ratio := v_min_parada / v_total_min;
    END IF;

    v_tarifa := ROUND(v_base * v_ratio, -2);
    IF v_tarifa < 0 THEN
        v_tarifa := 0;
    END IF;
    RETURN v_tarifa;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20103, 'No se encontro el bus asignado al viaje o la parada de bajada no pertenece a la ruta.');
END;
/

CREATE OR REPLACE FUNCTION LEHZ_FN_CALCULAR_TARIFA (
    p_id_viaje           IN NUMBER,
    p_id_terminal_bajada IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_patente VARCHAR2(8);
BEGIN
    SELECT c.PATENTE_BUS
      INTO v_patente
      FROM LEHZ_CONDUCE c
     WHERE c.ID_VIAJE = p_id_viaje
       AND ROWNUM = 1;

    RETURN LEHZ_FN_CALCULAR_TARIFA_BUS(p_id_viaje, v_patente, p_id_terminal_bajada);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20103, 'El viaje no tiene un bus asignado; no es posible calcular la tarifa.');
END;
/

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

    SELECT COUNT(*) INTO v_pasajero FROM LEHZ_PASAJERO WHERE RUT_PASAJERO = v_rut;
    IF v_pasajero = 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El pasajero no existe. Registrelo antes de vender el boleto.');
    END IF;

    SELECT FECHA_VIAJE INTO v_fecha_viaje FROM LEHZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
    IF TRUNC(v_fecha_viaje) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20104, 'No se puede vender un boleto para un viaje cuya fecha ya paso.');
    END IF;

    SELECT COUNT(*) INTO v_asignado
      FROM LEHZ_CONDUCE
     WHERE ID_VIAJE = p_id_viaje
       AND PATENTE_BUS = v_patente;
    IF v_asignado = 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El bus no esta asignado al viaje seleccionado.');
    END IF;

    SELECT CAPACIDAD INTO v_capacidad FROM LEHZ_BUS WHERE PATENTE_BUS = v_patente;

    SELECT COUNT(*) INTO v_asiento
      FROM LEHZ_ASIENTO
     WHERE PATENTE_BUS = v_patente
       AND NUMERO_ASIENTO = p_numero_asiento;
    IF v_asiento = 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El asiento ' || p_numero_asiento || ' no existe en el bus ' || v_patente || '.');
    END IF;

    SELECT COUNT(*) INTO v_ocupados
      FROM LEHZ_BOLETO
     WHERE ID_VIAJE = p_id_viaje
       AND PATENTE_BUS = v_patente
       AND ESTADO IN ('EMITIDO', 'USADO');
    IF v_ocupados >= NVL(v_capacidad, 0) THEN
        RAISE_APPLICATION_ERROR(-20104, 'No hay disponibilidad: el bus alcanzo su capacidad maxima (' || v_capacidad || ' asientos).');
    END IF;

    SELECT COUNT(*) INTO v_ocupados
      FROM LEHZ_BOLETO
     WHERE ID_VIAJE = p_id_viaje
       AND PATENTE_BUS = v_patente
       AND NUMERO_ASIENTO = p_numero_asiento
       AND ESTADO IN ('EMITIDO', 'USADO');
    IF v_ocupados > 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'El asiento ' || p_numero_asiento || ' ya esta ocupado para este viaje y bus.');
    END IF;

    v_tarifa := LEHZ_FN_CALCULAR_TARIFA_BUS(p_id_viaje, v_patente, v_terminal_bajada);

    SELECT LEHZ_SEQ_BOLETO.NEXTVAL INTO p_id_boleto_out FROM DUAL;

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
        SELECT NOMBRE INTO v_terminal_nombre
          FROM LEHZ_TERMINAL
         WHERE ID_TERMINAL = v_terminal_bajada;

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

    SELECT ESTADO INTO v_estado FROM LEHZ_BOLETO WHERE ID_BOLETO = p_id_boleto;

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

    SELECT ESTADO INTO v_estado FROM LEHZ_BOLETO WHERE ID_BOLETO = p_id_boleto;

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
BEGIN
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
END LEHZ_PS_LISTAR_BOLETOS;
/
