ALTER SESSION SET CURRENT_SCHEMA = LHAOMRJZ;

CREATE TABLE LHAOMRJZ_ROL (
    ID_ROL NUMBER NOT NULL,
    NOMBRE_ROL VARCHAR2(30) NOT NULL,
    DESCRIPCION_ROL VARCHAR2(150),
    CONSTRAINT PK_LHAOMRJZ_ROL PRIMARY KEY (ID_ROL),
    CONSTRAINT UQ_LHAOMRJZ_NOMBRE_ROL UNIQUE (NOMBRE_ROL)
);

CREATE TABLE LHAOMRJZ_USUARIO (
    ID_USUARIO NUMBER NOT NULL,
    USERNAME VARCHAR2(40) NOT NULL,
    PASSWORD_HASH VARCHAR2(128) NOT NULL,
    NOMBRE_COMPLETO VARCHAR2(120) NOT NULL,
    EMAIL VARCHAR2(80),
    ESTADO VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL,
    ID_ROL NUMBER NOT NULL,
    FECHA_CREACION DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_LHAOMRJZ_USUARIO PRIMARY KEY (ID_USUARIO),
    CONSTRAINT UQ_LHAOMRJZ_USERNAME UNIQUE (USERNAME),
    CONSTRAINT FK_USUARIO_ROL FOREIGN KEY (ID_ROL) REFERENCES LHAOMRJZ_ROL (ID_ROL)
);

CREATE TABLE LHAOMRJZ_AUDITORIA (
    ID_AUDITORIA NUMBER NOT NULL,
    TABLA_AFECTADA VARCHAR2(40) NOT NULL,
    OPERACION VARCHAR2(15) NOT NULL,
    ID_REGISTRO VARCHAR2(60),
    DETALLE VARCHAR2(500),
    USUARIO_BD VARCHAR2(40) DEFAULT USER NOT NULL,
    FECHA_EVENTO TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT PK_LHAOMRJZ_AUDITORIA PRIMARY KEY (ID_AUDITORIA)
);

-- Esta parte del código se encarga de calcular el hash SHA256 de una contrasena.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_HASH_PASSWORD (
    p_password IN VARCHAR2
) RETURN VARCHAR2 IS
    v_hash VARCHAR2(128);
BEGIN
    SELECT RAWTOHEX(STANDARD_HASH(p_password, 'SHA256'))
      INTO v_hash
      FROM DUAL;
    RETURN v_hash;
END;
/

-- Esta parte del código se encarga de contar los usuarios activos validos para el login.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_CONTAR_LOGIN (
    p_username IN VARCHAR2,
    p_hash     IN VARCHAR2
) RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM LHAOMRJZ_USUARIO u
     WHERE LOWER(u.USERNAME) = LOWER(TRIM(p_username))
       AND u.PASSWORD_HASH = p_hash
       AND u.ESTADO = 'ACTIVO';
    RETURN v_count;
END;
/

-- Esta parte del código se encarga de cargar los roles de prueba.

INSERT INTO LHAOMRJZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LHAOMRJZ_SEQ_ROL.NEXTVAL, 'ADMINISTRADOR', 'Acceso total a mantenedores, gestores, reportes y seguridad');

INSERT INTO LHAOMRJZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LHAOMRJZ_SEQ_ROL.NEXTVAL, 'VENDEDOR', 'Acceso a venta de boletos, pagos y consulta de viajes');

INSERT INTO LHAOMRJZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LHAOMRJZ_SEQ_ROL.NEXTVAL, 'OPERACIONES', 'Acceso a gestion de flota, viajes, conductores y mantenciones');

-- Esta parte del código se encarga de crear los usuarios iniciales con clave SHA256.
INSERT INTO LHAOMRJZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LHAOMRJZ_SEQ_USUARIO.NEXTVAL,
    'admin',
    RAWTOHEX(STANDARD_HASH('Admin1234', 'SHA256')),
    'Administrador General',
    'admin@transporteucm.cl',
    'ACTIVO',
    1
);

INSERT INTO LHAOMRJZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LHAOMRJZ_SEQ_USUARIO.NEXTVAL,
    'vendedor1',
    RAWTOHEX(STANDARD_HASH('Ventas1234', 'SHA256')),
    'Ejecutivo Boleteria Talca',
    'ventas@transporteucm.cl',
    'ACTIVO',
    2
);

