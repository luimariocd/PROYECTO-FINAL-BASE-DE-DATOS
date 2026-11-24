ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- ============================================================================
-- GESTOR 06: VISTAS FORMATEADAS, TARIFAS Y BAJADAS INDEPENDIENTES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Itinerario detallado: una fila por parada de cada ruta. Si la ruta aun no
-- tiene paradas registradas, muestra al menos origen y destino.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_ITINERARIO AS
SELECT r.ID_RUTA,
       r.NOMBRE_RUTA,
       rp.ORDEN_PARADA,
       rp.ID_TERMINAL,
       t.NOMBRE AS TERMINAL,
       c.NOMBRE_COMUNA,
       rp.MINUTOS_DESDE_ORIG,
       rp.PERMITE_BAJADA
  FROM LEHZ_RUTA r
  INNER JOIN LEHZ_RUTA_PARADA rp ON rp.ID_RUTA = r.ID_RUTA
  INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = rp.ID_TERMINAL
  INNER JOIN LEHZ_COMUNA c ON c.ID_COMUNA = t.ID_COMUNA
UNION ALL
SELECT r.ID_RUTA,
       r.NOMBRE_RUTA,
       1 AS ORDEN_PARADA,
       r.ID_TERMINAL_ORIGEN AS ID_TERMINAL,
       o.NOMBRE AS TERMINAL,
       co.NOMBRE_COMUNA,
       0 AS MINUTOS_DESDE_ORIG,
       'N' AS PERMITE_BAJADA
  FROM LEHZ_RUTA r
  INNER JOIN LEHZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
  INNER JOIN LEHZ_COMUNA co ON co.ID_COMUNA = o.ID_COMUNA
 WHERE NOT EXISTS (SELECT 1 FROM LEHZ_RUTA_PARADA rp WHERE rp.ID_RUTA = r.ID_RUTA)
UNION ALL
SELECT r.ID_RUTA,
       r.NOMBRE_RUTA,
       2 AS ORDEN_PARADA,
       r.ID_TERMINAL_DESTINO AS ID_TERMINAL,
       d.NOMBRE AS TERMINAL,
       cd.NOMBRE_COMUNA,
       NVL(r.HORAS_ESTIMADAS, 0) * 60 + NVL(r.MINUTOS_ESTIMADOS, 0) AS MINUTOS_DESDE_ORIG,
       'S' AS PERMITE_BAJADA
  FROM LEHZ_RUTA r
  INNER JOIN LEHZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO
  INNER JOIN LEHZ_COMUNA cd ON cd.ID_COMUNA = d.ID_COMUNA
 WHERE NOT EXISTS (SELECT 1 FROM LEHZ_RUTA_PARADA rp WHERE rp.ID_RUTA = r.ID_RUTA);

-- ----------------------------------------------------------------------------
-- Rutas con recorrido completo, origen, destino y conteo de terminales.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_RUTAS_DETALLE AS
SELECT r.ID_RUTA,
       r.NOMBRE_RUTA,
       r.DISTANCIA,
       r.HORAS_ESTIMADAS,
       r.MINUTOS_ESTIMADOS,
       o.NOMBRE AS TERMINAL_ORIGEN,
       co.NOMBRE_COMUNA AS COMUNA_ORIGEN,
       d.NOMBRE AS TERMINAL_DESTINO,
       cd.NOMBRE_COMUNA AS COMUNA_DESTINO,
       (SELECT COUNT(*) FROM LEHZ_RUTA_PARADA rp WHERE rp.ID_RUTA = r.ID_RUTA) AS TOTAL_PARADAS,
       (SELECT COUNT(DISTINCT t.ID_TERMINAL)
          FROM LEHZ_RUTA_PARADA rp
          INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = rp.ID_TERMINAL
         WHERE rp.ID_RUTA = r.ID_RUTA) AS TOTAL_TERMINALES,
       (SELECT LISTAGG(i.TERMINAL, ' -> ') WITHIN GROUP (ORDER BY i.ORDEN_PARADA)
          FROM LEHZ_VW_ITINERARIO i
         WHERE i.ID_RUTA = r.ID_RUTA) AS RECORRIDO
  FROM LEHZ_RUTA r
  INNER JOIN LEHZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
  INNER JOIN LEHZ_COMUNA co ON co.ID_COMUNA = o.ID_COMUNA
  INNER JOIN LEHZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO
  INNER JOIN LEHZ_COMUNA cd ON cd.ID_COMUNA = d.ID_COMUNA;

