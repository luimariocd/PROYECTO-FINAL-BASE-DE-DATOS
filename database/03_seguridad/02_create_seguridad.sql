ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

CREATE TABLE LEHZ_ROL (
    ID_ROL NUMBER NOT NULL,
    NOMBRE_ROL VARCHAR2(30) NOT NULL,
    DESCRIPCION_ROL VARCHAR2(150),
    CONSTRAINT PK_LEHZ_ROL PRIMARY KEY (ID_ROL),
    CONSTRAINT UQ_LEHZ_NOMBRE_ROL UNIQUE (NOMBRE_ROL)
);

CREATE TABLE LEHZ_USUARIO (
    ID_USUARIO NUMBER NOT NULL,
    USERNAME VARCHAR2(40) NOT NULL,
    PASSWORD_HASH VARCHAR2(128) NOT NULL,
    NOMBRE_COMPLETO VARCHAR2(120) NOT NULL,
    EMAIL VARCHAR2(80),
    ESTADO VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL,
    ID_ROL NUMBER NOT NULL,
    FECHA_CREACION DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_LEHZ_USUARIO PRIMARY KEY (ID_USUARIO),
    CONSTRAINT UQ_LEHZ_USERNAME UNIQUE (USERNAME),
    CONSTRAINT CK_LEHZ_USUARIO_ESTADO CHECK (ESTADO IN ('ACTIVO', 'INACTIVO')),
    CONSTRAINT FK_USUARIO_ROL FOREIGN KEY (ID_ROL) REFERENCES LEHZ_ROL (ID_ROL)
);

CREATE TABLE LEHZ_AUDITORIA (
    ID_AUDITORIA NUMBER NOT NULL,
    TABLA_AFECTADA VARCHAR2(40) NOT NULL,
    OPERACION VARCHAR2(15) NOT NULL,
    ID_REGISTRO VARCHAR2(60),
    DETALLE VARCHAR2(500),
    USUARIO_BD VARCHAR2(40) DEFAULT USER NOT NULL,
    FECHA_EVENTO TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT PK_LEHZ_AUDITORIA PRIMARY KEY (ID_AUDITORIA)
);

-- DATOS DE PRUEBA

INSERT INTO LEHZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LEHZ_SEQ_ROL.NEXTVAL, 'ADMINISTRADOR', 'Acceso total a mantenedores, gestores, reportes y seguridad');

INSERT INTO LEHZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LEHZ_SEQ_ROL.NEXTVAL, 'VENDEDOR', 'Acceso a venta de boletos, pagos y consulta de viajes');

INSERT INTO LEHZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LEHZ_SEQ_ROL.NEXTVAL, 'OPERACIONES', 'Acceso a gestion de flota, viajes, conductores y mantenciones');

-- Usuarios iniciales (clave encriptada con SHA256)
INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'admin',
    RAWTOHEX(STANDARD_HASH('Admin1234', 'SHA256')),
    'Administrador General',
    'admin@transporteucm.cl',
    'ACTIVO',
    1
);

INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'vendedor1',
    RAWTOHEX(STANDARD_HASH('Ventas1234', 'SHA256')),
    'Ejecutivo Boleteria Talca',
    'ventas@transporteucm.cl',
    'ACTIVO',
    2
);

INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'operador1',
    RAWTOHEX(STANDARD_HASH('Flota1234', 'SHA256')),
    'Coordinador de Flota',
    'flota@transporteucm.cl',
    'ACTIVO',
    3
);

-- ==================== [NUEVO] USUARIO ADMINISTRADOR DENUNCE ====================
INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'denunce',
    RAWTOHEX(STANDARD_HASH('Mario1234', 'SHA256')),
    'Administrador Denunce',
    'denunce@transporteucm.cl',
    'ACTIVO',
    1
);
-- ===============================================================================

COMMIT;

-- CONTROL DE ACCESO

CREATE OR REPLACE PACKAGE LEHZ_PKG_SEGURIDAD AS
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
END LEHZ_PKG_SEGURIDAD;
/