INSERT INTO LHAOMRJZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LHAOMRJZ_SEQ_USUARIO.NEXTVAL,
    'operador1',
    RAWTOHEX(STANDARD_HASH('Flota1234', 'SHA256')),
    'Coordinador de Flota',
    'flota@transporteucm.cl',
    'ACTIVO',
    3
);

-- Esta parte del código se encarga de crear el usuario administrador del sistema.
INSERT INTO LHAOMRJZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LHAOMRJZ_SEQ_USUARIO.NEXTVAL,
    'denunce',
    RAWTOHEX(STANDARD_HASH('Mario1234', 'SHA256')),
    'Administrador Denunce',
    'denunce@transporteucm.cl',
    'ACTIVO',
    1
);

COMMIT;

-- Esta parte del código se encarga de crear el paquete de control de acceso.

CREATE OR REPLACE PACKAGE LHAOMRJZ_PKG_SEGURIDAD AS
    FUNCTION LHAOMRJZ_FN_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN SYS_REFCURSOR;

    -- Esta parte del código se encarga de conservar el alias compatible del login.
    FUNCTION FN_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN SYS_REFCURSOR;

    PROCEDURE SP_CREAR_USUARIO(
        p_username        IN VARCHAR2,
        p_password        IN VARCHAR2,
        p_nombre_completo IN VARCHAR2,
        p_email           IN VARCHAR2,
        p_id_rol          IN NUMBER,
        p_id_generado     OUT NUMBER
    );

    PROCEDURE SP_CAMBIAR_ESTADO_USUARIO(
        p_id_usuario IN NUMBER,
        p_estado     IN VARCHAR2
    );

    PROCEDURE SP_LISTAR_USUARIOS(
        p_cursor OUT SYS_REFCURSOR
    );
END LHAOMRJZ_PKG_SEGURIDAD;
/

CREATE OR REPLACE PACKAGE BODY LHAOMRJZ_PKG_SEGURIDAD AS

    FUNCTION LHAOMRJZ_FN_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
        v_hash   VARCHAR2(128);

        -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
        CURSOR cur_local IS
            SELECT u.ID_USUARIO,
            u.USERNAME,
            u.NOMBRE_COMPLETO,
            u.EMAIL,
            r.ID_ROL,
            r.NOMBRE_ROL
            FROM LHAOMRJZ_USUARIO u
            INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
            WHERE LOWER(u.USERNAME) = LOWER(TRIM(p_username))
            AND u.PASSWORD_HASH = v_hash
            AND u.ESTADO = 'ACTIVO';
        v_registro_cursor cur_local%ROWTYPE;
    BEGIN
        v_hash := LHAOMRJZ_FN_HASH_PASSWORD(p_password);

        -- Esta parte del código se encarga de abrir, leer y cerrar el cursor local sin consumir el SYS_REFCURSOR de salida.
        OPEN cur_local;
        FETCH cur_local INTO v_registro_cursor;
        IF cur_local%NOTFOUND THEN
            NULL;
        END IF;
        CLOSE cur_local;
        OPEN v_cursor FOR
            SELECT u.ID_USUARIO,
                   u.USERNAME,
                   u.NOMBRE_COMPLETO,
                   u.EMAIL,
                   r.ID_ROL,
                   r.NOMBRE_ROL
            FROM LHAOMRJZ_USUARIO u
            INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
            WHERE LOWER(u.USERNAME) = LOWER(TRIM(p_username))
              AND u.PASSWORD_HASH = v_hash
              AND u.ESTADO = 'ACTIVO';

        RETURN v_cursor;
    END LHAOMRJZ_FN_VALIDAR_LOGIN;

    -- Esta parte del código se encarga de delegar el alias compatible al nombre con prefijo LHAOMRJZ_FN_.
    FUNCTION FN_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN SYS_REFCURSOR IS
    BEGIN
        RETURN LHAOMRJZ_FN_VALIDAR_LOGIN(p_username, p_password);
    END FN_VALIDAR_LOGIN;

    PROCEDURE SP_CREAR_USUARIO(
        p_username        IN VARCHAR2,
        p_password        IN VARCHAR2,
        p_nombre_completo IN VARCHAR2,
        p_email           IN VARCHAR2,
        p_id_rol          IN NUMBER,
        p_id_generado     OUT NUMBER
    ) IS
        v_hash VARCHAR2(128);
    BEGIN
        v_hash := LHAOMRJZ_FN_HASH_PASSWORD(p_password);

        p_id_generado := LHAOMRJZ_SEQ_USUARIO.NEXTVAL;

        INSERT INTO LHAOMRJZ_USUARIO (
            ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL
        ) VALUES (
            p_id_generado, TRIM(p_username), v_hash, TRIM(p_nombre_completo), TRIM(p_email), 'ACTIVO', p_id_rol
        );

        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'El nombre de usuario ya existe en el sistema.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_CREAR_USUARIO;

    PROCEDURE SP_CAMBIAR_ESTADO_USUARIO(
        p_id_usuario IN NUMBER,
        p_estado     IN VARCHAR2
    ) IS
    BEGIN
        UPDATE LHAOMRJZ_USUARIO
        SET ESTADO = UPPER(TRIM(p_estado))
        WHERE ID_USUARIO = p_id_usuario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'No se encontro el usuario especificado.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_CAMBIAR_ESTADO_USUARIO;

    PROCEDURE SP_LISTAR_USUARIOS(
        p_cursor OUT SYS_REFCURSOR
    ) IS

        -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
        CURSOR cur_local IS
            SELECT u.ID_USUARIO,
            u.USERNAME,
            u.NOMBRE_COMPLETO,
            u.EMAIL,
            u.ESTADO,
            r.ID_ROL,
            r.NOMBRE_ROL,
            u.FECHA_CREACION
            FROM LHAOMRJZ_USUARIO u
            INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
            ORDER BY u.ID_USUARIO ASC;
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
            SELECT u.ID_USUARIO,
                   u.USERNAME,
                   u.NOMBRE_COMPLETO,
                   u.EMAIL,
                   u.ESTADO,
                   r.ID_ROL,
                   r.NOMBRE_ROL,
                   u.FECHA_CREACION
            FROM LHAOMRJZ_USUARIO u
            INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
            ORDER BY u.ID_USUARIO ASC;
        -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
        COMMIT;
    EXCEPTION
        -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999, 'Error en SP_LISTAR_USUARIOS: ' || SQLERRM);
    END SP_LISTAR_USUARIOS;