-- ----------------------------------------------------------------------------
-- Horarios limpios para selectores y reportes.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_HORARIOS AS
SELECT ID_HORARIO,
       HORARIO,
       TO_CHAR(HORA_SALIDA, 'YYYY-MM-DD HH24:MI') AS HORA_SALIDA,
       TO_CHAR(HORA_LLEGADA, 'YYYY-MM-DD HH24:MI') AS HORA_LLEGADA,
       TO_CHAR(HORA_SALIDA, 'HH24:MI') || ' - ' || TO_CHAR(HORA_LLEGADA, 'HH24:MI') AS RANGO,
       CASE
           WHEN TO_NUMBER(TO_CHAR(HORA_SALIDA, 'HH24')) < 12 THEN 'MANANA'
           WHEN TO_NUMBER(TO_CHAR(HORA_SALIDA, 'HH24')) < 19 THEN 'TARDE'
           ELSE 'NOCHE'
       END AS JORNADA
  FROM LEHZ_HORARIO;

-- ----------------------------------------------------------------------------
-- Viajes con sus buses y conductores asignados (una fila por viaje/bus).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_VIAJE_BUSES AS
SELECT v.ID_VIAJE,
       v.FECHA_VIAJE,
       TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE_TEXTO,
       r.ID_RUTA,
       r.NOMBRE_RUTA,
       h.ID_HORARIO,
       TO_CHAR(h.HORA_SALIDA, 'HH24:MI') AS HORA_SALIDA,
       TO_CHAR(h.HORA_LLEGADA, 'HH24:MI') AS HORA_LLEGADA,
       c.PATENTE_BUS,
       b.MARCA,
       b.MODELO,
       b.CAPACIDAD,
       b.TIPO_SERVICIO,
       b.TARIFA_BASE,
       LISTAGG(co.NOMBRE_CONDUCTOR || ' ' || co.APELLIDO1_CONDUCTOR, ', ')
           WITHIN GROUP (ORDER BY co.APELLIDO1_CONDUCTOR, co.NOMBRE_CONDUCTOR) AS CONDUCTORES
  FROM LEHZ_VIAJE v
  INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
  INNER JOIN LEHZ_HORARIO h ON h.ID_HORARIO = v.ID_HORARIO
  INNER JOIN LEHZ_CONDUCE c ON c.ID_VIAJE = v.ID_VIAJE
  INNER JOIN LEHZ_BUS b ON b.PATENTE_BUS = c.PATENTE_BUS
  INNER JOIN LEHZ_CONDUCTOR co ON co.RUT_CONDUCTOR = c.RUT_CONDUCTOR
 GROUP BY v.ID_VIAJE, v.FECHA_VIAJE, r.ID_RUTA, r.NOMBRE_RUTA,
          h.ID_HORARIO, h.HORA_SALIDA, h.HORA_LLEGADA,
          c.PATENTE_BUS, b.MARCA, b.MODELO, b.CAPACIDAD,
          b.TIPO_SERVICIO, b.TARIFA_BASE;

