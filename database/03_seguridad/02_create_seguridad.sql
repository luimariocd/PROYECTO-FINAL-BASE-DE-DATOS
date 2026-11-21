ALTER SESSION SET CURRENT_SCHEMA = LEHZ;

-- =========================================================================
-- SEGURIDAD: ROLES, USUARIOS, AUDITORIA Y PAQUETE DE AUTENTICACION
-- La verificacion de credenciales, el hash SHA-256, la validacion de datos
-- y los mensajes de error se ejecutan integramente en Oracle.
-- =========================================================================

CREATE TABLE LEHZ_ROL (
    ID_ROL          NUMBER NOT NULL,
    NOMBRE_ROL      VARCHAR2(30) NOT NULL,
    DESCRIPCION_ROL VARCHAR2(150),
    CONSTRAINT PK_LEHZ_ROL PRIMARY KEY (ID_ROL),
    CONSTRAINT UQ_LEHZ_NOMBRE_ROL UNIQUE (NOMBRE_ROL),
    CONSTRAINT CK_LEHZ_ROL_NOMBRE CHECK (NOMBRE_ROL IN ('ADMINISTRADOR', 'VENDEDOR', 'OPERACIONES'))
);

CREATE TABLE LEHZ_USUARIO (
    ID_USUARIO       NUMBER NOT NULL,
    USERNAME         VARCHAR2(40) NOT NULL,
    PASSWORD_HASH    VARCHAR2(128) NOT NULL,
    NOMBRE_COMPLETO  VARCHAR2(120) NOT NULL,
    EMAIL            VARCHAR2(80),
    ESTADO           VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL,
    ID_ROL           NUMBER NOT NULL,
    FECHA_CREACION   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_LEHZ_USUARIO PRIMARY KEY (ID_USUARIO),
    CONSTRAINT UQ_LEHZ_USERNAME UNIQUE (USERNAME),
    CONSTRAINT CK_LEHZ_USUARIO_ESTADO CHECK (ESTADO IN ('ACTIVO', 'INACTIVO')),
    CONSTRAINT CK_LEHZ_USUARIO_USERNAME CHECK (REGEXP_LIKE(USERNAME, '^[a-z0-9._-]{4,40}$')),
    CONSTRAINT FK_LEHZ_USUARIO_ROL FOREIGN KEY (ID_ROL) REFERENCES LEHZ_ROL (ID_ROL)
);

CREATE TABLE LEHZ_AUDITORIA (
    ID_AUDITORIA    NUMBER NOT NULL,
    TABLA_AFECTADA  VARCHAR2(40) NOT NULL,
    OPERACION       VARCHAR2(15) NOT NULL,
    ID_REGISTRO     VARCHAR2(60),
    DETALLE         VARCHAR2(500),
    USUARIO_BD      VARCHAR2(40) DEFAULT USER NOT NULL,
    FECHA_EVENTO    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT PK_LEHZ_AUDITORIA PRIMARY KEY (ID_AUDITORIA)
);

CREATE INDEX IDX_LEHZ_USUARIO_ROL ON LEHZ_USUARIO (ID_ROL);
CREATE INDEX IDX_LEHZ_AUDITORIA_FECHA ON LEHZ_AUDITORIA (FECHA_EVENTO);

-- =========================================================================
-- DATOS INICIALES DE SEGURIDAD
-- =========================================================================

INSERT INTO LEHZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LEHZ_SEQ_ROL.NEXTVAL, 'ADMINISTRADOR', 'Acceso total a mantenedores, gestores, reportes y seguridad');

INSERT INTO LEHZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LEHZ_SEQ_ROL.NEXTVAL, 'VENDEDOR', 'Acceso a venta de boletos, pagos y consulta de viajes');

INSERT INTO LEHZ_ROL (ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL)
VALUES (LEHZ_SEQ_ROL.NEXTVAL, 'OPERACIONES', 'Acceso a gestion de flota, viajes, conductores y mantenciones');

-- Usuarios iniciales (hash SHA-256 calculado por Oracle)
INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'admin',
    RAWTOHEX(STANDARD_HASH('Admin1234', 'SHA256')),
    'Administrador General',
    'admin@transporteucm.cl',
    'ACTIVO',
    (SELECT ID_ROL FROM LEHZ_ROL WHERE NOMBRE_ROL = 'ADMINISTRADOR')
);

INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'vendedor1',
    RAWTOHEX(STANDARD_HASH('Ventas1234', 'SHA256')),
    'Ejecutivo Boleteria Talca',
    'ventas@transporteucm.cl',
    'ACTIVO',
    (SELECT ID_ROL FROM LEHZ_ROL WHERE NOMBRE_ROL = 'VENDEDOR')
);

INSERT INTO LEHZ_USUARIO (ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL)
VALUES (
    LEHZ_SEQ_USUARIO.NEXTVAL,
    'operador1',
    RAWTOHEX(STANDARD_HASH('Flota1234', 'SHA256')),
    'Coordinador de Flota',
    'flota@transporteucm.cl',
    'ACTIVO',
    (SELECT ID_ROL FROM LEHZ_ROL WHERE NOMBRE_ROL = 'OPERACIONES')
);

COMMIT;

-- =========================================================================
-- PAQUETE DE SEGURIDAD
-- =========================================================================

CREATE OR REPLACE PACKAGE LEHZ_PKG_SEGURIDAD AS

    PROCEDURE SP_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_cursor   OUT SYS_REFCURSOR
    );

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

    PROCEDURE SP_LISTAR_ROLES(
        p_cursor OUT SYS_REFCURSOR
    );

END LEHZ_PKG_SEGURIDAD;
/

