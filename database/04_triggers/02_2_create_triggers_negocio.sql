-- ============================================================================
-- [02_2] TRIGGERS DE REGLAS DE NEGOCIO Y AUDITORIA
-- ============================================================================
ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ----------------------------------------------------------------------------
-- Paquete auxiliar de auditoria (evita repetir el INSERT en cada trigger)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE LEHZ_PKG_AUDITORIA AS
    PROCEDURE REGISTRAR(
        p_tabla     IN VARCHAR2,
        p_operacion IN VARCHAR2,
        p_id        IN VARCHAR2,
        p_detalle   IN VARCHAR2
    );
END LEHZ_PKG_AUDITORIA;
/

CREATE OR REPLACE PACKAGE BODY LEHZ_PKG_AUDITORIA AS
    PROCEDURE REGISTRAR(
        p_tabla     IN VARCHAR2,
        p_operacion IN VARCHAR2,
        p_id        IN VARCHAR2,
        p_detalle   IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO LEHZ_AUDITORIA (
            ID_AUDITORIA, TABLA_AFECTADA, OPERACION, ID_REGISTRO,
            DETALLE, USUARIO_BD, FECHA_EVENTO
        ) VALUES (
            LEHZ_SEQ_AUDITORIA.NEXTVAL,
            SUBSTR(p_tabla, 1, 40),
            SUBSTR(p_operacion, 1, 15),
            SUBSTR(p_id, 1, 60),
            SUBSTR(p_detalle, 1, 500),
            USER,
            SYSTIMESTAMP
        );
    END REGISTRAR;
END LEHZ_PKG_AUDITORIA;
/

-- ----------------------------------------------------------------------------
-- 1. Bus: anio de fabricacion valido y capacidad coherente con los asientos
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_BUS_VALIDA_ANIO
BEFORE INSERT OR UPDATE OF ANIO_FABRICACION ON LEHZ_BUS
FOR EACH ROW
DECLARE
    v_anio_actual NUMBER := EXTRACT(YEAR FROM SYSDATE);
BEGIN
    IF :NEW.ANIO_FABRICACION IS NULL THEN
        RAISE_APPLICATION_ERROR(-20201, 'El anio de fabricacion del bus es obligatorio.');
    END IF;
    IF :NEW.ANIO_FABRICACION < 1995 OR :NEW.ANIO_FABRICACION > v_anio_actual + 1 THEN
        RAISE_APPLICATION_ERROR(-20201, 'Anio de fabricacion invalido: debe estar entre 1995 y ' || (v_anio_actual + 1) || '.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_BUS_CAPACIDAD
BEFORE UPDATE OF CAPACIDAD ON LEHZ_BUS
FOR EACH ROW
DECLARE
    v_asientos NUMBER := 0;
BEGIN
    IF :NEW.CAPACIDAD IS NULL OR :NEW.CAPACIDAD <= 0 THEN
        RAISE_APPLICATION_ERROR(-20210, 'La capacidad del bus debe ser mayor que cero.');
    END IF;

    SELECT COUNT(*)
      INTO v_asientos
      FROM LEHZ_ASIENTO
     WHERE PATENTE_BUS = :NEW.PATENTE_BUS;

    IF :NEW.CAPACIDAD < v_asientos THEN
        RAISE_APPLICATION_ERROR(-20210, 'Capacidad invalida: el bus ya tiene ' || v_asientos || ' asientos registrados; no puede declarar menos.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 2. Asiento: capacidad, piso y ubicacion fisica (distribucion 2+2)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_ASIENTO_VALIDA
BEFORE INSERT OR UPDATE ON LEHZ_ASIENTO
FOR EACH ROW
DECLARE
    v_capacidad NUMBER;
    v_pisos     NUMBER;
    v_ubicacion VARCHAR2(10);
BEGIN
    SELECT CAPACIDAD, CANTIDAD_PISOS
      INTO v_capacidad, v_pisos
      FROM LEHZ_BUS
     WHERE PATENTE_BUS = :NEW.PATENTE_BUS;

    IF v_capacidad IS NULL THEN
        RAISE_APPLICATION_ERROR(-20202, 'El bus no tiene capacidad declarada.');
    END IF;

    IF :NEW.NUMERO_ASIENTO < 1 OR :NEW.NUMERO_ASIENTO > v_capacidad THEN
        RAISE_APPLICATION_ERROR(-20202, 'Asiento invalido: el bus tiene capacidad para ' || v_capacidad || ' asientos.');
    END IF;

    IF :NEW.PISO > v_pisos THEN
        RAISE_APPLICATION_ERROR(-20202, 'Piso invalido: el bus tiene ' || v_pisos || ' piso(s).');
    END IF;

    -- Distribucion 2+2: 1 y 4 son ventana; 2 y 3 son pasillo.
    v_ubicacion := CASE MOD(:NEW.NUMERO_ASIENTO - 1, 4)
                        WHEN 0 THEN 'VENTANA'
                        WHEN 3 THEN 'VENTANA'
                        ELSE 'PASILLO'
                   END;

    IF :NEW.UBICACION IS NOT NULL AND UPPER(TRIM(:NEW.UBICACION)) <> v_ubicacion THEN
        RAISE_APPLICATION_ERROR(-20202, 'Ubicacion invalida para el asiento ' || :NEW.NUMERO_ASIENTO || ': debe ser ' || v_ubicacion || ' segun la distribucion 2+2.');
    END IF;

    :NEW.UBICACION := v_ubicacion;
END;
/

-- ----------------------------------------------------------------------------
-- 3. Viaje: no permitir fechas anteriores a hoy
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_VIAJE_FECHA
BEFORE INSERT OR UPDATE OF FECHA_VIAJE ON LEHZ_VIAJE
FOR EACH ROW
BEGIN
    IF TRUNC(:NEW.FECHA_VIAJE) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20203, 'Fecha de viaje invalida: no se pueden programar viajes en dias anteriores a hoy.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 4. Conductor: licencia vigente al momento de registrarlo
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_CONDUCTOR_LICENCIA
BEFORE INSERT OR UPDATE OF VENCIMIENTO_LICENCIA, TIPO_LICENCIA ON LEHZ_CONDUCTOR
FOR EACH ROW
BEGIN
    IF :NEW.VENCIMIENTO_LICENCIA IS NULL THEN
        RAISE_APPLICATION_ERROR(-20211, 'El conductor debe tener fecha de vencimiento de licencia.');
    END IF;
    IF :NEW.VENCIMIENTO_LICENCIA < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20211, 'La licencia del conductor esta vencida (vence el ' || TO_CHAR(:NEW.VENCIMIENTO_LICENCIA, 'DD/MM/YYYY') || ').');
    END IF;
    IF :NEW.TIPO_LICENCIA IS NULL OR UPPER(TRIM(:NEW.TIPO_LICENCIA)) NOT IN ('A1', 'A2', 'A3') THEN
        RAISE_APPLICATION_ERROR(-20211, 'Tipo de licencia invalido: debe ser A1, A2 o A3.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 5. Conduccion: licencia vigente, bus sin mantencion y sin doble asignacion
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_CONDUCE_VALIDA
BEFORE INSERT OR UPDATE ON LEHZ_CONDUCE
FOR EACH ROW
DECLARE
    v_vencimiento DATE;
    v_fecha_viaje DATE;
    v_horario     NUMBER;
    v_count       NUMBER := 0;
BEGIN
    SELECT VENCIMIENTO_LICENCIA
      INTO v_vencimiento
      FROM LEHZ_CONDUCTOR
     WHERE RUT_CONDUCTOR = :NEW.RUT_CONDUCTOR;

    SELECT FECHA_VIAJE, ID_HORARIO
      INTO v_fecha_viaje, v_horario
      FROM LEHZ_VIAJE
     WHERE ID_VIAJE = :NEW.ID_VIAJE;

    IF v_vencimiento IS NULL OR v_vencimiento < v_fecha_viaje THEN
        RAISE_APPLICATION_ERROR(-20204, 'No se puede asignar el conductor: su licencia esta vencida o no tiene fecha de vencimiento para el viaje del ' || TO_CHAR(v_fecha_viaje, 'DD/MM/YYYY') || '.');
    END IF;

    SELECT COUNT(*)
      INTO v_count
      FROM LEHZ_MANTENCION
     WHERE PATENTE_BUS = :NEW.PATENTE_BUS
       AND TRUNC(FECHA_MANTENCION) = TRUNC(v_fecha_viaje);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20204, 'No se puede asignar el bus: tiene una mantencion registrada para la fecha del viaje.');
    END IF;

    SELECT COUNT(*)
      INTO v_count
      FROM LEHZ_CONDUCE c
      INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = c.ID_VIAJE
     WHERE v.ID_HORARIO = v_horario
       AND TRUNC(v.FECHA_VIAJE) = TRUNC(v_fecha_viaje)
       AND c.ID_VIAJE <> :NEW.ID_VIAJE
       AND (c.RUT_CONDUCTOR = :NEW.RUT_CONDUCTOR OR c.PATENTE_BUS = :NEW.PATENTE_BUS);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20204, 'El conductor o el bus ya estan asignados a otro viaje en la misma fecha y bloque horario.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 6. Boleto: capacidad, asiento activo, bus asignado y fecha del viaje
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_BOLETO_VALIDA
BEFORE INSERT OR UPDATE OF ID_VIAJE, PATENTE_BUS, NUMERO_ASIENTO ON LEHZ_BOLETO
FOR EACH ROW
DECLARE
    v_capacidad   NUMBER;
    v_count       NUMBER := 0;
    v_asignado    NUMBER := 0;
    v_fecha_viaje DATE;
BEGIN
    IF :NEW.ESTADO = 'ANULADO' THEN
        RETURN;
    END IF;

    SELECT COUNT(*)
      INTO v_asignado
      FROM LEHZ_CONDUCE
     WHERE ID_VIAJE = :NEW.ID_VIAJE
       AND PATENTE_BUS = :NEW.PATENTE_BUS;

    IF v_asignado = 0 THEN
        RAISE_APPLICATION_ERROR(-20205, 'No se puede vender el boleto: el bus no esta asignado al viaje.');
    END IF;

    SELECT FECHA_VIAJE
      INTO v_fecha_viaje
      FROM LEHZ_VIAJE
     WHERE ID_VIAJE = :NEW.ID_VIAJE;

    IF TRUNC(v_fecha_viaje) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20205, 'No se puede vender un boleto para un viaje cuya fecha ya paso.');
    END IF;

    SELECT CAPACIDAD
      INTO v_capacidad
      FROM LEHZ_BUS
     WHERE PATENTE_BUS = :NEW.PATENTE_BUS;

    SELECT COUNT(*)
      INTO v_count
      FROM LEHZ_BOLETO
     WHERE ID_VIAJE = :NEW.ID_VIAJE
       AND PATENTE_BUS = :NEW.PATENTE_BUS
       AND ESTADO IN ('EMITIDO', 'USADO')
       AND ID_BOLETO <> NVL(:NEW.ID_BOLETO, -1);

    IF v_count >= NVL(v_capacidad, 0) THEN
        RAISE_APPLICATION_ERROR(-20205, 'No se puede vender el boleto: se alcanzo la capacidad maxima del bus (' || v_capacidad || ' asientos).');
    END IF;

    SELECT COUNT(*)
      INTO v_count
      FROM LEHZ_BOLETO
     WHERE ID_VIAJE = :NEW.ID_VIAJE
       AND PATENTE_BUS = :NEW.PATENTE_BUS
       AND NUMERO_ASIENTO = :NEW.NUMERO_ASIENTO
       AND ESTADO IN ('EMITIDO', 'USADO')
       AND ID_BOLETO <> NVL(:NEW.ID_BOLETO, -1);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20205, 'El asiento ' || :NEW.NUMERO_ASIENTO || ' ya esta ocupado para este viaje y bus.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 7. Ciclo de vida del boleto: no reactivar boletos anulados o usados
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_BOLETO_ESTADO
BEFORE UPDATE OF ESTADO ON LEHZ_BOLETO
FOR EACH ROW
BEGIN
    IF :OLD.ESTADO = 'ANULADO' AND :NEW.ESTADO <> 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20206, 'Un boleto anulado no puede volver a quedar activo. Genere una nueva venta.');
    END IF;
    IF :OLD.ESTADO = 'USADO' AND :NEW.ESTADO = 'EMITIDO' THEN
        RAISE_APPLICATION_ERROR(-20206, 'Un boleto usado no puede volver al estado emitido.');
    END IF;
    IF :NEW.ESTADO = 'ANULADO' AND (:NEW.FECHA_ANULACION IS NULL OR :NEW.MOTIVO_ANULACION IS NULL) THEN
        RAISE_APPLICATION_ERROR(-20206, 'Para anular un boleto debe registrar la fecha y el motivo de anulacion.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 8. Pago: debe coincidir con el boleto, su pasajero y su valor
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_PAGO_VALIDA
BEFORE INSERT OR UPDATE ON LEHZ_PAGO
FOR EACH ROW
DECLARE
    v_valor      NUMBER;
    v_estado     VARCHAR2(10);
    v_rut        VARCHAR2(12);
BEGIN
    SELECT VALOR_BOLETO, ESTADO, RUT_PASAJERO
      INTO v_valor, v_estado, v_rut
      FROM LEHZ_BOLETO
     WHERE ID_BOLETO = :NEW.ID_BOLETO;

    IF v_estado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20212, 'No se puede registrar un pago para un boleto anulado.');
    END IF;
    IF :NEW.RUT_PASAJERO <> v_rut THEN
        RAISE_APPLICATION_ERROR(-20212, 'El RUT del pago no coincide con el pasajero del boleto.');
    END IF;
    IF :NEW.MONTO_PAGO <> v_valor THEN
        RAISE_APPLICATION_ERROR(-20212, 'El monto del pago (' || :NEW.MONTO_PAGO || ') no coincide con el valor del boleto (' || v_valor || ').');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 9. Bajada independiente: el terminal debe ser parada habilitada de la ruta
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_PASAJE_BAJADA_VALIDA
BEFORE INSERT OR UPDATE ON LEHZ_PASAJE_BAJADA
FOR EACH ROW
DECLARE
    v_id_ruta NUMBER;
    v_count   NUMBER := 0;
