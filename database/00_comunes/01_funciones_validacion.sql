ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- =========================================================================
-- FUNCIONES COMUNES DE NORMALIZACION Y VALIDACION
-- Toda la logica de negocio de textos, RUT, telefonos y correos vive aqui.
-- La aplicacion PHP solo muestra mensajes devueltos por Oracle.
-- =========================================================================

-- -------------------------------------------------------------------------
-- Convierte un texto a formato titulo: primera letra de cada palabra en
-- mayuscula y el resto en minuscula. Los conectores (de, del, la, los...)
-- se mantienen en minuscula cuando no son la primera palabra.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_TITULO(p_texto IN VARCHAR2) RETURN VARCHAR2 IS
    v_texto   VARCHAR2(4000);
    v_salida  VARCHAR2(4000);
    v_palabra VARCHAR2(200);
    v_pos     NUMBER := 1;
BEGIN
    IF p_texto IS NULL THEN
        RETURN NULL;
    END IF;

    v_texto := TRIM(REGEXP_REPLACE(p_texto, '[[:space:]]+', ' '));
    IF v_texto IS NULL THEN
        RETURN NULL;
    END IF;

    LOOP
        v_palabra := REGEXP_SUBSTR(v_texto, '[^ ]+', 1, v_pos);
        EXIT WHEN v_palabra IS NULL;

        IF v_pos > 1 AND LOWER(v_palabra) IN
           ('de', 'del', 'la', 'las', 'los', 'el', 'y', 'e', 'o', 'u', 'al', 'da', 'das', 'do', 'dos') THEN
            v_palabra := LOWER(v_palabra);
        ELSE
            v_palabra := INITCAP(v_palabra);
        END IF;

        v_salida := v_salida || CASE WHEN v_pos = 1 THEN '' ELSE ' ' END || v_palabra;
        v_pos := v_pos + 1;
    END LOOP;

    RETURN v_salida;
END LEHZ_FN_TITULO;
/

-- -------------------------------------------------------------------------
-- Calcula el digito verificador de un RUT chileno (modulo 11).
-- Retorna 0-9 o K. Retorna NULL si el cuerpo no es numerico.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_DV_RUT(p_cuerpo IN VARCHAR2) RETURN VARCHAR2 IS
    v_suma          NUMBER := 0;
    v_multiplicador NUMBER := 2;
    v_resto         NUMBER;
    v_dv            NUMBER;
BEGIN
    IF p_cuerpo IS NULL OR NOT REGEXP_LIKE(p_cuerpo, '^[0-9]+$') THEN
        RETURN NULL;
    END IF;

    FOR i IN REVERSE 1 .. LENGTH(p_cuerpo) LOOP
        v_suma := v_suma + TO_NUMBER(SUBSTR(p_cuerpo, i, 1)) * v_multiplicador;
        IF v_multiplicador = 7 THEN
            v_multiplicador := 2;
        ELSE
            v_multiplicador := v_multiplicador + 1;
        END IF;
    END LOOP;

    v_resto := MOD(v_suma, 11);
    v_dv    := 11 - v_resto;

    IF v_dv = 11 THEN
        RETURN '0';
    ELSIF v_dv = 10 THEN
        RETURN 'K';
    ELSE
        RETURN TO_CHAR(v_dv);
    END IF;
END LEHZ_FN_DV_RUT;
/

-- -------------------------------------------------------------------------
-- Normaliza un RUT al formato canonico CUERPO-DV, sin puntos ni espacios.
-- Acepta: 12345678-9, 12.345.678-9, 123456789, 12345678K, 20000003-K.
-- Si el usuario omite el DV, se calcula automaticamente.
-- Retorna NULL si el cuerpo no tiene 7 u 8 digitos.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_NORMALIZAR_RUT(p_rut IN VARCHAR2) RETURN VARCHAR2 IS
    v_limpio VARCHAR2(30);
    v_cuerpo VARCHAR2(10);
    v_dv     VARCHAR2(1);
    v_parte  VARCHAR2(30);