END LHAOMRJZ_PKG_SEGURIDAD;
/

-- Esta parte del código se encarga de exponer login y roles para que PHP los consuma.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LOGIN(
    p_username IN  VARCHAR2,
    p_password IN  VARCHAR2,
    p_cursor   OUT SYS_REFCURSOR
) IS
    v_hash  VARCHAR2(128);
    v_count NUMBER := 0;

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT u.ID_USUARIO,
        u.USERNAME,
        u.NOMBRE_COMPLETO,
        u.EMAIL,
        r.ID_ROL,
        r.NOMBRE_ROL
        FROM LHAOMRJZ_USUARIO u
        INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
        WHERE LOWER(u.USERNAME) = LOWER(TRIM(p_username))
        AND u.PASSWORD_HASH = v_hash
        AND u.ESTADO = 'ACTIVO';
    v_registro_cursor cur_local%ROWTYPE;
BEGIN
    v_hash := LHAOMRJZ_FN_HASH_PASSWORD(p_password);
    v_count := LHAOMRJZ_FN_CONTAR_LOGIN(p_username, v_hash);

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Usuario o contrasena incorrectos, o la cuenta esta inactiva.');
    END IF;

    -- Esta parte del código se encarga de abrir, leer y cerrar el cursor local sin consumir el SYS_REFCURSOR de salida.
    OPEN cur_local;
    FETCH cur_local INTO v_registro_cursor;
    IF cur_local%NOTFOUND THEN
        NULL;
    END IF;
    CLOSE cur_local;
    OPEN p_cursor FOR
        SELECT u.ID_USUARIO,
               u.USERNAME,
               u.NOMBRE_COMPLETO,
               u.EMAIL,
               r.ID_ROL,
               r.NOMBRE_ROL
          FROM LHAOMRJZ_USUARIO u
          INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
         WHERE LOWER(u.USERNAME) = LOWER(TRIM(p_username))
           AND u.PASSWORD_HASH = v_hash
           AND u.ESTADO = 'ACTIVO';
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LOGIN: ' || SQLERRM);
END LHAOMRJZ_PS_LOGIN;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_ROLES(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL
        FROM LHAOMRJZ_ROL
        ORDER BY ID_ROL ASC;
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
        SELECT ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL
        FROM LHAOMRJZ_ROL
        ORDER BY ID_ROL ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_ROLES: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_ROLES;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_USUARIOS(
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT u.ID_USUARIO, u.USERNAME, u.NOMBRE_COMPLETO, u.EMAIL,
        u.ESTADO, r.NOMBRE_ROL, u.FECHA_CREACION
        FROM LHAOMRJZ_USUARIO u
        INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
        ORDER BY u.ID_USUARIO ASC;
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
        SELECT u.ID_USUARIO, u.USERNAME, u.NOMBRE_COMPLETO, u.EMAIL,
               u.ESTADO, r.NOMBRE_ROL, u.FECHA_CREACION
          FROM LHAOMRJZ_USUARIO u
          INNER JOIN LHAOMRJZ_ROL r ON u.ID_ROL = r.ID_ROL
         ORDER BY u.ID_USUARIO ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_USUARIOS: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_USUARIOS;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_CAMBIAR_ESTADO_USUARIO(
    p_id_usuario IN NUMBER,
    p_estado     IN VARCHAR2
) IS
BEGIN
    IF UPPER(TRIM(p_estado)) NOT IN ('ACTIVO', 'INACTIVO') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Estado de usuario invalido: use ACTIVO o INACTIVO.');
    END IF;

    UPDATE LHAOMRJZ_USUARIO
       SET ESTADO = UPPER(TRIM(p_estado))
     WHERE ID_USUARIO = p_id_usuario;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'No se encontro el usuario especificado.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END LHAOMRJZ_PS_CAMBIAR_ESTADO_USUARIO;
/

-- Esta parte del código se encarga de obtener el identificador interno de un rol.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_OBTENER_ID_ROL (
    p_nombre_rol IN VARCHAR2
) RETURN NUMBER IS
    v_id_rol NUMBER;
BEGIN
    SELECT ID_ROL INTO v_id_rol FROM LHAOMRJZ_ROL WHERE NOMBRE_ROL = p_nombre_rol;
    RETURN v_id_rol;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20094, 'El rol indicado no existe.');
END;
/

-- Esta parte del código se encarga de validar contraseñas robustas y privilegios.
CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_VALIDAR_PASSWORD (
    p_password IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    IF p_password IS NULL OR LENGTH(p_password) < 8 OR LENGTH(p_password) > 16 THEN
        RETURN 'La contrasena debe tener entre 8 y 16 caracteres.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[A-Z]') THEN
        RETURN 'La contrasena debe incluir al menos una letra mayuscula.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[a-z]') THEN
        RETURN 'La contrasena debe incluir al menos una letra minuscula.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[0-9]') THEN
        RETURN 'La contrasena debe incluir al menos un numero.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[^A-Za-z0-9]') THEN
        RETURN 'La contrasena debe incluir al menos un caracter especial (ej: @, #, $, %, !, .).';
    END IF;
    RETURN 'OK';