-- ----------------------------------------------------------------------------
-- Viajes con datos consolidados para paneles y selectores.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_VIAJES_DETALLE AS
SELECT v.ID_VIAJE,
       v.FECHA_VIAJE,
       TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE_TEXTO,
       h.ID_HORARIO,
       TO_CHAR(h.HORA_SALIDA, 'HH24:MI') AS HORA_SALIDA,
       TO_CHAR(h.HORA_LLEGADA, 'HH24:MI') AS HORA_LLEGADA,
       r.ID_RUTA,
       r.NOMBRE_RUTA,
       o.NOMBRE AS TERMINAL_ORIGEN,
       d.NOMBRE AS TERMINAL_DESTINO,
       r.DISTANCIA,
       (SELECT LISTAGG(c.PATENTE_BUS, ', ') WITHIN GROUP (ORDER BY c.PATENTE_BUS)
          FROM (SELECT DISTINCT c2.PATENTE_BUS
                  FROM LEHZ_CONDUCE c2
                 WHERE c2.ID_VIAJE = v.ID_VIAJE) c) AS BUSES,
       (SELECT NVL(SUM(b.CAPACIDAD), 0)
          FROM (SELECT DISTINCT c3.PATENTE_BUS
                  FROM LEHZ_CONDUCE c3
                 WHERE c3.ID_VIAJE = v.ID_VIAJE) x
          INNER JOIN LEHZ_BUS b ON b.PATENTE_BUS = x.PATENTE_BUS) AS CAPACIDAD_TOTAL,
       (SELECT COUNT(*)
          FROM LEHZ_BOLETO b
         WHERE b.ID_VIAJE = v.ID_VIAJE
           AND b.ESTADO IN ('EMITIDO', 'USADO')) AS BOLETOS_ACTIVOS
  FROM LEHZ_VIAJE v
  INNER JOIN LEHZ_HORARIO h ON h.ID_HORARIO = v.ID_HORARIO
  INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
  INNER JOIN LEHZ_TERMINAL o ON o.ID_TERMINAL = r.ID_TERMINAL_ORIGEN
  INNER JOIN LEHZ_TERMINAL d ON d.ID_TERMINAL = r.ID_TERMINAL_DESTINO;

-- ----------------------------------------------------------------------------
-- Asientos disponibles por viaje y bus.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_ASIENTOS_DISPONIBLES AS
SELECT v.ID_VIAJE,
       c.PATENTE_BUS,
       a.NUMERO_ASIENTO,
       a.PISO,
       a.UBICACION,
       CASE
           WHEN EXISTS (
               SELECT 1
                 FROM LEHZ_BOLETO b
                WHERE b.ID_VIAJE = v.ID_VIAJE
                  AND b.PATENTE_BUS = c.PATENTE_BUS
                  AND b.NUMERO_ASIENTO = a.NUMERO_ASIENTO
                  AND b.ESTADO IN ('EMITIDO', 'USADO')
           ) THEN 'OCUPADO'
           ELSE 'DISPONIBLE'
       END AS ESTADO_ASIENTO
  FROM LEHZ_VIAJE v
  INNER JOIN (SELECT DISTINCT ID_VIAJE, PATENTE_BUS FROM LEHZ_CONDUCE) c
          ON c.ID_VIAJE = v.ID_VIAJE
  INNER JOIN LEHZ_ASIENTO a ON a.PATENTE_BUS = c.PATENTE_BUS;

-- ----------------------------------------------------------------------------
-- Paradas habilitadas para bajada por viaje/bus, con tarifa calculada.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_PARADAS_BAJADA AS
SELECT v.ID_VIAJE,
       v.FECHA_VIAJE,
       r.ID_RUTA,
       r.NOMBRE_RUTA,
       c.PATENTE_BUS,
       rp.ID_TERMINAL,
       t.NOMBRE AS TERMINAL,
       co.NOMBRE_COMUNA,
       rp.ORDEN_PARADA,
       rp.MINUTOS_DESDE_ORIG,
       LEHZ_FN_CALCULAR_TARIFA_BUS(v.ID_VIAJE, c.PATENTE_BUS, rp.ID_TERMINAL) AS TARIFA
  FROM LEHZ_VIAJE v
  INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
  INNER JOIN LEHZ_CONDUCE c ON c.ID_VIAJE = v.ID_VIAJE
  INNER JOIN LEHZ_RUTA_PARADA rp ON rp.ID_RUTA = r.ID_RUTA
  INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = rp.ID_TERMINAL
  INNER JOIN LEHZ_COMUNA co ON co.ID_COMUNA = t.ID_COMUNA
 WHERE rp.PERMITE_BAJADA = 'S'
   AND rp.ORDEN_PARADA > 1;

