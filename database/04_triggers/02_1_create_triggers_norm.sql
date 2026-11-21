-- ============================================================================
-- [NUEVO - 02_1] NORMALIZACION (INITCAP) Y VALIDACION CHILENA (RUT + TEL +56)
-- Complementa a 02_create_triggers.sql sin modificar el archivo original.
-- ============================================================================
ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ----------------------------------------------------------------------------
-- 1. [NUEVO] Funcion de Normalizacion de Textos (Primera letra mayuscula)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_NORMALIZAR_TEXTO (
    p_texto IN VARCHAR2
) RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
    IF p_texto IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN INITCAP(LOWER(REGEXP_REPLACE(TRIM(p_texto), '\s+', ' ')));
END;
/

-- ----------------------------------------------------------------------------
-- 2. [NUEVO] Funcion Validadora de RUT Chileno (Modulo 11, DV 0-9/K, Persona/Empresa)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_VALIDAR_RUT_CL (
    p_rut          IN VARCHAR2,
    p_tipo_entidad IN VARCHAR2 -- 'PERSONA' (< 50.000.000) o 'EMPRESA' (>= 50.000.000)
) RETURN VARCHAR2 IS
    v_clean   VARCHAR2(20);
    v_cuerpo  VARCHAR2(15);
    v_dv_ing  CHAR(1);
    v_dv_calc CHAR(1);
    v_num     NUMBER;
    v_suma    NUMBER := 0;
    v_mult    NUMBER := 2;
    v_resto   NUMBER;
BEGIN
    IF p_rut IS NULL OR TRIM(p_rut) = '' THEN
        RAISE_APPLICATION_ERROR(-20010, 'El RUT es obligatorio.');
    END IF;

    -- Elimina puntos, guiones o espacios y pasa K a mayuscula
    v_clean := UPPER(REGEXP_REPLACE(TRIM(p_rut), '[^0-9K]', ''));
    IF LENGTH(v_clean) < 8 OR LENGTH(v_clean) > 9 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT inválido: debe tener 7 u 8 dígitos más su dígito verificador (ej. 12.345.678-K).');
    END IF;

    v_cuerpo := SUBSTR(v_clean, 1, LENGTH(v_clean) - 1);
    v_dv_ing := SUBSTR(v_clean, -1, 1);

    IF NOT REGEXP_LIKE(v_cuerpo, '^[0-9]+$') THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT inválido: el cuerpo del RUT solo debe contener números.');
    END IF;

    v_num := TO_NUMBER(v_cuerpo);

    IF UPPER(p_tipo_entidad) = 'PERSONA' AND v_num >= 50000000 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT inválido para persona natural: los RUT iguales o superiores a 50.000.000 corresponden a empresas.');
    ELSIF UPPER(p_tipo_entidad) = 'EMPRESA' AND v_num < 50000000 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT inválido para empresa: debe ser igual o superior a 50.000.000.');
    END IF;

    -- Calculo Modulo 11
    FOR i IN REVERSE 1..LENGTH(v_cuerpo) LOOP
        v_suma := v_suma + (TO_NUMBER(SUBSTR(v_cuerpo, i, 1)) * v_mult);
        v_mult := CASE WHEN v_mult = 7 THEN 2 ELSE v_mult + 1 END;
    END LOOP;

    v_resto   := 11 - MOD(v_suma, 11);
    v_dv_calc := CASE v_resto WHEN 11 THEN '0' WHEN 10 THEN 'K' ELSE TO_CHAR(v_resto) END;

    IF v_dv_ing <> v_dv_calc THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT inválido: el dígito verificador ingresado (' || v_dv_ing || ') no corresponde; debería ser ' || v_dv_calc || '.');
    END IF;

    -- Devuelve estandarizado sin puntos y con guion (ej. 12345678-K)
    RETURN TO_CHAR(v_num) || '-' || v_dv_calc;
END;
/

-- ----------------------------------------------------------------------------
-- 3. [NUEVO] Funcion Validadora de Telefono Chileno (+56)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_VALIDAR_TEL_CL (
    p_telefono     IN VARCHAR2,
    p_tipo_entidad IN VARCHAR2 -- 'PERSONA' (+569XXXXXXXX) o 'EMPRESA' (+56[2-9]XXXXXXXX)
) RETURN VARCHAR2 IS
    v_tel VARCHAR2(20) := REGEXP_REPLACE(TRIM(p_telefono), '\s+', '');