END;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_CREAR_USUARIO_SEGURO (
    p_username        IN  VARCHAR2,
    p_password        IN  VARCHAR2,
    p_nombre_completo IN  VARCHAR2,
    p_email           IN  VARCHAR2,
    p_rol_solicitado  IN  VARCHAR2,
    p_rol_ejecutor    IN  VARCHAR2,
    p_estado          OUT VARCHAR2,
    p_mensaje         OUT VARCHAR2
) IS
    v_val_pass  VARCHAR2(200);
    v_id_rol    NUMBER;
    v_rol_final VARCHAR2(30);
BEGIN
    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        p_estado  := 'ADVERTENCIA';
        p_mensaje := 'El nombre de usuario es obligatorio.';
        RETURN;
    END IF;
    IF p_nombre_completo IS NULL OR TRIM(p_nombre_completo) = '' THEN
        p_estado  := 'ADVERTENCIA';
        p_mensaje := 'El nombre completo es obligatorio.';
        RETURN;
    END IF;
    IF p_email IS NOT NULL
       AND NOT REGEXP_LIKE(TRIM(p_email), '^[^@]+@[^@]+\.[^@]{2,}$') THEN
        p_estado  := 'ADVERTENCIA';
        p_mensaje := 'El correo electronico no tiene un formato valido (ej. usuario@dominio.cl).';
        RETURN;
    END IF;

    v_val_pass := LHAOMRJZ_FN_VALIDAR_PASSWORD(p_password);
    IF v_val_pass <> 'OK' THEN
        p_estado  := 'ADVERTENCIA';
        p_mensaje := v_val_pass;
        RETURN;
    END IF;

    -- Esta parte del código se encarga de permitir solo al ADMINISTRADOR crear cuentas con mas privilegios.
    IF UPPER(NVL(p_rol_ejecutor, 'PUBLICO')) <> 'ADMINISTRADOR' THEN
        v_rol_final := 'VENDEDOR';
    ELSE
        v_rol_final := NVL(UPPER(TRIM(p_rol_solicitado)), 'VENDEDOR');
    END IF;

    v_id_rol := LHAOMRJZ_FN_OBTENER_ID_ROL(v_rol_final);

    INSERT INTO LHAOMRJZ_USUARIO (
        ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL
    ) VALUES (
        LHAOMRJZ_SEQ_USUARIO.NEXTVAL,
        LOWER(TRIM(p_username)),
        RAWTOHEX(STANDARD_HASH(p_password, 'SHA256')),
        INITCAP(TRIM(p_nombre_completo)),
        LOWER(TRIM(p_email)),
        'ACTIVO',
        v_id_rol
    );

    COMMIT;
    p_estado  := 'OK';
    p_mensaje := 'Usuario ' || LOWER(TRIM(p_username)) || ' creado correctamente con rol ' || v_rol_final || '.';

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_estado  := 'ADVERTENCIA';
        p_mensaje := 'El nombre de usuario "' || p_username || '" ya existe. Elige otro para continuar.';
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_estado  := 'ADVERTENCIA';
        p_mensaje := 'El rol solicitado no existe.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_estado  := 'ERROR';
        p_mensaje := 'No se pudo registrar el usuario: ' || SQLERRM;
