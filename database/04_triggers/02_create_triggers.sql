ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- =========================================================================
-- TRIGGERS DE NORMALIZACION, VALIDACION Y AUDITORIA
-- La base de datos es la unica responsable de aceptar o rechazar datos.
-- =========================================================================

-- ------------------------- REGION ---------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_REGION_BIU
BEFORE INSERT OR UPDATE ON LEHZ_REGION
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.NOMBRE_REGION := LEHZ_FN_TITULO(:NEW.NOMBRE_REGION);
    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE_REGION, 'nombre de la region');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20010, v_error);
    END IF;
END;
/

-- ------------------------- COMUNA ---------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_COMUNA_BIU
BEFORE INSERT OR UPDATE ON LEHZ_COMUNA
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.NOMBRE_COMUNA := LEHZ_FN_TITULO(:NEW.NOMBRE_COMUNA);
    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE_COMUNA, 'nombre de la comuna');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20011, v_error);
    END IF;
END;
/

-- ------------------------- EMPRESA --------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_EMPRESA_BIU
BEFORE INSERT OR UPDATE ON LEHZ_EMPRESA
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.RUT_EMPRESA  := LEHZ_FN_NORMALIZAR_RUT(:NEW.RUT_EMPRESA);
    :NEW.RAZON_SOCIAL := LEHZ_FN_TITULO(:NEW.RAZON_SOCIAL);
    :NEW.TELEFONO_EMPRESA := LEHZ_FN_NORMALIZAR_TELEFONO(:NEW.TELEFONO_EMPRESA);
    :NEW.CORREO_ELECTRONICO_EMPRESA := LOWER(TRIM(:NEW.CORREO_ELECTRONICO_EMPRESA));

    v_error := LEHZ_FN_ERROR_RUT(:NEW.RUT_EMPRESA, 'EMPRESA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20012, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.RAZON_SOCIAL, 'razon social');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20013, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TELEFONO(:NEW.TELEFONO_EMPRESA, 'EMPRESA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20014, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_EMAIL(:NEW.CORREO_ELECTRONICO_EMPRESA, 'N');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20015, v_error);
    END IF;
END;
/

-- ------------------------- PASAJERO -------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_PASAJERO_BIU
BEFORE INSERT OR UPDATE ON LEHZ_PASAJERO
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.RUT_PASAJERO     := LEHZ_FN_NORMALIZAR_RUT(:NEW.RUT_PASAJERO);
    :NEW.NOMBRE_PASAJERO  := LEHZ_FN_TITULO(:NEW.NOMBRE_PASAJERO);
    :NEW.APELLIDO1_PASAJERO := LEHZ_FN_TITULO(:NEW.APELLIDO1_PASAJERO);
    :NEW.APELLIDO2_PASAJERO := LEHZ_FN_TITULO(:NEW.APELLIDO2_PASAJERO);
    :NEW.TELEFONO_PASAJERO := LEHZ_FN_NORMALIZAR_TELEFONO(:NEW.TELEFONO_PASAJERO);
    :NEW.CORREO_ELECTRONICO_PASAJERO := LOWER(TRIM(:NEW.CORREO_ELECTRONICO_PASAJERO));

    v_error := LEHZ_FN_ERROR_RUT(:NEW.RUT_PASAJERO, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20016, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE_PASAJERO, 'nombre');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20017, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.APELLIDO1_PASAJERO, 'primer apellido');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20018, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TELEFONO(:NEW.TELEFONO_PASAJERO, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20019, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_EMAIL(:NEW.CORREO_ELECTRONICO_PASAJERO, 'N');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20020, v_error);
    END IF;
END;
/