BEGIN
    SELECT v.ID_RUTA
      INTO v_id_ruta
      FROM LEHZ_BOLETO b
      INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
     WHERE b.ID_BOLETO = :NEW.ID_BOLETO;

    SELECT COUNT(*)
      INTO v_count
      FROM LEHZ_RUTA_PARADA rp
     WHERE rp.ID_RUTA = v_id_ruta
       AND rp.ID_TERMINAL = :NEW.ID_TERMINAL_BAJADA
       AND rp.PERMITE_BAJADA = 'S'
       AND rp.ORDEN_PARADA > 1;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20207, 'La bajada seleccionada no es una parada habilitada de la ruta del viaje.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 10. Paradas de ruta: la primera parada debe ser el origen
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_RUTA_PARADA_VALIDA
BEFORE INSERT OR UPDATE ON LEHZ_RUTA_PARADA
FOR EACH ROW
DECLARE
    v_origen  NUMBER;
    v_destino NUMBER;
BEGIN
    SELECT ID_TERMINAL_ORIGEN, ID_TERMINAL_DESTINO
      INTO v_origen, v_destino
      FROM LEHZ_RUTA
     WHERE ID_RUTA = :NEW.ID_RUTA;

    IF :NEW.ORDEN_PARADA = 1 AND :NEW.ID_TERMINAL <> v_origen THEN
        RAISE_APPLICATION_ERROR(-20208, 'La primera parada de la ruta debe ser el terminal de origen.');
    END IF;

    IF :NEW.ID_TERMINAL = v_origen AND :NEW.ORDEN_PARADA <> 1 THEN
        RAISE_APPLICATION_ERROR(-20208, 'El terminal de origen solo puede registrarse en la parada 1.');
    END IF;

    IF :NEW.ID_TERMINAL = v_destino AND :NEW.PERMITE_BAJADA <> 'S' THEN
        RAISE_APPLICATION_ERROR(-20208, 'El terminal de destino debe permitir la bajada de pasajeros.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 11. Horario: llegada posterior a la salida
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_HORARIO_VALIDA
BEFORE INSERT OR UPDATE ON LEHZ_HORARIO
FOR EACH ROW
BEGIN
    IF :NEW.HORA_SALIDA IS NULL OR :NEW.HORA_LLEGADA IS NULL THEN
        RAISE_APPLICATION_ERROR(-20209, 'El horario debe tener hora de salida y de llegada.');
    END IF;
    IF :NEW.HORA_LLEGADA <= :NEW.HORA_SALIDA THEN
        RAISE_APPLICATION_ERROR(-20209, 'La hora de llegada debe ser posterior a la hora de salida.');
    END IF;
END;
/

-- ============================================================================
-- 12. AUDITORIA AUTOMATICA
--     Se registran cambios en tablas criticas y eliminaciones de mantenedores.
-- ============================================================================
CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_REGION
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_REGION
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_REGION',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_REGION, :OLD.ID_REGION)),
        'Region: ' || COALESCE(:NEW.NOMBRE_REGION, :OLD.NOMBRE_REGION));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_COMUNA
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_COMUNA
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_COMUNA',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_COMUNA, :OLD.ID_COMUNA)),
        'Comuna: ' || COALESCE(:NEW.NOMBRE_COMUNA, :OLD.NOMBRE_COMUNA));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_TERMINAL
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_TERMINAL
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_TERMINAL',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_TERMINAL, :OLD.ID_TERMINAL)),
        'Terminal: ' || COALESCE(:NEW.NOMBRE, :OLD.NOMBRE));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_EMPRESA
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_EMPRESA
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_EMPRESA',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.RUT_EMPRESA, :OLD.RUT_EMPRESA),
        'Empresa: ' || COALESCE(:NEW.RAZON_SOCIAL, :OLD.RAZON_SOCIAL));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_CONDUCTOR
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_CONDUCTOR
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_CONDUCTOR',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.RUT_CONDUCTOR, :OLD.RUT_CONDUCTOR),
        'Conductor: ' || COALESCE(:NEW.NOMBRE_CONDUCTOR || ' ' || :NEW.APELLIDO1_CONDUCTOR, :OLD.NOMBRE_CONDUCTOR || ' ' || :OLD.APELLIDO1_CONDUCTOR));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_MECANICO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_MECANICO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_MECANICO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.RUT_MECANICO, :OLD.RUT_MECANICO),
        'Mecanico: ' || COALESCE(:NEW.NOMBRE_MECANICO || ' ' || :NEW.APELLIDO1_MECANICO, :OLD.NOMBRE_MECANICO || ' ' || :OLD.APELLIDO1_MECANICO));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_PASAJERO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_PASAJERO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_PASAJERO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.RUT_PASAJERO, :OLD.RUT_PASAJERO),
        'Pasajero: ' || COALESCE(:NEW.NOMBRE_PASAJERO || ' ' || :NEW.APELLIDO1_PASAJERO, :OLD.NOMBRE_PASAJERO || ' ' || :OLD.APELLIDO1_PASAJERO));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_RUTA
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_RUTA
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_RUTA',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_RUTA, :OLD.ID_RUTA)),
        'Ruta: ' || COALESCE(:NEW.NOMBRE_RUTA, :OLD.NOMBRE_RUTA));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_HORARIO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_HORARIO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_HORARIO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_HORARIO, :OLD.ID_HORARIO)),
        'Horario: ' || COALESCE(TO_CHAR(:NEW.HORARIO), TO_CHAR(:OLD.HORARIO)));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_ASIENTO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_ASIENTO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_ASIENTO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.PATENTE_BUS, :OLD.PATENTE_BUS) || '-' || TO_CHAR(COALESCE(:NEW.NUMERO_ASIENTO, :OLD.NUMERO_ASIENTO)),
        'Asiento ' || COALESCE(:NEW.NUMERO_ASIENTO, :OLD.NUMERO_ASIENTO) || ' del bus ' || COALESCE(:NEW.PATENTE_BUS, :OLD.PATENTE_BUS));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_BOLETO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_BOLETO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_BOLETO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_BOLETO, :OLD.ID_BOLETO)),
        'Boleto ' || COALESCE(:NEW.ID_BOLETO, :OLD.ID_BOLETO) || ' | Estado: ' || COALESCE(:NEW.ESTADO, :OLD.ESTADO) || ' | Viaje: ' || COALESCE(:NEW.ID_VIAJE, :OLD.ID_VIAJE) || ' | Asiento: ' || COALESCE(:NEW.NUMERO_ASIENTO, :OLD.NUMERO_ASIENTO) || ' | Valor: ' || COALESCE(:NEW.VALOR_BOLETO, :OLD.VALOR_BOLETO));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_PAGO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_PAGO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_PAGO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_PAGO, :OLD.ID_PAGO)),
        'Pago ' || COALESCE(:NEW.ID_PAGO, :OLD.ID_PAGO) || ' | Monto: ' || COALESCE(:NEW.MONTO_PAGO, :OLD.MONTO_PAGO) || ' | Metodo: ' || COALESCE(:NEW.METODO_PAGO, :OLD.METODO_PAGO));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_USUARIO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_USUARIO
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_USUARIO',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_USUARIO, :OLD.ID_USUARIO)),
        'Usuario: ' || COALESCE(:NEW.USERNAME, :OLD.USERNAME) || ' | Estado: ' || COALESCE(:NEW.ESTADO, :OLD.ESTADO));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_CONDUCE
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_CONDUCE
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_CONDUCE',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.RUT_CONDUCTOR, :OLD.RUT_CONDUCTOR) || '|' || COALESCE(:NEW.PATENTE_BUS, :OLD.PATENTE_BUS) || '|' || COALESCE(:NEW.ID_VIAJE, :OLD.ID_VIAJE),
        'Asignacion conductor/bus/viaje');
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_UTILIZAN
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_UTILIZAN
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_UTILIZAN',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        COALESCE(:NEW.RUT_EMPRESA, :OLD.RUT_EMPRESA) || '|' || COALESCE(:NEW.ID_TERMINAL, :OLD.ID_TERMINAL),
        'Asociacion terminal/empresa');
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_RUTA_PARADA
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_RUTA_PARADA
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_RUTA_PARADA',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_RUTA_PARADA, :OLD.ID_RUTA_PARADA)),
        'Parada de ruta: ' || COALESCE(:NEW.ID_RUTA, :OLD.ID_RUTA) || ' orden ' || COALESCE(:NEW.ORDEN_PARADA, :OLD.ORDEN_PARADA));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_PASAJE_BAJADA
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_PASAJE_BAJADA
FOR EACH ROW
BEGIN
    LEHZ_PKG_AUDITORIA.REGISTRAR('LEHZ_PASAJE_BAJADA',
        CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
        TO_CHAR(COALESCE(:NEW.ID_BAJADA, :OLD.ID_BAJADA)),
        'Bajada del boleto ' || COALESCE(:NEW.ID_BOLETO, :OLD.ID_BOLETO) || ' en terminal ' || COALESCE(:NEW.ID_TERMINAL_BAJADA, :OLD.ID_TERMINAL_BAJADA));
END;
/
