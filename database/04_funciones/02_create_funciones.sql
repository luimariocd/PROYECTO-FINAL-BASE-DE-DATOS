-- Esta parte del código se encarga de crear todas las funciones PL/SQL del esquema LHAOMRJZ.
ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de poner mayuscula la primera letra de cada palabra.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_NORMALIZAR_TEXTO (
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
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_NORMALIZAR_RUT (
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
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_VALIDAR_RUT_CL (
    p_rut          IN VARCHAR2,
    p_tipo_entidad IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    RETURN LHAOMRJZ_FN_NORMALIZAR_RUT(p_rut, p_tipo_entidad);
END;
/

-- Esta parte del código se encarga de normalizar y validar el telefono chileno.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_VALIDAR_TEL_CL (
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
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_NORMALIZAR_PATENTE (
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

-- Esta parte del código se encarga de calcular la tarifa segun el tramo recorrido.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_CALCULAR_TARIFA_BUS (
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
      FROM LHAOMRJZ_VIAJE v
      INNER JOIN LHAOMRJZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
      INNER JOIN LHAOMRJZ_CONDUCE c ON c.ID_VIAJE = v.ID_VIAJE
      INNER JOIN LHAOMRJZ_BUS b ON b.PATENTE_BUS = c.PATENTE_BUS
     WHERE v.ID_VIAJE = p_id_viaje
       AND c.PATENTE_BUS = UPPER(TRIM(p_patente_bus))
       AND ROWNUM = 1;

    IF p_id_terminal_bajada IS NULL OR p_id_terminal_bajada = v_destino THEN
        RETURN v_base;
    END IF;

    SELECT rp.ORDEN_PARADA, rp.MINUTOS_DESDE_ORIG
      INTO v_orden, v_min_parada
      FROM LHAOMRJZ_RUTA_PARADA rp
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

-- Esta parte del código se encarga de calcular la tarifa cuando el bus no se indico explicitamente.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_CALCULAR_TARIFA (
    p_id_viaje           IN NUMBER,
    p_id_terminal_bajada IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_patente VARCHAR2(8);
BEGIN
    SELECT c.PATENTE_BUS
      INTO v_patente
      FROM LHAOMRJZ_CONDUCE c
     WHERE c.ID_VIAJE = p_id_viaje
       AND ROWNUM = 1;

    RETURN LHAOMRJZ_FN_CALCULAR_TARIFA_BUS(p_id_viaje, v_patente, p_id_terminal_bajada);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20103, 'El viaje no tiene un bus asignado; no es posible calcular la tarifa.');
END;
/

-- Esta parte del código se encarga de verificar la existencia de una comuna.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_COMUNA (
    p_id_comuna IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_COMUNA WHERE ID_COMUNA = p_id_comuna;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de una empresa.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_EMPRESA (
    p_rut_empresa IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_EMPRESA WHERE RUT_EMPRESA = p_rut_empresa;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un bus.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_BUS (
    p_patente_bus IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_BUS WHERE PATENTE_BUS = p_patente_bus;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un terminal.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_TERMINAL (
    p_id_terminal IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de una ruta.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_RUTA (
    p_id_ruta IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_RUTA WHERE ID_RUTA = p_id_ruta;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un horario.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_HORARIO (
    p_id_horario IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_HORARIO WHERE ID_HORARIO = p_id_horario;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un pasajero.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_PASAJERO (
    p_rut_pasajero IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_PASAJERO WHERE RUT_PASAJERO = p_rut_pasajero;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un viaje.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_VIAJE (
    p_id_viaje IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un mecanico.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_MECANICO (
    p_rut_mecanico IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_MECANICO WHERE RUT_MECANICO = p_rut_mecanico;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un conductor.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_CONDUCTOR (
    p_rut_conductor IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_CONDUCTOR WHERE RUT_CONDUCTOR = p_rut_conductor;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de contar los asientos registrados de un bus.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_CONTAR_ASIENTOS (
    p_patente_bus IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_ASIENTO WHERE PATENTE_BUS = p_patente_bus;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar la existencia de un asiento en un bus.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_EXISTE_ASIENTO (
    p_patente_bus    IN VARCHAR2,
    p_numero_asiento IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_ASIENTO
     WHERE PATENTE_BUS = p_patente_bus
       AND NUMERO_ASIENTO = p_numero_asiento;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar un orden de parada repetido en una ruta.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_PARADA_ORDEN_EXISTE (
    p_id_ruta    IN NUMBER,
    p_orden      IN NUMBER,
    p_id_actual  IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_RUTA_PARADA
     WHERE ID_RUTA = p_id_ruta
       AND ORDEN_PARADA = p_orden
       AND ID_RUTA_PARADA <> NVL(p_id_actual, -1);
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar un terminal repetido en una ruta.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_PARADA_TERMINAL_EXISTE (
    p_id_ruta      IN NUMBER,
    p_id_terminal  IN NUMBER,
    p_id_actual    IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_RUTA_PARADA
     WHERE ID_RUTA = p_id_ruta
       AND ID_TERMINAL = p_id_terminal
       AND ID_RUTA_PARADA <> NVL(p_id_actual, -1);
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar un viaje duplicado por ruta, fecha y horario.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_VIAJE_DUPLICADO (
    p_fecha_viaje IN DATE,
    p_id_horario  IN NUMBER,
    p_id_ruta     IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_VIAJE
     WHERE TRUNC(FECHA_VIAJE) = TRUNC(p_fecha_viaje)
       AND ID_HORARIO = p_id_horario
       AND ID_RUTA = p_id_ruta;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de obtener la fecha de un viaje.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_FECHA_VIAJE (
    p_id_viaje IN NUMBER
) RETURN DATE IS
    v_fecha DATE;
BEGIN
    SELECT FECHA_VIAJE INTO v_fecha FROM LHAOMRJZ_VIAJE WHERE ID_VIAJE = p_id_viaje;
    RETURN v_fecha;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20090, 'Error al obtener la fecha del viaje: ' || SQLERRM);
END;
/

-- Esta parte del código se encarga de verificar que un bus este asignado a un viaje.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_BUS_ASIGNADO (
    p_id_viaje   IN NUMBER,
    p_patente_bus IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_CONDUCE
     WHERE ID_VIAJE = p_id_viaje
       AND PATENTE_BUS = p_patente_bus;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de obtener la capacidad declarada de un bus.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_CAPACIDAD_BUS (
    p_patente_bus IN VARCHAR2
) RETURN NUMBER IS
    v_capacidad NUMBER;
BEGIN
    SELECT CAPACIDAD INTO v_capacidad FROM LHAOMRJZ_BUS WHERE PATENTE_BUS = p_patente_bus;
    RETURN v_capacidad;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20091, 'Error al obtener la capacidad del bus: ' || SQLERRM);
END;
/

-- Esta parte del código se encarga de contar los boletos ocupados de un bus en un viaje.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_CONTAR_BOLETOS_OCUPADOS (
    p_id_viaje    IN NUMBER,
    p_patente_bus IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_BOLETO
     WHERE ID_VIAJE = p_id_viaje
       AND PATENTE_BUS = p_patente_bus
       AND ESTADO IN ('EMITIDO', 'USADO');
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar si un asiento ya esta vendido en un viaje.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_ASIENTO_OCUPADO (
    p_id_viaje       IN NUMBER,
    p_patente_bus    IN VARCHAR2,
    p_numero_asiento IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_BOLETO
     WHERE ID_VIAJE = p_id_viaje
       AND PATENTE_BUS = p_patente_bus
       AND NUMERO_ASIENTO = p_numero_asiento
       AND ESTADO IN ('EMITIDO', 'USADO');
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de obtener el nombre de un terminal.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_NOMBRE_TERMINAL (
    p_id_terminal IN NUMBER
) RETURN VARCHAR2 IS
    v_nombre VARCHAR2(80);
BEGIN
    SELECT NOMBRE INTO v_nombre FROM LHAOMRJZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal;
    RETURN v_nombre;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20092, 'Error al obtener el nombre del terminal: ' || SQLERRM);
END;
/

-- Esta parte del código se encarga de obtener el estado actual de un boleto.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_ESTADO_BOLETO (
    p_id_boleto IN NUMBER
) RETURN VARCHAR2 IS
    v_estado VARCHAR2(10);
BEGIN
    SELECT ESTADO INTO v_estado FROM LHAOMRJZ_BOLETO WHERE ID_BOLETO = p_id_boleto;
    RETURN v_estado;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20093, 'Error al obtener el estado del boleto: ' || SQLERRM);
END;
/

-- Esta parte del código se encarga de contar la bajada registrada de un boleto.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_CONTAR_BAJADA (
    p_id_boleto IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LHAOMRJZ_PASAJE_BAJADA WHERE ID_BOLETO = p_id_boleto;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Esta parte del código se encarga de verificar que la bajada corresponda a una parada habilitada del viaje.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_BAJADA_PERMITIDA (
    p_id_boleto        IN NUMBER,
    p_id_terminal_bajada IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM LHAOMRJZ_BOLETO b
      INNER JOIN LHAOMRJZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
      INNER JOIN LHAOMRJZ_RUTA_PARADA rp ON rp.ID_RUTA = v.ID_RUTA
     WHERE b.ID_BOLETO = p_id_boleto
       AND rp.ID_TERMINAL = p_id_terminal_bajada
       AND rp.PERMITE_BAJADA = 'S'
       AND rp.ORDEN_PARADA > 1;
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

COMMIT;

-- Esta parte del código se encarga de obtener el identificador de region de una comuna del catalogo.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_ID_REGION_COMUNA (
    p_nombre_comuna IN VARCHAR2
) RETURN NUMBER IS
    v_id_region NUMBER;
BEGIN
    SELECT r.ID_REGION
      INTO v_id_region
      FROM LHAOMRJZ_VW_COMUNAS_CHILE_ALL c
      JOIN LHAOMRJZ_REGION r ON UPPER(r.NOMBRE_REGION) = UPPER(c.NOMBRE_REGION)
     WHERE UPPER(c.NOMBRE_COMUNA) = UPPER(p_nombre_comuna);
    RETURN v_id_region;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20022, 'La comuna seleccionada no existe en el catalogo de Chile o su region no esta cargada.');
END;
/

-- Esta parte del código se encarga de obtener el valor calculado de un boleto.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_VALOR_BOLETO (
    p_id_boleto IN NUMBER
) RETURN NUMBER IS
    v_valor NUMBER;
BEGIN
    SELECT VALOR_BOLETO
      INTO v_valor
      FROM LHAOMRJZ_BOLETO
     WHERE ID_BOLETO = p_id_boleto;
    RETURN v_valor;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/