-- ------------------------- CONDUCTOR ------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_CONDUCTOR_BIU
BEFORE INSERT OR UPDATE ON LEHZ_CONDUCTOR
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.RUT_CONDUCTOR    := LEHZ_FN_NORMALIZAR_RUT(:NEW.RUT_CONDUCTOR);
    :NEW.NOMBRE_CONDUCTOR := LEHZ_FN_TITULO(:NEW.NOMBRE_CONDUCTOR);
    :NEW.APELLIDO1_CONDUCTOR := LEHZ_FN_TITULO(:NEW.APELLIDO1_CONDUCTOR);
    :NEW.APELLIDO2_CONDUCTOR := LEHZ_FN_TITULO(:NEW.APELLIDO2_CONDUCTOR);
    :NEW.TELEFONO_CONDUCTOR := LEHZ_FN_NORMALIZAR_TELEFONO(:NEW.TELEFONO_CONDUCTOR);
    :NEW.TIPO_LICENCIA := UPPER(TRIM(:NEW.TIPO_LICENCIA));

    v_error := LEHZ_FN_ERROR_RUT(:NEW.RUT_CONDUCTOR, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20021, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE_CONDUCTOR, 'nombre');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20022, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.APELLIDO1_CONDUCTOR, 'primer apellido');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20023, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TELEFONO(:NEW.TELEFONO_CONDUCTOR, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20024, v_error);
    END IF;
END;
/

-- ------------------------- MECANICO -------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_MECANICO_BIU
BEFORE INSERT OR UPDATE ON LEHZ_MECANICO
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.RUT_MECANICO     := LEHZ_FN_NORMALIZAR_RUT(:NEW.RUT_MECANICO);
    :NEW.NOMBRE_MECANICO  := LEHZ_FN_TITULO(:NEW.NOMBRE_MECANICO);
    :NEW.APELLIDO1_MECANICO := LEHZ_FN_TITULO(:NEW.APELLIDO1_MECANICO);
    :NEW.APELLIDO2_MECANICO := LEHZ_FN_TITULO(:NEW.APELLIDO2_MECANICO);
    :NEW.TELEFONO_MECANICO := LEHZ_FN_NORMALIZAR_TELEFONO(:NEW.TELEFONO_MECANICO);
    :NEW.ESPECIALIDAD     := LEHZ_FN_TITULO(:NEW.ESPECIALIDAD);

    v_error := LEHZ_FN_ERROR_RUT(:NEW.RUT_MECANICO, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20025, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE_MECANICO, 'nombre');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20026, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.APELLIDO1_MECANICO, 'primer apellido');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20027, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_TELEFONO(:NEW.TELEFONO_MECANICO, 'PERSONA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20028, v_error);
    END IF;
END;
/

-- ------------------------- TERMINAL -------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_TERMINAL_BIU
BEFORE INSERT OR UPDATE ON LEHZ_TERMINAL
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.NOMBRE := LEHZ_FN_TITULO(:NEW.NOMBRE);
    :NEW.CALLE  := LEHZ_FN_TITULO(:NEW.CALLE);

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE, 'nombre del terminal');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20029, v_error);
    END IF;

    IF :NEW.NUMERO IS NOT NULL AND :NEW.NUMERO <= 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'El numero de la direccion debe ser mayor que cero.');
    END IF;
END;
/

-- ------------------------- BUS ------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_BUS_BIU
BEFORE INSERT OR UPDATE ON LEHZ_BUS
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.PATENTE_BUS := UPPER(TRIM(:NEW.PATENTE_BUS));
    :NEW.MARCA       := LEHZ_FN_TITULO(:NEW.MARCA);
    :NEW.MODELO      := TRIM(:NEW.MODELO);
    :NEW.RUT_EMPRESA := LEHZ_FN_NORMALIZAR_RUT(:NEW.RUT_EMPRESA);

    IF :NEW.PATENTE_BUS IS NULL OR NOT REGEXP_LIKE(:NEW.PATENTE_BUS, '^[A-Z0-9]{6}$') THEN
        RAISE_APPLICATION_ERROR(-20031,
            'Patente invalida: debe tener 6 caracteres alfanumericos sin guion. Ejemplo: ABCD12.');
    END IF;

    v_error := LEHZ_FN_ERROR_RUT(:NEW.RUT_EMPRESA, 'EMPRESA');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20032, v_error);
    END IF;

    IF :NEW.ANIO_FABRICACION IS NOT NULL AND :NEW.ANIO_FABRICACION NOT BETWEEN 1950 AND 2100 THEN
        RAISE_APPLICATION_ERROR(-20033, 'Anio de fabricacion invalido: debe estar entre 1950 y 2100.');
    END IF;

    IF :NEW.CAPACIDAD IS NOT NULL AND :NEW.CAPACIDAD NOT BETWEEN 1 AND 100 THEN
        RAISE_APPLICATION_ERROR(-20034, 'Capacidad invalida: debe estar entre 1 y 100 asientos.');
    END IF;