END;
/


-- Esta parte del código se encarga de permitir crear usuarios solo a administradores.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_CREAR_USUARIO_ADMIN (
    p_username         IN  VARCHAR2,
    p_password         IN  VARCHAR2,
    p_password_confirm IN  VARCHAR2,
    p_nombre_completo  IN  VARCHAR2,
    p_email            IN  VARCHAR2,
    p_rol              IN  VARCHAR2,
    p_estado           OUT VARCHAR2,
    p_mensaje          OUT VARCHAR2
) IS
BEGIN
    IF p_password IS NULL OR p_password_confirm IS NULL
       OR p_password <> p_password_confirm THEN
        p_estado  := 'ADVERTENCIA';
        p_mensaje := 'Las contrasenas no coinciden. Escribe la misma clave en ambos campos.';
        RETURN;
    END IF;

    LHAOMRJZ_PS_CREAR_USUARIO_SEGURO(
        p_username, p_password, p_nombre_completo, p_email,
        p_rol, 'ADMINISTRADOR', p_estado, p_mensaje
    );
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_CREAR_USUARIO_ADMIN: ' || SQLERRM);
END LHAOMRJZ_PS_CREAR_USUARIO_ADMIN;
/

-- Esta parte del código se encarga de entregar el menu autorizado segun el rol.
CREATE OR REPLACE VIEW LHAOMRJZ_VW_MENU_ROL AS
WITH MODULOS AS (
    SELECT 'dashboard' AS CODIGO, 'Panel' AS ETIQUETA, 'PRINCIPAL' AS GRUPO, 1 AS ORDEN,
           'ADMINISTRADOR,VENDEDOR,OPERACIONES' AS ROLES FROM DUAL
    UNION ALL SELECT 'regiones', 'Regiones', 'MANTENEDORES', 10, 'ADMINISTRADOR' FROM DUAL
    UNION ALL SELECT 'comunas', 'Comunas', 'MANTENEDORES', 11, 'ADMINISTRADOR' FROM DUAL
    UNION ALL SELECT 'terminales', 'Terminales', 'MANTENEDORES', 12, 'ADMINISTRADOR' FROM DUAL
    UNION ALL SELECT 'empresas', 'Empresas', 'MANTENEDORES', 13, 'ADMINISTRADOR' FROM DUAL
    UNION ALL SELECT 'buses', 'Buses', 'MANTENEDORES', 14, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'asientos', 'Asientos', 'MANTENEDORES', 15, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'conductores', 'Conductores', 'MANTENEDORES', 16, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'mecanicos', 'Mecanicos', 'MANTENEDORES', 17, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'rutas', 'Rutas', 'MANTENEDORES', 18, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'paradas', 'Paradas por ruta', 'MANTENEDORES', 19, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'horarios', 'Horarios', 'MANTENEDORES', 20, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'pasajeros', 'Pasajeros', 'MANTENEDORES', 21, 'ADMINISTRADOR,VENDEDOR' FROM DUAL
    UNION ALL SELECT 'venta', 'Venta de boletos', 'GESTION', 30, 'ADMINISTRADOR,VENDEDOR' FROM DUAL
    UNION ALL SELECT 'bajada', 'Registrar bajada', 'GESTION', 31, 'ADMINISTRADOR,VENDEDOR' FROM DUAL
    UNION ALL SELECT 'viaje', 'Programar viaje', 'GESTION', 32, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'conduce', 'Asignar conductor', 'GESTION', 33, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'mantencion', 'Mantenciones', 'GESTION', 34, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'utilizan', 'Terminal-empresa', 'GESTION', 35, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'usuarios', 'Usuarios', 'SEGURIDAD', 40, 'ADMINISTRADOR' FROM DUAL
    UNION ALL SELECT 'recaudacion', 'Recaudacion por viaje', 'REPORTES', 50, 'ADMINISTRADOR,VENDEDOR' FROM DUAL
    UNION ALL SELECT 'rep_mantencion', 'Costos de mantencion', 'REPORTES', 51, 'ADMINISTRADOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'ocupacion', 'Ocupacion de asientos', 'REPORTES', 52, 'ADMINISTRADOR,VENDEDOR,OPERACIONES' FROM DUAL
    UNION ALL SELECT 'itinerario', 'Itinerario y paradas', 'REPORTES', 53, 'ADMINISTRADOR,VENDEDOR,OPERACIONES' FROM DUAL
)
SELECT r.NOMBRE_ROL, m.CODIGO, m.ETIQUETA, m.GRUPO, m.ORDEN
  FROM LHAOMRJZ_ROL r
 CROSS JOIN MODULOS m
 WHERE ',' || m.ROLES || ',' LIKE '%,' || r.NOMBRE_ROL || ',%';
