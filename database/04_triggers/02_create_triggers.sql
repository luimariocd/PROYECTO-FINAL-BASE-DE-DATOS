ALTER SESSION SET CURRENT_SCHEMA = LEHZ;


CREATE OR REPLACE TRIGGER LEHZ_TRG_AUDITORIA_BUSES
AFTER INSERT OR UPDATE OR DELETE 
ON LEHZ_BUS
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(15);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle   := 'Se registro un nuevo bus con patente: ' || :NEW.PATENTE_BUS || ', Marca: ' || :NEW.MARCA;
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_detalle   := 'Se actualizo el bus patente: ' || :OLD.PATENTE_BUS || ' (Modelo anterior: ' || :OLD.MODELO || ' -> Nuevo modelo: ' || :NEW.MODELO || ')';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle   := 'Se elimino el bus con patente: ' || :OLD.PATENTE_BUS;
    END IF;

    -- Esta parte del código se encarga de guardar el cambio en la auditoria con su correlativo.
    INSERT INTO LEHZ_AUDITORIA (
        ID_AUDITORIA, TABLA_AFECTADA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_BD, FECHA_EVENTO
    ) VALUES (
        LEHZ_SEQ_AUDITORIA.NEXTVAL,
        'LEHZ_BUS',
        v_operacion,
        COALESCE(:NEW.PATENTE_BUS, :OLD.PATENTE_BUS),
        v_detalle,
        USER,
        SYSTIMESTAMP
    );
END;
/


CREATE OR REPLACE TRIGGER LEHZ_TRG_AUDITORIA_MANTENCIONES
AFTER INSERT OR UPDATE OR DELETE 
ON LEHZ_MANTENCION
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(15);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle   := 'Se registro mantencion ID: ' || :NEW.ID_MANTENCION || ' para el bus: ' || :NEW.PATENTE_BUS || ' con costo: ' || :NEW.COSTO_MANTENCION;
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_detalle   := 'Se modifico la mantencion ID: ' || :OLD.ID_MANTENCION || ' (Costo anterior: ' || :OLD.COSTO_MANTENCION || ' -> Nuevo costo: ' || :NEW.COSTO_MANTENCION || ')';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle   := 'Se elimino el registro de mantencion ID: ' || :OLD.ID_MANTENCION;
    END IF;

    INSERT INTO LEHZ_AUDITORIA (
        ID_AUDITORIA, TABLA_AFECTADA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_BD, FECHA_EVENTO
    ) VALUES (
        LEHZ_SEQ_AUDITORIA.NEXTVAL,
        'LEHZ_MANTENCION',
        v_operacion,
        TO_CHAR(COALESCE(:NEW.ID_MANTENCION, :OLD.ID_MANTENCION)),
        v_detalle,
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_VALIDAR_FECHA_MANTENCION
BEFORE INSERT OR UPDATE
ON LEHZ_MANTENCION
FOR EACH ROW
DECLARE
    v_asignaciones NUMBER := 0;
BEGIN
    IF :NEW.FECHA_MANTENCION IS NULL THEN
        RAISE_APPLICATION_ERROR(-20213, 'La fecha de la mantencion es obligatoria.');
    END IF;
    IF TRUNC(:NEW.FECHA_MANTENCION) > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20213, 'La fecha de la mantencion no puede ser mayor a la fecha actual.');
    END IF;
    IF :NEW.DESCRIPCION_MANTENCION IS NULL OR TRIM(:NEW.DESCRIPCION_MANTENCION) = '' THEN
        RAISE_APPLICATION_ERROR(-20213, 'La descripcion de la mantencion es obligatoria.');
    END IF;
    IF :NEW.COSTO_MANTENCION IS NULL OR :NEW.COSTO_MANTENCION < 0 THEN
        RAISE_APPLICATION_ERROR(-20213, 'El costo de la mantencion debe ser mayor o igual a cero.');
    END IF;

    SELECT COUNT(*)
      INTO v_asignaciones
      FROM LEHZ_CONDUCE c
      INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = c.ID_VIAJE
     WHERE c.PATENTE_BUS = :NEW.PATENTE_BUS
       AND TRUNC(v.FECHA_VIAJE) = TRUNC(:NEW.FECHA_MANTENCION);

    IF v_asignaciones > 0 THEN
        RAISE_APPLICATION_ERROR(-20213, 'No se puede registrar la mantencion: el bus esta asignado a un viaje en esa fecha.');
    END IF;
END;
/