END;
/

-- ------------------------- RUTA -----------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_RUTA_BIU
BEFORE INSERT OR UPDATE ON LEHZ_RUTA
FOR EACH ROW
BEGIN
    IF :NEW.ID_COMUNA_ORIGEN IS NULL OR :NEW.ID_COMUNA_DESTINO IS NULL THEN
        RAISE_APPLICATION_ERROR(-20035, 'Debes indicar la ciudad de origen y la ciudad de destino de la ruta.');
    END IF;

    IF :NEW.ID_COMUNA_ORIGEN = :NEW.ID_COMUNA_DESTINO THEN
        RAISE_APPLICATION_ERROR(-20036, 'La ciudad de origen y la ciudad de destino deben ser diferentes.');
    END IF;

    IF :NEW.DISTANCIA IS NULL OR :NEW.DISTANCIA <= 0 THEN
        RAISE_APPLICATION_ERROR(-20037, 'La distancia de la ruta debe ser mayor que cero kilometros.');
    END IF;
END;
/

-- ------------------------- RUTA_PARADA ----------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_PARADA_BIU
BEFORE INSERT OR UPDATE ON LEHZ_RUTA_PARADA
FOR EACH ROW
BEGIN
    IF :NEW.ORDEN IS NULL OR :NEW.ORDEN < 1 THEN
        RAISE_APPLICATION_ERROR(-20038, 'El orden de la parada debe ser un numero mayor o igual a 1.');
    END IF;

    IF :NEW.DISTANCIA_DESDE_ORIGEN IS NULL OR :NEW.DISTANCIA_DESDE_ORIGEN < 0 THEN
        RAISE_APPLICATION_ERROR(-20039, 'La distancia de la parada no puede ser negativa.');
    END IF;

    IF :NEW.MINUTOS_DESDE_SALIDA IS NULL OR :NEW.MINUTOS_DESDE_SALIDA < 0 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Los minutos desde la salida no pueden ser negativos.');
    END IF;
END;
/

-- ------------------------- USUARIO --------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_USUARIO_BIU
BEFORE INSERT OR UPDATE ON LEHZ_USUARIO
FOR EACH ROW
DECLARE
    v_error VARCHAR2(400);
BEGIN
    :NEW.USERNAME        := LOWER(TRIM(:NEW.USERNAME));
    :NEW.NOMBRE_COMPLETO := LEHZ_FN_TITULO(:NEW.NOMBRE_COMPLETO);
    :NEW.EMAIL           := LOWER(TRIM(:NEW.EMAIL));
    :NEW.ESTADO          := UPPER(TRIM(:NEW.ESTADO));

    IF :NEW.USERNAME IS NULL OR NOT REGEXP_LIKE(:NEW.USERNAME, '^[a-z0-9._-]{4,40}$') THEN
        RAISE_APPLICATION_ERROR(-20041,
            'Usuario invalido: debe tener entre 4 y 40 caracteres y solo puede usar letras, numeros, punto, guion o guion bajo.');
    END IF;

    v_error := LEHZ_FN_ERROR_TEXTO(:NEW.NOMBRE_COMPLETO, 'nombre completo');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20042, v_error);
    END IF;

    v_error := LEHZ_FN_ERROR_EMAIL(:NEW.EMAIL, 'N');
    IF v_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20043, v_error);
    END IF;

    IF :NEW.PASSWORD_HASH IS NULL OR LENGTH(:NEW.PASSWORD_HASH) < 32 THEN
        RAISE_APPLICATION_ERROR(-20044, 'El hash de la contrasena no es valido.');
    END IF;

    IF :NEW.ESTADO NOT IN ('ACTIVO', 'INACTIVO') THEN
        RAISE_APPLICATION_ERROR(-20045, 'Estado de usuario invalido: debe ser ACTIVO o INACTIVO.');
    END IF;
