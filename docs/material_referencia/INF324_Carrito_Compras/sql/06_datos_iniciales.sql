-- ============================================================================
-- SCRIPT 06: DATOS DE PRUEBA (POBLAMIENTO INICIAL COHERENTE)
-- Asignatura: INF324 - Base de Datos
-- Requisito de Rúbrica: "Datos reales y previamente cargados"
-- ============================================================================

-- 1. Insertar Roles
INSERT INTO ROLES (id_rol, nombre_rol, descripcion) VALUES (SEQ_ROLES.NEXTVAL, 'Administrador', 'Control total del sistema y reportes');
INSERT INTO ROLES (id_rol, nombre_rol, descripcion) VALUES (SEQ_ROLES.NEXTVAL, 'Vendedor', 'Acceso a ventas, clientes y catálogo');
INSERT INTO ROLES (id_rol, nombre_rol, descripcion) VALUES (SEQ_ROLES.NEXTVAL, 'Auditor', 'Visualización de reportes y auditoría de inventario');

-- 2. Insertar Usuarios (Clave en texto plano para demostración didáctica: 'admin123', 'vendedor123')
INSERT INTO USUARIOS (id_usuario, id_rol, nombre_completo, email, clave, estado, fecha_registro) 
VALUES (SEQ_USUARIOS.NEXTVAL, 1, 'Profesor Evaluador', 'admin@ucm.cl', 'admin123', 'A', SYSDATE);

INSERT INTO USUARIOS (id_usuario, id_rol, nombre_completo, email, clave, estado, fecha_registro) 
VALUES (SEQ_USUARIOS.NEXTVAL, 2, 'Carlos Vendedor', 'vendedor@ucm.cl', 'vendedor123', 'A', SYSDATE);

-- 3. Insertar Categorías
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria, descripcion) VALUES (SEQ_CATEGORIAS.NEXTVAL, 'Lácteos y Huevos', 'Leches, quesos, yogures y derivados');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria, descripcion) VALUES (SEQ_CATEGORIAS.NEXTVAL, 'Bebidas y Licores', 'Aguas, gaseosas, jugos y vinos');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria, descripcion) VALUES (SEQ_CATEGORIAS.NEXTVAL, 'Abarrotes', 'Arroz, fideos, aceites y legumbres');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria, descripcion) VALUES (SEQ_CATEGORIAS.NEXTVAL, 'Snacks y Confites', 'Galletas, chocolates y papas fritas');

-- 4. Insertar Productos
INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 1, '78010001', 'Leche Entera 1L Colun', 1150.00, 45, 10, 'A');

INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 1, '78010002', 'Queso Gauda Laminado 250g', 2490.00, 30, 8, 'A');

INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 2, '78020001', 'Bebida Coca Cola Original 2.5L', 2790.00, 60, 15, 'A');

INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 2, '78020002', 'Jugo Néctar Andina Durazno 1.5L', 1450.00, 25, 10, 'A');

INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 3, '78030001', 'Arroz Grado 1 Tucapel 1Kg', 1690.00, 80, 20, 'A');

INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 3, '78030002', 'Aceite Vegetal Belmont 900ml', 2190.00, 50, 12, 'A');

INSERT INTO PRODUCTOS (id_producto, id_categoria, codigo_barra, nombre_producto, precio_venta, stock_actual, stock_minimo, estado)
VALUES (SEQ_PRODUCTOS.NEXTVAL, 4, '78040001', 'Papas Fritas Lays Clásicas 200g', 1890.00, 4, 10, 'A'); -- Stock crítico intencional para mostrar alerta

-- 5. Insertar Clientes
-- Cliente 1: Consumidor Final / Cliente Ocasional (Preseleccionado por defecto en caja)
INSERT INTO CLIENTES (id_cliente, rut, nombres, apellidos, email, telefono, direccion, estado)
VALUES (SEQ_CLIENTES.NEXTVAL, '66.666.666-6', 'Consumidor Final', '(Cliente Ocasional)', 'cliente.ocasional@ventas.cl', NULL, 'Sin dirección registrada', 'A');

INSERT INTO CLIENTES (id_cliente, rut, nombres, apellidos, email, telefono, direccion, estado)
VALUES (SEQ_CLIENTES.NEXTVAL, '18.456.789-0', 'Juan', 'Pérez González', 'juan.perez@gmail.com', '+56911223344', 'Av. San Miguel 3605, Talca', 'A');

INSERT INTO CLIENTES (id_cliente, rut, nombres, apellidos, email, telefono, direccion, estado)
VALUES (SEQ_CLIENTES.NEXTVAL, '19.876.543-2', 'María', 'Rojas Sepúlveda', 'maria.rojas@gmail.com', '+56988776655', 'Calle 1 Oriente 1234, Talca', 'A');

INSERT INTO CLIENTES (id_cliente, rut, nombres, apellidos, email, telefono, direccion, estado)
VALUES (SEQ_CLIENTES.NEXTVAL, '20.123.456-7', 'Ignacio', 'Muñoz Silva', 'ignacio.munoz@alumnos.ucm.cl', '+56955443322', '2 Norte 567, Curicó', 'A');

COMMIT;

-- 6. Ejecutar una venta de prueba mediante el Gestor para poblar históricos
DECLARE
    v_id_v NUMBER;
    v_fol  VARCHAR2(30);
    v_tot  NUMBER;
    v_res  VARCHAR2(200);
BEGIN
    -- Iniciar venta para el cliente 1, procesada por usuario 1
    pr_la_gestor_iniciar_venta(1, 1, v_id_v, v_fol, v_res);

    -- Agregar ítems a la venta
    pr_la_gestor_agregar_item(v_id_v, 1, 3, v_res); -- 3 unidades de Leche
    pr_la_gestor_agregar_item(v_id_v, 3, 2, v_res); -- 2 unidades de Coca Cola

    -- Finalizar y confirmar la venta
    pr_la_gestor_finalizar_venta(v_id_v, v_tot, v_res);

    DBMS_OUTPUT.PUT_LINE(v_res || ' - Folio: ' || v_fol || ' - Total: $' || v_tot);
END;
/

COMMIT;
