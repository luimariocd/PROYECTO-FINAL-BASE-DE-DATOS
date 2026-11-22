-- REQUERIMIENTO 4.1 - ASOCIAR RUTA AL PROGRAMAR VIAJE
-- Para crear rutas nuevas con paradas se usa primero el CRUD 11:
--   LEHZ_CRUD_RUTA('I', NULL, origen, destino, horario, distancia, horas, minutos)
-- y luego LEHZ_CRUD_RUTA_PARADA('I', NULL, id_ruta, terminal, orden).
-- Esta operacion asocia la ruta ya construida a un viaje nuevo.
-- Requiere LEHZ_SEQ_VIAJE existente (verificar nombre en 02_create_sequences.sql).
CREATE OR REPLACE PROCEDURE LEHZ_GES_PROGRAMAR_VIAJE_41 (
    P_FECHA_VIAJE IN DATE,
    P_ID_HORARIO IN NUMBER,
    P_ID_RUTA IN NUMBER,
    P_ID_VIAJE_OUT OUT NUMBER
)
IS
    V_EXISTE NUMBER;
BEGIN
    SELECT COUNT(*) INTO V_EXISTE FROM LEHZ_RUTA
     WHERE ID_RUTA = P_ID_RUTA
       AND ID_TERMINAL_ORIGEN IS NOT NULL
       AND ID_TERMINAL_DESTINO IS NOT NULL
       AND ID_TERMINAL_ORIGEN <> ID_TERMINAL_DESTINO;
    IF V_EXISTE = 0 THEN
        RAISE_APPLICATION_ERROR(-20121, 'Ruta incompleta o inexistente');
    END IF;
    SELECT COUNT(*) INTO V_EXISTE FROM LEHZ_HORARIO
     WHERE ID_HORARIO = P_ID_HORARIO;
    IF V_EXISTE = 0 THEN
        RAISE_APPLICATION_ERROR(-20122, 'Horario inexistente');
    END IF;
    P_ID_VIAJE_OUT := LEHZ_SEQ_VIAJE.NEXTVAL;
    INSERT INTO LEHZ_VIAJE(ID_VIAJE, FECHA_VIAJE, ID_HORARIO, ID_RUTA)
    VALUES(P_ID_VIAJE_OUT, P_FECHA_VIAJE, P_ID_HORARIO, P_ID_RUTA);
END;
/
-- Sin COMMIT: programar ruta, paradas, puntos y viaje en una sola transaccion.