/

CREATE OR REPLACE FUNCTION LHAOMRJZ_FN_ROL_PERMITE (
    p_rol    IN VARCHAR2,
    p_modulo IN VARCHAR2
) RETURN CHAR IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM LHAOMRJZ_VW_MENU_ROL
     WHERE NOMBRE_ROL = UPPER(TRIM(p_rol))
       AND CODIGO = LOWER(TRIM(p_modulo));

    RETURN CASE WHEN v_count > 0 THEN 'S' ELSE 'N' END;
END LHAOMRJZ_FN_ROL_PERMITE;
/

-- Esta parte del código se encarga de entregar el permiso del rol como procedimiento invocable por la aplicacion.
CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_ROL_PERMITE (
    p_rol       IN  VARCHAR2,
    p_modulo    IN  VARCHAR2,
    p_resultado OUT VARCHAR2
) IS
BEGIN
    p_resultado := LHAOMRJZ_FN_ROL_PERMITE(p_rol, p_modulo);
EXCEPTION
    WHEN OTHERS THEN
        p_resultado := 'N';
END;
/

CREATE OR REPLACE PROCEDURE LHAOMRJZ_PS_LISTAR_MENU (
    p_rol    IN  VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) IS

    -- Esta parte del código se encarga de declarar el cursor local de validación sobre la misma consulta.
    CURSOR cur_local IS
        SELECT CODIGO, ETIQUETA, GRUPO, ORDEN
        FROM LHAOMRJZ_VW_MENU_ROL
        WHERE NOMBRE_ROL = UPPER(TRIM(p_rol))
        ORDER BY ORDEN ASC;
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
        SELECT CODIGO, ETIQUETA, GRUPO, ORDEN
          FROM LHAOMRJZ_VW_MENU_ROL
         WHERE NOMBRE_ROL = UPPER(TRIM(p_rol))
         ORDER BY ORDEN ASC;
    -- Esta parte del código se encarga de confirmar la transacción antes de finalizar.
    COMMIT;
EXCEPTION
    -- Esta parte del código se encarga de revertir cambios y reportar el error en español.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Error en LHAOMRJZ_PS_LISTAR_MENU: ' || SQLERRM);
END LHAOMRJZ_PS_LISTAR_MENU;
/