CREATE OR REPLACE PACKAGE BODY LEHZ_PKG_SEGURIDAD AS

    FUNCTION FN_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
        v_hash   VARCHAR2(128);
    BEGIN
        SELECT RAWTOHEX(STANDARD_HASH(p_password, 'SHA256'))
        INTO v_hash
        FROM DUAL;

        OPEN v_cursor FOR
            SELECT u.ID_USUARIO,
                   u.USERNAME,
                   u.NOMBRE_COMPLETO,
                   u.EMAIL,
                   r.ID_ROL,
                   r.NOMBRE_ROL
            FROM LEHZ_USUARIO u
            INNER JOIN LEHZ_ROL r ON u.ID_ROL = r.ID_ROL
            WHERE LOWER(u.USERNAME) = LOWER(TRIM(p_username))
              AND u.PASSWORD_HASH = v_hash
              AND u.ESTADO = 'ACTIVO';

        RETURN v_cursor;
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
        SELECT RAWTOHEX(STANDARD_HASH(p_password, 'SHA256'))
        INTO v_hash
        FROM DUAL;

        p_id_generado := LEHZ_SEQ_USUARIO.NEXTVAL;

        INSERT INTO LEHZ_USUARIO (
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
        UPDATE LEHZ_USUARIO
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
    BEGIN
        OPEN p_cursor FOR
            SELECT u.ID_USUARIO,
                   u.USERNAME,
                   u.NOMBRE_COMPLETO,
                   u.EMAIL,
                   u.ESTADO,
                   r.ID_ROL,
                   r.NOMBRE_ROL,
                   u.FECHA_CREACION
            FROM LEHZ_USUARIO u
            INNER JOIN LEHZ_ROL r ON u.ID_ROL = r.ID_ROL
            ORDER BY u.ID_USUARIO ASC;
    END SP_LISTAR_USUARIOS;

END LEHZ_PKG_SEGURIDAD;
/

-- ==================== [NUEVO] POLITICA DE CONTRASEÑA ROBUSTA Y PRIVILEGIOS =======
CREATE OR REPLACE FUNCTION LEHZ_FN_VALIDAR_PASSWORD (
    p_password IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    IF p_password IS NULL OR LENGTH(p_password) < 8 OR LENGTH(p_password) > 16 THEN
        RETURN 'La contraseña debe tener entre 8 y 16 caracteres.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[A-Z]') THEN
        RETURN 'La contraseña debe incluir al menos una letra mayúscula.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[a-z]') THEN
        RETURN 'La contraseña debe incluir al menos una letra minúscula.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[0-9]') THEN
        RETURN 'La contraseña debe incluir al menos un número.';
    END IF;
    IF NOT REGEXP_LIKE(p_password, '[^A-Za-z0-9]') THEN
        RETURN 'La contraseña debe incluir al menos un carácter especial (ej: @, #, $, %, !, .).';
    END IF;
    RETURN 'OK';
END;
/

CREATE OR REPLACE PROCEDURE LEHZ_PS_CREAR_USUARIO_SEGURO (
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
    v_val_pass := LEHZ_FN_VALIDAR_PASSWORD(p_password);
    IF v_val_pass <> 'OK' THEN
        p_estado  := 'ADVERTENCIA';
        p_mensaje := v_val_pass;
        RETURN;
    END IF;

    -- Solo un ADMINISTRADOR puede crear cuentas con privilegios superiores
    IF UPPER(NVL(p_rol_ejecutor, 'PUBLICO')) <> 'ADMINISTRADOR' THEN
        v_rol_final := 'VENDEDOR';
    ELSE
        v_rol_final := UPPER(TRIM(p_rol_solicitado));
    END IF;

    SELECT ID_ROL INTO v_id_rol
    FROM LEHZ_ROL
    WHERE NOMBRE_ROL = v_rol_final;

    INSERT INTO LEHZ_USUARIO (
        ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL
    ) VALUES (
        LEHZ_SEQ_USUARIO.NEXTVAL,
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
-- =================================================================================