-- ----------------------------------------------------------------------------
-- Boletos formateados para consulta y reportes.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_BOLETOS AS
SELECT b.ID_BOLETO,
       TO_CHAR(b.FECHA_EMISION_BOLETO, 'DD/MM/YYYY') AS FECHA_EMISION,
       b.VALOR_BOLETO,
       b.ESTADO,
       b.RUT_PASAJERO,
       p.NOMBRE_PASAJERO || ' ' || p.APELLIDO1_PASAJERO AS PASAJERO,
       b.ID_VIAJE,
       TO_CHAR(v.FECHA_VIAJE, 'DD/MM/YYYY') AS FECHA_VIAJE,
       r.NOMBRE_RUTA,
       b.PATENTE_BUS,
       b.NUMERO_ASIENTO,
       pg.METODO_PAGO,
       tb.NOMBRE AS TERMINAL_BAJADA,
       b.FECHA_ANULACION,
       b.MOTIVO_ANULACION
  FROM LEHZ_BOLETO b
  INNER JOIN LEHZ_PASAJERO p ON p.RUT_PASAJERO = b.RUT_PASAJERO
  INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
  INNER JOIN LEHZ_RUTA r ON r.ID_RUTA = v.ID_RUTA
  LEFT JOIN LEHZ_PAGO pg ON pg.ID_BOLETO = b.ID_BOLETO
  LEFT JOIN LEHZ_PASAJE_BAJADA pb ON pb.ID_BOLETO = b.ID_BOLETO
  LEFT JOIN LEHZ_TERMINAL tb ON tb.ID_TERMINAL = pb.ID_TERMINAL_BAJADA;

-- ----------------------------------------------------------------------------
-- Resumen general para el panel principal.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_RESUMEN AS
SELECT (SELECT COUNT(*) FROM LEHZ_EMPRESA) AS TOTAL_EMPRESAS,
       (SELECT COUNT(*) FROM LEHZ_BUS) AS TOTAL_BUSES,
       (SELECT COUNT(*) FROM LEHZ_VIAJE) AS TOTAL_VIAJES,
       (SELECT COUNT(*) FROM LEHZ_PASAJERO) AS TOTAL_PASAJEROS,
       (SELECT COUNT(*) FROM LEHZ_BOLETO WHERE ESTADO = 'EMITIDO') AS BOLETOS_EMITIDOS,
       (SELECT COUNT(*) FROM LEHZ_BOLETO WHERE ESTADO = 'ANULADO') AS BOLETOS_ANULADOS,
       (SELECT NVL(SUM(p.MONTO_PAGO), 0)
          FROM LEHZ_PAGO p
          INNER JOIN LEHZ_BOLETO b ON b.ID_BOLETO = p.ID_BOLETO
         WHERE b.ESTADO <> 'ANULADO') AS RECAUDACION_ACTIVA
  FROM DUAL;

-- ----------------------------------------------------------------------------
-- Dominios cerrados del modelo. PHP consume estas listas desde Oracle en lugar
-- de mantener arreglos o valores quemados en el codigo de presentacion.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW LEHZ_VW_DOMINIOS AS
SELECT 'TIPO_SERVICIO' AS DOMINIO, 'NORMAL' AS VALOR, 'Normal' AS ETIQUETA FROM DUAL
UNION ALL SELECT 'TIPO_SERVICIO', 'SALON CAMA', 'Salon cama' FROM DUAL
UNION ALL SELECT 'TIPO_SERVICIO', 'CAMA', 'Cama' FROM DUAL
UNION ALL SELECT 'METODO_PAGO', 'EFECTIVO', 'Efectivo' FROM DUAL
UNION ALL SELECT 'METODO_PAGO', 'TARJETA', 'Tarjeta' FROM DUAL
UNION ALL SELECT 'METODO_PAGO', 'TRANSFERENCIA', 'Transferencia' FROM DUAL
UNION ALL SELECT 'PERMITE_BAJADA', 'S', 'Si' FROM DUAL
UNION ALL SELECT 'PERMITE_BAJADA', 'N', 'No' FROM DUAL
UNION ALL SELECT 'TIPO_LICENCIA', 'A1', 'A1' FROM DUAL
UNION ALL SELECT 'TIPO_LICENCIA', 'A2', 'A2' FROM DUAL
UNION ALL SELECT 'TIPO_LICENCIA', 'A3', 'A3' FROM DUAL
UNION ALL SELECT 'ESTADO_USUARIO', 'ACTIVO', 'Activo' FROM DUAL
UNION ALL SELECT 'ESTADO_USUARIO', 'INACTIVO', 'Inactivo' FROM DUAL
UNION ALL SELECT 'UBICACION_ASIENTO', 'VENTANA', 'Ventana' FROM DUAL
UNION ALL SELECT 'UBICACION_ASIENTO', 'PASILLO', 'Pasillo' FROM DUAL
UNION ALL SELECT 'CANTIDAD_PISOS', '1', '1 piso' FROM DUAL
UNION ALL SELECT 'CANTIDAD_PISOS', '2', '2 pisos' FROM DUAL;