BEGIN
    IF p_rut IS NULL OR TRIM(p_rut) IS NULL THEN
        RETURN NULL;
    END IF;

    v_limpio := UPPER(TRIM(p_rut));

    IF INSTR(v_limpio, '-') > 0 THEN
        v_parte  := SUBSTR(v_limpio, 1, INSTR(v_limpio, '-') - 1);
        v_cuerpo := REGEXP_REPLACE(v_parte, '[^0-9]', '');
        v_dv     := REGEXP_REPLACE(SUBSTR(v_limpio, INSTR(v_limpio, '-') + 1), '[^0-9K]', '');
        IF LENGTH(v_dv) > 1 THEN
            v_dv := SUBSTR(v_dv, 1, 1);
        END IF;
        IF v_dv = '' THEN
            v_dv := NULL;
        END IF;
    ELSE
        v_parte := REGEXP_REPLACE(v_limpio, '[^0-9K]', '');
        IF SUBSTR(v_parte, -1) = 'K' THEN
            v_cuerpo := SUBSTR(v_parte, 1, LENGTH(v_parte) - 1);
            v_dv     := 'K';
        ELSIF LENGTH(v_parte) >= 9 THEN
            v_cuerpo := SUBSTR(v_parte, 1, LENGTH(v_parte) - 1);
            v_dv     := SUBSTR(v_parte, -1);
        ELSE
            v_cuerpo := v_parte;
            v_dv     := NULL;
        END IF;
    END IF;

    IF v_cuerpo IS NULL OR NOT REGEXP_LIKE(v_cuerpo, '^[0-9]{7,8}$') THEN
        RETURN NULL;
    END IF;

    IF v_dv IS NULL THEN
        v_dv := LEHZ_FN_DV_RUT(v_cuerpo);
    END IF;

    RETURN v_cuerpo || '-' || v_dv;
END LEHZ_FN_NORMALIZAR_RUT;
/

-- -------------------------------------------------------------------------
-- Valida un RUT segun su tipo:
--   EMPRESA : cuerpo entre 50.000.000 y 99.999.999 (persona juridica)
--   PERSONA : cuerpo entre 1.000.000 y 49.999.999 (persona natural)
-- Retorna NULL si es valido o el mensaje de error listo para mostrar.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_ERROR_RUT(
    p_rut  IN VARCHAR2,
    p_tipo IN VARCHAR2
) RETURN VARCHAR2 IS
    v_normal VARCHAR2(20);
    v_cuerpo VARCHAR2(10);
    v_dv     VARCHAR2(1);
    v_tipo   VARCHAR2(10);
    v_num    NUMBER;
BEGIN
    v_tipo := UPPER(TRIM(p_tipo));

    IF p_rut IS NULL OR TRIM(p_rut) IS NULL THEN
        RETURN 'El RUT es obligatorio.';
    END IF;

    v_normal := LEHZ_FN_NORMALIZAR_RUT(p_rut);
    IF v_normal IS NULL THEN
        RETURN 'RUT invalido: debe tener entre 7 y 8 digitos y digito verificador (0-9 o K). Ejemplo: 12345678-9.';
    END IF;

    v_cuerpo := SUBSTR(v_normal, 1, INSTR(v_normal, '-') - 1);
    v_dv     := SUBSTR(v_normal, INSTR(v_normal, '-') + 1);

    IF v_dv <> LEHZ_FN_DV_RUT(v_cuerpo) THEN
        RETURN 'RUT invalido: el digito verificador no corresponde. Para el cuerpo ' ||
               v_cuerpo || ' el DV correcto es ' || LEHZ_FN_DV_RUT(v_cuerpo) || '.';
    END IF;

    v_num := TO_NUMBER(v_cuerpo);

    IF v_tipo = 'EMPRESA' THEN
        IF v_num < 50000000 THEN
            RETURN 'RUT de empresa invalido: el cuerpo debe estar entre 50.000.000 y 99.999.999 (persona juridica).';
        END IF;
    ELSIF v_tipo = 'PERSONA' THEN
        IF v_num >= 50000000 THEN
            RETURN 'RUT personal invalido: el cuerpo debe ser menor a 50.000.000. Ese rango corresponde a una empresa.';
        ELSIF v_num < 1000000 THEN
            RETURN 'RUT personal invalido: el cuerpo debe ser mayor o igual a 1.000.000.';
        END IF;
    ELSE
        RETURN 'Tipo de RUT no reconocido. Debe ser PERSONA o EMPRESA.';
    END IF;

    RETURN NULL;
END LEHZ_FN_ERROR_RUT;
/

-- -------------------------------------------------------------------------
-- Normaliza telefonos chilenos al formato +56XXXXXXXX o +56XXXXXXXXX.
-- Acepta +56, 56, 0056, espacios, guiones, puntos y parentesis.
-- Formatos nacionales validos:
--   Movil          : 9XXXXXXXX   (9 digitos)
--   Santiago fijo  : 2XXXXXXXX   (9 digitos)
--   Region fijo    : [3-7]XXXXXXX (8 digitos, ej. 71234455)
-- Retorna NULL si no es un telefono chileno valido.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_NORMALIZAR_TELEFONO(p_telefono IN VARCHAR2) RETURN VARCHAR2 IS
    v VARCHAR2(40);
