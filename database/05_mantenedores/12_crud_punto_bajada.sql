-- REQUERIMIENTO 4.1 - CRUD PUNTOS HABILITADOS
-- Requiere 01_estructura_41.sql y LEHZ_RUTA_PARADA del CRUD 11.
-- I = habilitar; D = deshabilitar. No se necesita U: se deshabilita y habilita otro.
CREATE OR REPLACE PROCEDURE LEHZ_CRUD_PUNTO_BAJADA (
    P_OPERACION IN VARCHAR2,
    P_ID_RUTA IN NUMBER,
    P_ID_TERMINAL IN NUMBER
)
IS
    V_EXISTE NUMBER;
    V_ORIGEN NUMBER;
    V_DESTINO NUMBER;
BEGIN
    SELECT ID_TERMINAL_ORIGEN, ID_TERMINAL_DESTINO
      INTO V_ORIGEN, V_DESTINO
      FROM LEHZ_RUTA WHERE ID_RUTA = P_ID_RUTA FOR UPDATE;

    IF UPPER(TRIM(P_OPERACION)) = 'I' THEN
        IF P_ID_TERMINAL IS NULL OR P_ID_TERMINAL = V_ORIGEN THEN
            RAISE_APPLICATION_ERROR(-20101, 'No se permite bajar en el origen');
        END IF;
        SELECT COUNT(*) INTO V_EXISTE FROM LEHZ_RUTA_PARADA
         WHERE ID_RUTA = P_ID_RUTA AND ID_TERMINAL = P_ID_TERMINAL;
        IF V_EXISTE = 0 AND (V_DESTINO IS NULL OR P_ID_TERMINAL <> V_DESTINO) THEN
            RAISE_APPLICATION_ERROR(-20102, 'El terminal no es parada ni destino de la ruta');
        END IF;
        INSERT INTO LEHZ_PUNTO_BAJADA(ID_PUNTO_BAJADA, ID_RUTA, ID_TERMINAL)
        VALUES (LEHZ_SEQ_PUNTO_BAJADA.NEXTVAL, P_ID_RUTA, P_ID_TERMINAL);
    ELSIF UPPER(TRIM(P_OPERACION)) = 'D' THEN
        DELETE FROM LEHZ_PUNTO_BAJADA
         WHERE ID_RUTA = P_ID_RUTA AND ID_TERMINAL = P_ID_TERMINAL;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20103, 'Punto de bajada no encontrado');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20104, 'Operacion invalida (I/D)');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20105, 'Ruta no encontrada');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20106, 'Punto ya habilitado para esta ruta');
END;
/

-- Habilitar automaticamente todas las paradas y el destino de cada ruta
-- (solo rutas que tengan origen y destino definidos).
-- Este bloque puede repetirse sin duplicar registros.
BEGIN
    FOR R IN (SELECT ID_RUTA, ID_TERMINAL_DESTINO FROM LEHZ_RUTA
              WHERE ID_TERMINAL_ORIGEN IS NOT NULL AND ID_TERMINAL_DESTINO IS NOT NULL)
    LOOP
        FOR P IN (SELECT ID_TERMINAL FROM LEHZ_RUTA_PARADA WHERE ID_RUTA = R.ID_RUTA
                  UNION SELECT R.ID_TERMINAL_DESTINO FROM DUAL)
        LOOP
            MERGE INTO LEHZ_PUNTO_BAJADA X
            USING (SELECT R.ID_RUTA ID_RUTA, P.ID_TERMINAL ID_TERMINAL FROM DUAL) S
               ON (X.ID_RUTA = S.ID_RUTA AND X.ID_TERMINAL = S.ID_TERMINAL)
            WHEN NOT MATCHED THEN
                INSERT (ID_PUNTO_BAJADA, ID_RUTA, ID_TERMINAL)
                VALUES (LEHZ_SEQ_PUNTO_BAJADA.NEXTVAL, S.ID_RUTA, S.ID_TERMINAL);
        END LOOP;
    END LOOP;
END;
/

-- Nota: si se agregan o cambian paradas posteriormente, actualizar los puntos
-- habilitados. No eliminar paradas ya referenciadas por boletos sin revisar.