END;
/

-- =========================================================================
-- TRIGGERS DE AUDITORIA
-- =========================================================================

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_BUS
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_BUS
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(15);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle   := 'Se registro el bus patente ' || :NEW.PATENTE_BUS || ', marca ' || :NEW.MARCA;
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_detalle   := 'Se actualizo el bus patente ' || :OLD.PATENTE_BUS || ' (modelo ' || :OLD.MODELO || ' -> ' || :NEW.MODELO || ')';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle   := 'Se elimino el bus patente ' || :OLD.PATENTE_BUS;
    END IF;

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

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_MANTENCION
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_MANTENCION
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(15);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle   := 'Mantencion ' || :NEW.ID_MANTENCION || ' del bus ' || :NEW.PATENTE_BUS || ' con costo ' || :NEW.COSTO_MANTENCION;
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_detalle   := 'Se modifico la mantencion ' || :OLD.ID_MANTENCION || ' (costo ' || :OLD.COSTO_MANTENCION || ' -> ' || :NEW.COSTO_MANTENCION || ')';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle   := 'Se elimino la mantencion ' || :OLD.ID_MANTENCION;
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

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_RUTA
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_RUTA
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(15);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle   := 'Se creo la ruta ' || :NEW.ID_RUTA || ' con distancia ' || :NEW.DISTANCIA || ' km';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_detalle   := 'Se actualizo la ruta ' || :OLD.ID_RUTA;
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle   := 'Se elimino la ruta ' || :OLD.ID_RUTA;
    END IF;

    INSERT INTO LEHZ_AUDITORIA (
        ID_AUDITORIA, TABLA_AFECTADA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_BD, FECHA_EVENTO
    ) VALUES (
        LEHZ_SEQ_AUDITORIA.NEXTVAL,
        'LEHZ_RUTA',
        v_operacion,
        TO_CHAR(COALESCE(:NEW.ID_RUTA, :OLD.ID_RUTA)),
        v_detalle,
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_AUD_USUARIO
AFTER INSERT OR UPDATE OR DELETE ON LEHZ_USUARIO
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(15);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle   := 'Se creo el usuario ' || :NEW.USERNAME || ' con rol ID ' || :NEW.ID_ROL;
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_detalle   := 'Se actualizo el usuario ' || :OLD.USERNAME || ' (estado ' || :OLD.ESTADO || ' -> ' || :NEW.ESTADO || ')';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle   := 'Se elimino el usuario ' || :OLD.USERNAME;
    END IF;

    INSERT INTO LEHZ_AUDITORIA (
        ID_AUDITORIA, TABLA_AFECTADA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_BD, FECHA_EVENTO
    ) VALUES (
        LEHZ_SEQ_AUDITORIA.NEXTVAL,
        'LEHZ_USUARIO',
        v_operacion,
        TO_CHAR(COALESCE(:NEW.ID_USUARIO, :OLD.ID_USUARIO)),
        v_detalle,
        USER,
        SYSTIMESTAMP
    );
END;
/

-- ------------------------- REGLA DE NEGOCIO -----------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_MANTENCION_FECHA
BEFORE INSERT OR UPDATE ON LEHZ_MANTENCION
FOR EACH ROW
BEGIN
    IF :NEW.FECHA_MANTENCION > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20046,
            'La fecha de la mantencion no puede ser posterior a la fecha actual.');
    END IF;
END;
/
