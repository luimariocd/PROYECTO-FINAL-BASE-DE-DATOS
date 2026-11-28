ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

-- Esta parte del código se encarga de crear el mantenedor de paradas por ruta.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_IUD_RUTA_PARADA(
    p_opcion          IN VARCHAR2,
    p_id_ruta_parada  IN OUT NUMBER,
    p_id_ruta         IN NUMBER DEFAULT NULL,
    p_id_terminal     IN NUMBER DEFAULT NULL,
    p_orden           IN NUMBER DEFAULT NULL,
    p_minutos         IN NUMBER DEFAULT 0,
    p_permite_bajada  IN VARCHAR2 DEFAULT 'S'
) IS
    v_count NUMBER := 0;
    v_perm  CHAR(1);
BEGIN
    LOCK TABLE LHAOMRJZ_RUTA_PARADA IN ROW EXCLUSIVE MODE;
    v_perm := UPPER(TRIM(NVL(p_permite_bajada, 'S')));

    IF UPPER(TRIM(p_opcion)) IN ('I', 'U') THEN
        IF p_id_ruta IS NULL OR p_id_ruta <= 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Debe indicar la ruta.');
        END IF;
        IF p_id_terminal IS NULL OR p_id_terminal <= 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Debe indicar el terminal de la parada.');
        END IF;
        IF p_orden IS NULL OR p_orden <= 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'El orden de la parada debe ser mayor que cero.');
        END IF;
        IF p_minutos IS NULL OR p_minutos < 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Los minutos desde el origen deben ser mayores o iguales a cero.');
        END IF;
        IF v_perm NOT IN ('S', 'N') THEN
            RAISE_APPLICATION_ERROR(-20100, 'El indicador de bajada debe ser S o N.');
        END IF;

        v_count := LHAOMRJZ_FN_EXISTE_RUTA(p_id_ruta);
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'La ruta seleccionada no existe.');
        END IF;
        v_count := LHAOMRJZ_FN_EXISTE_TERMINAL(p_id_terminal);
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'El terminal seleccionado no existe.');
        END IF;

        v_count := LHAOMRJZ_FN_PARADA_ORDEN_EXISTE(p_id_ruta, p_orden, p_id_ruta_parada);        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Ya existe una parada con ese orden en la ruta.');
        END IF;

        v_count := LHAOMRJZ_FN_PARADA_TERMINAL_EXISTE(p_id_ruta, p_id_terminal, p_id_ruta_parada);        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Ese terminal ya esta registrado como parada de la ruta.');
        END IF;
    END IF;

    IF UPPER(TRIM(p_opcion)) = 'I' THEN
        p_id_ruta_parada := LHAOMRJZ_SEQ_RUTA_PARADA.NEXTVAL;
        INSERT INTO LHAOMRJZ_RUTA_PARADA (
            ID_RUTA_PARADA, ID_RUTA, ID_TERMINAL, ORDEN_PARADA,
            MINUTOS_DESDE_ORIG, PERMITE_BAJADA
        ) VALUES (
            p_id_ruta_parada, p_id_ruta, p_id_terminal, p_orden,
            p_minutos, v_perm
        );

    ELSIF UPPER(TRIM(p_opcion)) = 'U' THEN
        IF p_id_ruta_parada IS NULL OR p_id_ruta_parada <= 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Debe indicar la parada a actualizar.');
        END IF;
        UPDATE LHAOMRJZ_RUTA_PARADA
           SET ID_RUTA = p_id_ruta,
               ID_TERMINAL = p_id_terminal,
               ORDEN_PARADA = p_orden,
               MINUTOS_DESDE_ORIG = p_minutos,
               PERMITE_BAJADA = v_perm
         WHERE ID_RUTA_PARADA = p_id_ruta_parada;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20101, 'No se encontro la parada a actualizar.');
        END IF;

    ELSIF UPPER(TRIM(p_opcion)) = 'D' THEN
        IF p_id_ruta_parada IS NULL OR p_id_ruta_parada <= 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'Debe indicar la parada a eliminar.');
        END IF;
        DELETE FROM LHAOMRJZ_RUTA_PARADA WHERE ID_RUTA_PARADA = p_id_ruta_parada;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'No se encontro la parada a eliminar.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20100, 'Operacion invalida. Use I, U o D.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20100, 'Ya existe una parada con ese orden o terminal en la ruta.');
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20102, 'No se puede eliminar la parada: tiene bajadas de pasajeros asociadas.');
        END IF;
        RAISE;
