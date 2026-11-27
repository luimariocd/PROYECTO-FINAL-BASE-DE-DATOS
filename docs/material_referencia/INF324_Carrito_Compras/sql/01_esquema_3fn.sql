-- ============================================================================
-- SCRIPT 01: CREACIÓN DE TABLAS Y RESTRICCIONES (MODELO EN 3FN)
-- Asignatura: INF324 - Base de Datos
-- Motor: ORACLE Database
-- Nota Pedagógica: Las restricciones se limitan a PK, FK y UNIQUE.
-- Las validaciones de negocio (precios, stock, cantidades) se delegan 
-- a los Procedimientos Almacenados y Triggers (Arquitectura "Servidor Robusto").
-- ============================================================================

-- Limpieza preventiva de tablas previas si existen (en orden inverso por FKs)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_STOCK CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE DETALLE_VENTAS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE VENTAS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE CLIENTES CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE PRODUCTOS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE CATEGORIAS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE USUARIOS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE ROLES CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignorar errores si no existen previamente
END;
/

-- 1. TABLA: ROLES (Perfiles de seguridad para control de acceso)
CREATE TABLE ROLES (
    id_rol          NUMBER(6) NOT NULL,
    nombre_rol      VARCHAR2(50) NOT NULL,
    descripcion     VARCHAR2(200),
    CONSTRAINT pk_roles PRIMARY KEY (id_rol),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre_rol)
);

-- 2. TABLA: USUARIOS (Autenticación y confidencialidad)
CREATE TABLE USUARIOS (
    id_usuario      NUMBER(8) NOT NULL,
    id_rol          NUMBER(6) NOT NULL,
    nombre_completo VARCHAR2(100) NOT NULL,
    email           VARCHAR2(100) NOT NULL,
    clave           VARCHAR2(255) NOT NULL,
    estado          CHAR(1) DEFAULT 'A' NOT NULL,
    fecha_registro  DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (id_rol) 
        REFERENCES ROLES (id_rol)
);

-- 3. TABLA: CATEGORIAS (Clasificación de productos)
CREATE TABLE CATEGORIAS (
    id_categoria    NUMBER(6) NOT NULL,
    nombre_categoria VARCHAR2(80) NOT NULL,
    descripcion     VARCHAR2(200),
    CONSTRAINT pk_categorias PRIMARY KEY (id_categoria),
    CONSTRAINT uq_cat_nombre UNIQUE (nombre_categoria)
);

-- 4. TABLA: PRODUCTOS (Catálogo y control de existencias)
CREATE TABLE PRODUCTOS (
    id_producto     NUMBER(8) NOT NULL,
    id_categoria    NUMBER(6) NOT NULL,
    codigo_barra    VARCHAR2(50) NOT NULL,
    nombre_producto VARCHAR2(120) NOT NULL,
    precio_venta    NUMBER(10, 2) NOT NULL,
    stock_actual    NUMBER(8) DEFAULT 0 NOT NULL,
    stock_minimo    NUMBER(8) DEFAULT 5 NOT NULL,
    estado          CHAR(1) DEFAULT 'A' NOT NULL,
    CONSTRAINT pk_productos PRIMARY KEY (id_producto),
    CONSTRAINT uq_producto_codigo UNIQUE (codigo_barra),
    CONSTRAINT fk_productos_categoria FOREIGN KEY (id_categoria) 
        REFERENCES CATEGORIAS (id_categoria)
);

-- 5. TABLA: CLIENTES (Entidad de negocio para clientes)
CREATE TABLE CLIENTES (
    id_cliente      NUMBER(8) NOT NULL,
    rut             VARCHAR2(12) NOT NULL,
    nombres         VARCHAR2(80) NOT NULL,
    apellidos       VARCHAR2(80) NOT NULL,
    email           VARCHAR2(100),
    telefono        VARCHAR2(20),
    direccion       VARCHAR2(150),
    estado          CHAR(1) DEFAULT 'A' NOT NULL,
    CONSTRAINT pk_clientes PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_rut UNIQUE (rut)
);

-- 6. TABLA: VENTAS (Cabecera transaccional del Gestor de Ventas)
CREATE TABLE VENTAS (
    id_venta        NUMBER(10) NOT NULL,
    id_cliente      NUMBER(8) NOT NULL,
    id_usuario      NUMBER(8) NOT NULL,
    numero_folio    VARCHAR2(30) NOT NULL,
    fecha_venta     DATE DEFAULT SYSDATE NOT NULL,
    subtotal        NUMBER(12, 2) NOT NULL,
    iva             NUMBER(12, 2) NOT NULL,
    total           NUMBER(12, 2) NOT NULL,
    estado          VARCHAR2(20) DEFAULT 'PAGADA' NOT NULL,
    CONSTRAINT pk_ventas PRIMARY KEY (id_venta),
    CONSTRAINT uq_venta_folio UNIQUE (numero_folio),
    CONSTRAINT fk_ventas_cliente FOREIGN KEY (id_cliente) 
        REFERENCES CLIENTES (id_cliente),
    CONSTRAINT fk_ventas_usuario FOREIGN KEY (id_usuario) 
        REFERENCES USUARIOS (id_usuario)
);

-- 7. TABLA: DETALLE_VENTAS (Líneas de venta: desagregación N:M entre VENTAS y PRODUCTOS)
CREATE TABLE DETALLE_VENTAS (
    id_detalle      NUMBER(12) NOT NULL,
    id_venta        NUMBER(10) NOT NULL,
    id_producto     NUMBER(8) NOT NULL,
    cantidad        NUMBER(6) NOT NULL,
    precio_unitario NUMBER(10, 2) NOT NULL,
    subtotal_linea  NUMBER(12, 2) NOT NULL,
    CONSTRAINT pk_detalle_ventas PRIMARY KEY (id_detalle),
    CONSTRAINT fk_detalle_venta FOREIGN KEY (id_venta) 
        REFERENCES VENTAS (id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto) 
        REFERENCES PRODUCTOS (id_producto)
);

-- 8. TABLA: AUDITORIA_STOCK (Destino de monitoreo y control mediante Triggers)
CREATE TABLE AUDITORIA_STOCK (
    id_auditoria    NUMBER(12) NOT NULL,
    id_producto     NUMBER(8) NOT NULL,
    stock_anterior  NUMBER(8) NOT NULL,
    stock_nuevo     NUMBER(8) NOT NULL,
    diferencia      NUMBER(8) NOT NULL,
    operacion       VARCHAR2(30) NOT NULL,
    usuario_bd      VARCHAR2(50) NOT NULL,
    fecha_registro  DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_auditoria_stock PRIMARY KEY (id_auditoria),
    CONSTRAINT fk_auditoria_producto FOREIGN KEY (id_producto) 
        REFERENCES PRODUCTOS (id_producto)
);

COMMIT;
