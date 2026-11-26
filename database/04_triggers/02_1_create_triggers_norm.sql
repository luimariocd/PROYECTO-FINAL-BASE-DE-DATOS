-- Esta parte del código se encarga de normalizar textos y validar RUT, telefono y patente.
ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- Esta parte del código se encarga de poner mayuscula la primera letra de cada palabra.
CREATE OR REPLACE FUNCTION LEHZ_FN_NORMALIZAR_TEXTO (
    p_texto IN VARCHAR2
) RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
    IF p_texto IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN INITCAP(LOWER(REGEXP_REPLACE(TRIM(p_texto), '[[:space:]]+', ' ')));
END;
/

-- Esta parte del código se encarga de normalizar y validar el RUT con modulo 11.
CREATE OR REPLACE FUNCTION LEHZ_FN_NORMALIZAR_RUT (
    p_rut          IN VARCHAR2,
    p_tipo_entidad IN VARCHAR2
) RETURN VARCHAR2 IS
    v_original VARCHAR2(30);
    v_clean    VARCHAR2(20);
    v_cuerpo   VARCHAR2(15);
    v_dv_ing   CHAR(1);
    v_dv_calc  CHAR(1);
    v_num      NUMBER;
    v_suma     NUMBER := 0;
    v_mult     NUMBER := 2;
    v_resto    NUMBER;
BEGIN
    IF p_rut IS NULL OR TRIM(p_rut) = '' THEN
        RAISE_APPLICATION_ERROR(-20010, 'El RUT es obligatorio.');
    END IF;

    v_original := UPPER(TRIM(p_rut));
    v_clean    := UPPER(REGEXP_REPLACE(v_original, '[^0-9K]', ''));

    IF LENGTH(v_clean) < 7 OR LENGTH(v_clean) > 9 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT invalido: debe tener 7 u 8 digitos mas su digito verificador (ej. 12.345.678-K).');
    END IF;

    IF INSTR(v_original, '-') > 0 OR SUBSTR(v_clean, -1, 1) = 'K' THEN
        v_cuerpo := SUBSTR(v_clean, 1, LENGTH(v_clean) - 1);
        v_dv_ing := SUBSTR(v_clean, -1, 1);
    ELSIF LENGTH(v_clean) = 9 THEN
        v_cuerpo := SUBSTR(v_clean, 1, 8);
        v_dv_ing := SUBSTR(v_clean, 9, 1);
    ELSE
        v_cuerpo := v_clean;
        v_dv_ing := NULL;
    END IF;

    IF LENGTH(v_cuerpo) < 7 OR LENGTH(v_cuerpo) > 8 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT invalido: el cuerpo debe tener 7 u 8 digitos.');
    END IF;

    IF NOT REGEXP_LIKE(v_cuerpo, '^[0-9]+$') THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT invalido: el cuerpo del RUT solo debe contener numeros.');
    END IF;

    v_num := TO_NUMBER(v_cuerpo);

    IF UPPER(p_tipo_entidad) = 'PERSONA' AND v_num >= 50000000 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT invalido para persona natural: los RUT iguales o superiores a 50.000.000 corresponden a empresas.');
    ELSIF UPPER(p_tipo_entidad) = 'EMPRESA' AND v_num < 50000000 THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT invalido para empresa: debe ser igual o superior a 50.000.000.');
    END IF;

    -- Esta parte del código se encarga de calcular el digito verificador con modulo 11.
    FOR i IN REVERSE 1..LENGTH(v_cuerpo) LOOP
        v_suma := v_suma + (TO_NUMBER(SUBSTR(v_cuerpo, i, 1)) * v_mult);
        v_mult := CASE WHEN v_mult = 7 THEN 2 ELSE v_mult + 1 END;
    END LOOP;

    v_resto   := 11 - MOD(v_suma, 11);
    v_dv_calc := CASE v_resto WHEN 11 THEN '0' WHEN 10 THEN 'K' ELSE TO_CHAR(v_resto) END;

    IF v_dv_ing IS NOT NULL AND v_dv_ing <> v_dv_calc THEN
        RAISE_APPLICATION_ERROR(-20010, 'RUT invalido: el digito verificador ingresado (' || v_dv_ing || ') no corresponde; deberia ser ' || v_dv_calc || '.');
    END IF;

    RETURN TO_CHAR(v_num, 'FM99999999') || '-' || v_dv_calc;
END;
/

