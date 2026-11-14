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