BEGIN
    IF v_tel IS NULL THEN
        RETURN NULL;
    END IF;

    IF UPPER(p_tipo_entidad) = 'PERSONA' THEN
        IF NOT REGEXP_LIKE(v_tel, '^\+569[0-9]{8}$') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Teléfono personal inválido: debe tener formato móvil chileno +569 seguido de 8 dígitos (ej. +56912345678).');
        END IF;
    ELSE
        IF NOT REGEXP_LIKE(v_tel, '^\+56[2-9][0-9]{8}$') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Teléfono de empresa inválido: debe iniciar con +56 y tener 9 dígitos válidos (ej. +56712234455 o +56912345678).');
        END IF;
    END IF;

    RETURN v_tel;
END;
/

-- ----------------------------------------------------------------------------
-- 4. [NUEVO] Triggers de Normalizacion y Validacion por Tabla
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_VAL_USUARIO
BEFORE INSERT OR UPDATE OF NOMBRE_COMPLETO ON LEHZ_USUARIO
FOR EACH ROW
BEGIN
    :NEW.NOMBRE_COMPLETO := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_COMPLETO);
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_VAL_EMPRESA
BEFORE INSERT OR UPDATE ON LEHZ_EMPRESA
FOR EACH ROW
BEGIN
    :NEW.RUT_EMPRESA      := LEHZ_FN_VALIDAR_RUT_CL(:NEW.RUT_EMPRESA, 'EMPRESA');
    :NEW.RAZON_SOCIAL     := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.RAZON_SOCIAL);
    :NEW.TELEFONO_EMPRESA := LEHZ_FN_VALIDAR_TEL_CL(:NEW.TELEFONO_EMPRESA, 'EMPRESA');
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_VAL_CONDUCTOR
BEFORE INSERT OR UPDATE ON LEHZ_CONDUCTOR
FOR EACH ROW
BEGIN
    :NEW.RUT_CONDUCTOR       := LEHZ_FN_VALIDAR_RUT_CL(:NEW.RUT_CONDUCTOR, 'PERSONA');
    :NEW.NOMBRE_CONDUCTOR    := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_CONDUCTOR);
    :NEW.APELLIDO1_CONDUCTOR := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.APELLIDO1_CONDUCTOR);
    :NEW.APELLIDO2_CONDUCTOR := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.APELLIDO2_CONDUCTOR);
    :NEW.TELEFONO            := LEHZ_FN_VALIDAR_TEL_CL(:NEW.TELEFONO, 'PERSONA');
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_VAL_MECANICO
BEFORE INSERT OR UPDATE ON LEHZ_MECANICO
FOR EACH ROW
BEGIN
    :NEW.RUT_MECANICO       := LEHZ_FN_VALIDAR_RUT_CL(:NEW.RUT_MECANICO, 'PERSONA');
    :NEW.NOMBRE_MECANICO    := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_MECANICO);
    :NEW.APELLIDO1_MECANICO := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.APELLIDO1_MECANICO);
    :NEW.APELLIDO2_MECANICO := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.APELLIDO2_MECANICO);
    :NEW.ESPECIALIDAD       := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.ESPECIALIDAD);
    :NEW.TELEFONO           := LEHZ_FN_VALIDAR_TEL_CL(:NEW.TELEFONO, 'PERSONA');
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_VAL_PASAJERO
BEFORE INSERT OR UPDATE ON LEHZ_PASAJERO
FOR EACH ROW
BEGIN
    :NEW.RUT_PASAJERO       := LEHZ_FN_VALIDAR_RUT_CL(:NEW.RUT_PASAJERO, 'PERSONA');
    :NEW.NOMBRE_PASAJERO    := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_PASAJERO);
    :NEW.APELLIDO1_PASAJERO := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.APELLIDO1_PASAJERO);
    :NEW.APELLIDO2_PASAJERO := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.APELLIDO2_PASAJERO);
    :NEW.TELEFONO           := LEHZ_FN_VALIDAR_TEL_CL(:NEW.TELEFONO, 'PERSONA');
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_REGION
BEFORE INSERT OR UPDATE OF NOMBRE_REGION ON LEHZ_REGION
FOR EACH ROW
BEGIN
    :NEW.NOMBRE_REGION := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_REGION);
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_COMUNA
BEFORE INSERT OR UPDATE OF NOMBRE_COMUNA ON LEHZ_COMUNA
FOR EACH ROW
BEGIN
    :NEW.NOMBRE_COMUNA := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_COMUNA);
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_TERMINAL
BEFORE INSERT OR UPDATE OF NOMBRE ON LEHZ_TERMINAL
FOR EACH ROW
BEGIN
    :NEW.NOMBRE := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE);
END;
/