-- Esta parte del código se encarga de mantener el nombre que usaban los scripts anteriores.
CREATE OR REPLACE FUNCTION LEHZ_FN_VALIDAR_RUT_CL (
    p_rut          IN VARCHAR2,
    p_tipo_entidad IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    RETURN LEHZ_FN_NORMALIZAR_RUT(p_rut, p_tipo_entidad);
END;
/

-- Esta parte del código se encarga de normalizar y validar el telefono chileno.
CREATE OR REPLACE FUNCTION LEHZ_FN_VALIDAR_TEL_CL (
    p_telefono     IN VARCHAR2,
    p_tipo_entidad IN VARCHAR2
) RETURN VARCHAR2 IS
    v_digits VARCHAR2(20);
    v_tel    VARCHAR2(20);
BEGIN
    IF p_telefono IS NULL OR TRIM(p_telefono) = '' THEN
        RETURN NULL;
    END IF;

    v_digits := REGEXP_REPLACE(TRIM(p_telefono), '[^0-9]', '');

    IF UPPER(p_tipo_entidad) = 'PERSONA' THEN
        IF LENGTH(v_digits) = 9 AND SUBSTR(v_digits, 1, 1) = '9' THEN
            v_tel := '+56' || v_digits;
        ELSIF LENGTH(v_digits) = 11 AND SUBSTR(v_digits, 1, 2) = '56'
              AND SUBSTR(v_digits, 3, 1) = '9' THEN
            v_tel := '+' || v_digits;
        ELSE
            v_tel := v_digits;
        END IF;

        IF NOT REGEXP_LIKE(v_tel, '^\+569[0-9]{8}$') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Telefono personal invalido: debe tener formato movil chileno +569 seguido de 8 digitos (ej. +56912345678).');
        END IF;
    ELSE
        -- Esta parte del código se encarga de aceptar 600 y 809 sin el prefijo +56.
        IF LENGTH(v_digits) = 9 AND SUBSTR(v_digits, 1, 3) IN ('600', '809') THEN
            v_tel := v_digits;
        ELSIF LENGTH(v_digits) = 9 AND SUBSTR(v_digits, 1, 1) BETWEEN '2' AND '9' THEN
            v_tel := '+56' || v_digits;
        ELSIF LENGTH(v_digits) = 11 AND SUBSTR(v_digits, 1, 2) = '56'
              AND SUBSTR(v_digits, 3, 1) BETWEEN '2' AND '9' THEN
            v_tel := '+' || v_digits;
        ELSE
            v_tel := v_digits;
        END IF;

        IF NOT REGEXP_LIKE(v_tel, '^(\+56[2-9][0-9]{8}|600[0-9]{6}|809[0-9]{6})$') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Telefono de empresa invalido: use +56 + 9 digitos, o un numero 600/809 de 9 digitos (ej. +56712345678, 600123456, 809123456).');
        END IF;
    END IF;

    RETURN v_tel;
END;
/

-- Esta parte del código se encarga de normalizar y validar la patente chilena.
CREATE OR REPLACE FUNCTION LEHZ_FN_NORMALIZAR_PATENTE (
    p_patente IN VARCHAR2
) RETURN VARCHAR2 IS
    v_pat VARCHAR2(10);
BEGIN
    IF p_patente IS NULL OR TRIM(p_patente) = '' THEN
        RAISE_APPLICATION_ERROR(-20012, 'La patente del bus es obligatoria.');
    END IF;

    v_pat := UPPER(REGEXP_REPLACE(TRIM(p_patente), '[^A-Za-z0-9]', ''));

    IF NOT REGEXP_LIKE(v_pat, '^([B-DF-HJ-NP-TV-Z]{4}[0-9]{2}|[A-Z]{2}[0-9]{4})$') THEN
        RAISE_APPLICATION_ERROR(-20012, 'Patente invalida: use formato nuevo de 4 letras sin vocales + 2 digitos (ej. BCDF12) o formato antiguo de 2 letras + 4 digitos (ej. AB1234).');
    END IF;

    RETURN v_pat;
END;
/

-- Esta parte del código se encarga de aplicar los triggers de normalizacion por tabla.
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

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_VAL_BUS
BEFORE INSERT OR UPDATE ON LEHZ_BUS
FOR EACH ROW
BEGIN
    :NEW.PATENTE_BUS   := LEHZ_FN_NORMALIZAR_PATENTE(:NEW.PATENTE_BUS);
    :NEW.MARCA         := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.MARCA);
    :NEW.MODELO        := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.MODELO);
    :NEW.TIPO_SERVICIO := UPPER(TRIM(:NEW.TIPO_SERVICIO));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_RUTA
BEFORE INSERT OR UPDATE OF NOMBRE_RUTA ON LEHZ_RUTA
FOR EACH ROW
BEGIN
    :NEW.NOMBRE_RUTA := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE_RUTA);
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_ASIENTO
BEFORE INSERT OR UPDATE OF UBICACION ON LEHZ_ASIENTO
FOR EACH ROW
BEGIN
    :NEW.UBICACION := UPPER(TRIM(:NEW.UBICACION));
END;
/

CREATE OR REPLACE TRIGGER LEHZ_TRG_NORM_PASAJE_BAJADA
BEFORE INSERT OR UPDATE OF OBSERVACION ON LEHZ_PASAJE_BAJADA
FOR EACH ROW
BEGIN
    :NEW.OBSERVACION := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.OBSERVACION);
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
BEFORE INSERT OR UPDATE OF NOMBRE, CALLE ON LEHZ_TERMINAL
FOR EACH ROW
BEGIN
    :NEW.NOMBRE := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.NOMBRE);
    :NEW.CALLE  := LEHZ_FN_NORMALIZAR_TEXTO(:NEW.CALLE);
END;
/