BEGIN
    IF p_telefono IS NULL OR TRIM(p_telefono) IS NULL THEN
        RETURN NULL;
    END IF;

    v := TRIM(p_telefono);
    v := REPLACE(v, ' ', '');
    v := REPLACE(v, '-', '');
    v := REPLACE(v, '.', '');
    v := REPLACE(v, '(', '');
    v := REPLACE(v, ')', '');
    v := UPPER(v);

    IF v LIKE '+56%' THEN
        v := SUBSTR(v, 4);
    ELSIF v LIKE '0056%' THEN
        v := SUBSTR(v, 5);
    ELSIF v LIKE '56%' AND LENGTH(v) > 9 THEN
        v := SUBSTR(v, 3);
    END IF;

    v := REGEXP_REPLACE(v, '[^0-9]', '');

    IF REGEXP_LIKE(v, '^(9[0-9]{8}|2[0-9]{8}|[3-7][0-9]{7})$') THEN
        RETURN '+56' || v;
    END IF;

    RETURN NULL;
END LEHZ_FN_NORMALIZAR_TELEFONO;
/

-- -------------------------------------------------------------------------
-- Valida un telefono segun su tipo:
--   EMPRESA : fijo Santiago, fijo regional o movil
--   PERSONA : solo movil +56 9 XXXXXXXX
-- Retorna NULL si es valido o el mensaje de error.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_ERROR_TELEFONO(
    p_telefono IN VARCHAR2,
    p_tipo     IN VARCHAR2
) RETURN VARCHAR2 IS
    v_normal  VARCHAR2(20);
    v_nacional VARCHAR2(10);
    v_tipo    VARCHAR2(10);
BEGIN
    v_tipo := UPPER(TRIM(p_tipo));

    IF p_telefono IS NULL OR TRIM(p_telefono) IS NULL THEN
        RETURN 'El telefono es obligatorio.';
    END IF;

    v_normal := LEHZ_FN_NORMALIZAR_TELEFONO(p_telefono);
    IF v_normal IS NULL THEN
        RETURN 'Telefono invalido: usa un numero chileno de 8 o 9 digitos. ' ||
               'Movil: +56 9 1234 5678. Fijo Santiago: +56 2 2345 6789. Fijo region: +56 71 234 455.';
    END IF;

    v_nacional := SUBSTR(v_normal, 4);

    IF v_tipo = 'PERSONA' THEN
        IF SUBSTR(v_nacional, 1, 1) <> '9' THEN
            RETURN 'Telefono personal invalido: debe ser un celular chileno con formato +56 9 XXXX XXXX.';
        END IF;
    ELSIF v_tipo <> 'EMPRESA' THEN
        RETURN 'Tipo de telefono no reconocido. Debe ser PERSONA o EMPRESA.';
    END IF;

    RETURN NULL;
END LEHZ_FN_ERROR_TELEFONO;
/

-- -------------------------------------------------------------------------
-- Valida un correo electronico. p_obligatorio = 'S' lo exige.
-- Retorna NULL si es valido o el mensaje de error.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_ERROR_EMAIL(
    p_email       IN VARCHAR2,
    p_obligatorio IN VARCHAR2 DEFAULT 'N'
) RETURN VARCHAR2 IS
BEGIN
    IF p_email IS NULL OR TRIM(p_email) IS NULL THEN
        IF UPPER(TRIM(p_obligatorio)) = 'S' THEN
            RETURN 'El correo electronico es obligatorio.';
        END IF;
        RETURN NULL;
    END IF;

    IF LENGTH(TRIM(p_email)) > 80 THEN
        RETURN 'Correo electronico invalido: no puede superar los 80 caracteres.';
    END IF;

    IF NOT REGEXP_LIKE(TRIM(p_email), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
        RETURN 'Correo electronico invalido. Ejemplo: nombre.apellido@dominio.cl';
    END IF;

    RETURN NULL;
END LEHZ_FN_ERROR_EMAIL;
/

-- -------------------------------------------------------------------------
-- Valida que un texto obligatorio no venga vacio.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LEHZ_FN_ERROR_TEXTO(
    p_texto IN VARCHAR2,
    p_campo IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    IF p_texto IS NULL OR TRIM(p_texto) IS NULL THEN
        RETURN 'El campo ' || p_campo || ' es obligatorio.';
    END IF;
    RETURN NULL;
END LEHZ_FN_ERROR_TEXTO;
/