-- ----------------------------------------------------------------------------
-- Registro o cambio de la bajada independiente de un boleto existente.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_REGISTRAR_BAJADA(
    p_id_boleto          IN NUMBER,
    p_id_terminal_bajada IN NUMBER,
    p_observacion        IN VARCHAR2 DEFAULT NULL
) IS
    v_count  NUMBER := 0;
    v_estado VARCHAR2(10);
    v_nombre VARCHAR2(80);
BEGIN
    LOCK TABLE LEHZ_PASAJE_BAJADA IN EXCLUSIVE MODE;

    IF p_id_boleto IS NULL OR p_id_boleto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20150, 'Debe indicar un boleto valido.');
    END IF;
    IF p_id_terminal_bajada IS NULL OR p_id_terminal_bajada <= 0 THEN
        RAISE_APPLICATION_ERROR(-20150, 'Debe seleccionar una parada de bajada valida.');
    END IF;

    SELECT ESTADO INTO v_estado FROM LEHZ_BOLETO WHERE ID_BOLETO = p_id_boleto;
    IF v_estado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20150, 'No se puede registrar una bajada para un boleto anulado.');
    END IF;

    SELECT NOMBRE INTO v_nombre FROM LEHZ_TERMINAL WHERE ID_TERMINAL = p_id_terminal_bajada;

    SELECT COUNT(*)
      INTO v_count
      FROM LEHZ_BOLETO b
      INNER JOIN LEHZ_VIAJE v ON v.ID_VIAJE = b.ID_VIAJE
      INNER JOIN LEHZ_RUTA_PARADA rp ON rp.ID_RUTA = v.ID_RUTA
     WHERE b.ID_BOLETO = p_id_boleto
       AND rp.ID_TERMINAL = p_id_terminal_bajada
       AND rp.PERMITE_BAJADA = 'S'
       AND rp.ORDEN_PARADA > 1;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20150, 'La parada seleccionada no pertenece al recorrido del boleto o no permite bajada.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM LEHZ_PASAJE_BAJADA WHERE ID_BOLETO = p_id_boleto;

    IF v_count = 0 THEN
        INSERT INTO LEHZ_PASAJE_BAJADA (
            ID_BAJADA, ID_BOLETO, ID_TERMINAL_BAJADA, OBSERVACION, FECHA_REGISTRO
        ) VALUES (
            LEHZ_SEQ_PASAJE_BAJADA.NEXTVAL, p_id_boleto, p_id_terminal_bajada,
            NVL(LEHZ_FN_NORMALIZAR_TEXTO(p_observacion), 'Bajada en ' || v_nombre), SYSDATE
        );
    ELSE
        UPDATE LEHZ_PASAJE_BAJADA
           SET ID_TERMINAL_BAJADA = p_id_terminal_bajada,
               OBSERVACION = NVL(LEHZ_FN_NORMALIZAR_TEXTO(p_observacion), 'Bajada en ' || v_nombre)
         WHERE ID_BOLETO = p_id_boleto;
    END IF;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20150, 'El boleto o el terminal de bajada no existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LEHZ_PS_GES_REGISTRAR_BAJADA;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_GES_LISTAR_BAJADAS(
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT pb.ID_BAJADA, pb.ID_BOLETO, pb.ID_TERMINAL_BAJADA,
               t.NOMBRE AS TERMINAL, pb.OBSERVACION, pb.FECHA_REGISTRO
          FROM LEHZ_PASAJE_BAJADA pb
          INNER JOIN LEHZ_TERMINAL t ON t.ID_TERMINAL = pb.ID_TERMINAL_BAJADA
         ORDER BY pb.ID_BAJADA DESC;
END LEHZ_PS_GES_LISTAR_BAJADAS;
/