CREATE OR REPLACE PACKAGE BODY LEHZ_PKG_SEGURIDAD AS

    PROCEDURE SP_VALIDAR_LOGIN(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_cursor   OUT SYS_REFCURSOR
    ) IS
        v_hash VARCHAR2(128);
    BEGIN
        IF p_username IS NULL OR p_password IS NULL THEN
            OPEN p_cursor FOR
                SELECT u.ID_USUARIO, u.USERNAME, u.NOMBRE_COMPLETO, u.EMAIL,
                       r.ID_ROL, r.NOMBRE_ROL
                FROM LEHZ_USUARIO u
                INNER JOIN LEHZ_ROL r ON u.ID_ROL = r.ID_ROL
                WHERE 1 = 0;
            RETURN;
        END IF;

        SELECT RAWTOHEX(STANDARD_HASH(p_password, 'SHA256'))
        INTO v_hash
        FROM DUAL;

        OPEN p_cursor FOR
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
    END SP_VALIDAR_LOGIN;

    PROCEDURE SP_CREAR_USUARIO(
        p_username        IN VARCHAR2,
        p_password        IN VARCHAR2,
        p_nombre_completo IN VARCHAR2,
        p_email           IN VARCHAR2,
        p_id_rol          IN NUMBER,
        p_id_generado     OUT NUMBER
    ) IS
        v_hash     VARCHAR2(128);
        v_username VARCHAR2(40);
        v_nombre   VARCHAR2(120);
        v_email    VARCHAR2(80);
        v_existe   NUMBER := 0;
        v_rol      NUMBER := 0;
        v_error    VARCHAR2(400);
    BEGIN
        v_username := LOWER(TRIM(p_username));
        v_nombre   := LEHZ_FN_TITULO(p_nombre_completo);
        v_email    := LOWER(TRIM(p_email));

        IF v_username IS NULL OR NOT REGEXP_LIKE(v_username, '^[a-z0-9._-]{4,40}$') THEN
            RAISE_APPLICATION_ERROR(-20003,
                'Usuario invalido: debe tener entre 4 y 40 caracteres y solo puede usar letras, numeros, punto, guion o guion bajo.');
        END IF;

        IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
            RAISE_APPLICATION_ERROR(-20004,
                'Contrasena invalida: debe tener al menos 8 caracteres.');
        END IF;

        v_error := LEHZ_FN_ERROR_TEXTO(v_nombre, 'nombre completo');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20005, v_error);
        END IF;

        v_error := LEHZ_FN_ERROR_EMAIL(v_email, 'S');
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20006, v_error);
        END IF;

        SELECT COUNT(*) INTO v_rol FROM LEHZ_ROL WHERE ID_ROL = p_id_rol;
        IF v_rol = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'El rol seleccionado no existe.');
        END IF;

        SELECT COUNT(*) INTO v_existe
        FROM LEHZ_USUARIO
        WHERE LOWER(USERNAME) = v_username;

        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'El nombre de usuario ya existe en el sistema.');
        END IF;

        SELECT RAWTOHEX(STANDARD_HASH(p_password, 'SHA256'))
        INTO v_hash
        FROM DUAL;

        p_id_generado := LEHZ_SEQ_USUARIO.NEXTVAL;

        INSERT INTO LEHZ_USUARIO (
            ID_USUARIO, USERNAME, PASSWORD_HASH, NOMBRE_COMPLETO, EMAIL, ESTADO, ID_ROL
        ) VALUES (
            p_id_generado, v_username, v_hash, v_nombre, v_email, 'ACTIVO', p_id_rol
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
        v_estado VARCHAR2(10);
        v_rol    VARCHAR2(30);
        v_admin  NUMBER := 0;
    BEGIN
        v_estado := UPPER(TRIM(p_estado));

        IF v_estado NOT IN ('ACTIVO', 'INACTIVO') THEN
            RAISE_APPLICATION_ERROR(-20008, 'Estado invalido: debe ser ACTIVO o INACTIVO.');
        END IF;

        SELECT r.NOMBRE_ROL
        INTO v_rol
        FROM LEHZ_USUARIO u
        INNER JOIN LEHZ_ROL r ON u.ID_ROL = r.ID_ROL
        WHERE u.ID_USUARIO = p_id_usuario;

        IF v_rol = 'ADMINISTRADOR' AND v_estado = 'INACTIVO' THEN
            SELECT COUNT(*)
            INTO v_admin
            FROM LEHZ_USUARIO u
            INNER JOIN LEHZ_ROL r ON u.ID_ROL = r.ID_ROL
            WHERE r.NOMBRE_ROL = 'ADMINISTRADOR'
              AND u.ESTADO = 'ACTIVO';

            IF v_admin <= 1 THEN
                RAISE_APPLICATION_ERROR(-20009,
                    'No se puede desactivar al ultimo administrador activo del sistema.');
            END IF;
        END IF;

        UPDATE LEHZ_USUARIO
        SET ESTADO = v_estado
        WHERE ID_USUARIO = p_id_usuario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'No se encontro el usuario especificado.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'No se encontro el usuario especificado.');
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
                   TO_CHAR(u.FECHA_CREACION, 'YYYY-MM-DD') AS FECHA_CREACION
            FROM LEHZ_USUARIO u
            INNER JOIN LEHZ_ROL r ON u.ID_ROL = r.ID_ROL
            ORDER BY u.ID_USUARIO ASC;
    END SP_LISTAR_USUARIOS;

    PROCEDURE SP_LISTAR_ROLES(
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT ID_ROL, NOMBRE_ROL, DESCRIPCION_ROL
            FROM LEHZ_ROL
            ORDER BY ID_ROL ASC;
    END SP_LISTAR_ROLES;

END LEHZ_PKG_SEGURIDAD;
/