END LHAOMRJZ_PS_IUD_RUTA_PARADA;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_RUTA_PARADAS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT rp.ID_RUTA_PARADA, rp.ID_RUTA, r.NOMBRE_RUTA,
        rp.ID_TERMINAL, t.NOMBRE AS TERMINAL,
        c.NOMBRE_COMUNA, rp.ORDEN_PARADA,
        rp.MINUTOS_DESDE_ORIG, rp.PERMITE_BAJADA
        FROM LHAOMRJZ_RUTA_PARADA rp
        INNER JOIN LHAOMRJZ_RUTA r ON rp.ID_RUTA = r.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL t ON rp.ID_TERMINAL = t.ID_TERMINAL
        INNER JOIN LHAOMRJZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        ORDER BY r.NOMBRE_RUTA ASC, rp.ORDEN_PARADA ASC;
    v_registro_cursor cur_local%ROWTYPE;
BEGIN
    -- Esta parte del código se encarga de abrir, leer y cerrar el cursor local sin consumir el SYS_REFCURSOR de salida.
    OPEN cur_local;
    FETCH cur_local INTO v_registro_cursor;
    IF cur_local%NOTFOUND THEN
        NULL;
    END IF;
    CLOSE cur_local;
    OPEN p_cursor FOR
        SELECT rp.ID_RUTA_PARADA, rp.ID_RUTA, r.NOMBRE_RUTA,
               rp.ID_TERMINAL, t.NOMBRE AS TERMINAL,
               c.NOMBRE_COMUNA, rp.ORDEN_PARADA,
               rp.MINUTOS_DESDE_ORIG, rp.PERMITE_BAJADA
        FROM LHAOMRJZ_RUTA_PARADA rp
        INNER JOIN LHAOMRJZ_RUTA r ON rp.ID_RUTA = r.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL t ON rp.ID_TERMINAL = t.ID_TERMINAL
        INNER JOIN LHAOMRJZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        ORDER BY r.NOMBRE_RUTA ASC, rp.ORDEN_PARADA ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_RUTA_PARADAS: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_RUTA_PARADAS;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_PARADAS_DE_RUTA(
    p_id_ruta IN NUMBER,
    p_cursor  OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT rp.ID_RUTA_PARADA, rp.ID_RUTA, r.NOMBRE_RUTA,
        rp.ID_TERMINAL, t.NOMBRE AS TERMINAL,
        c.NOMBRE_COMUNA, rp.ORDEN_PARADA,
        rp.MINUTOS_DESDE_ORIG, rp.PERMITE_BAJADA
        FROM LHAOMRJZ_RUTA_PARADA rp
        INNER JOIN LHAOMRJZ_RUTA r ON rp.ID_RUTA = r.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL t ON rp.ID_TERMINAL = t.ID_TERMINAL
        INNER JOIN LHAOMRJZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        WHERE rp.ID_RUTA = p_id_ruta
        ORDER BY rp.ORDEN_PARADA ASC;
    v_registro_cursor cur_local%ROWTYPE;
BEGIN
    -- Esta parte del código se encarga de abrir, leer y cerrar el cursor local sin consumir el SYS_REFCURSOR de salida.
    OPEN cur_local;
    FETCH cur_local INTO v_registro_cursor;
    IF cur_local%NOTFOUND THEN
        NULL;
    END IF;
    CLOSE cur_local;
    OPEN p_cursor FOR
        SELECT rp.ID_RUTA_PARADA, rp.ID_RUTA, r.NOMBRE_RUTA,
               rp.ID_TERMINAL, t.NOMBRE AS TERMINAL,
               c.NOMBRE_COMUNA, rp.ORDEN_PARADA,
               rp.MINUTOS_DESDE_ORIG, rp.PERMITE_BAJADA
        FROM LHAOMRJZ_RUTA_PARADA rp
        INNER JOIN LHAOMRJZ_RUTA r ON rp.ID_RUTA = r.ID_RUTA
        INNER JOIN LHAOMRJZ_TERMINAL t ON rp.ID_TERMINAL = t.ID_TERMINAL
        INNER JOIN LHAOMRJZ_COMUNA c ON t.ID_COMUNA = c.ID_COMUNA
        WHERE rp.ID_RUTA = p_id_ruta
        ORDER BY rp.ORDEN_PARADA ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_PARADAS_DE_RUTA: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_PARADAS_DE_RUTA;
/
