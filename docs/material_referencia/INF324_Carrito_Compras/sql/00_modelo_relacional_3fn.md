# Diseño y Modelado Relacional en 3FN - Proyecto Carrito de Compras
**Asignatura:** INF324 - Base de Datos (UCM)  
**Objetivo:** Modelo conceptual y relacional normalizado en 3ra Forma Normal (3FN), sirviendo como referencia para los 10 mantenedores, 5 gestores y 3 reportes.

---

## 1. Justificación de Normalización (Criterios de la Rúbrica)

### Primera Forma Normal (1FN)
* **Atomicidad de Columnas:** Todos los atributos almacenan valores indivisibles (ej. nombres y apellidos separados, RUT sin caracteres mezclados innecesariamente).
* **Eliminación de Grupos Repetitivos:** Ninguna tabla almacena múltiples valores en un solo campo (como listas de productos dentro de una orden). El detalle de cada venta se extrae a una entidad separada (`DETALLE_VENTAS`).
* **Claves Primarias Definidas:** Cada entidad posee una clave primaria (`PK`) unívoca gestionada mediante secuencias de Oracle.

### Segunda Forma Normal (2FN)
* Cumple 1FN.
* **Eliminación de Dependencias Funcionales Parciales:** En tablas con claves compuestas (o intermedias), cada atributo no clave depende de la totalidad de la clave primaria y no de una parte de ella.
* En `DETALLE_VENTAS`, el `PRECIO_UNITARIO` se congela al momento de la venta para preservar la coherencia histórica, dependiendo directamente de la transacción específica.

### Tercera Forma Normal (3FN)
* Cumple 2FN.
* **Eliminación de Dependencias Transitivas:** Ningún atributo no clave depende funcionalmente de otro atributo no clave.
* Por ejemplo: En `PRODUCTOS`, no se almacena el `NOMBRE_CATEGORIA`, sino la clave foránea `ID_CATEGORIA`. En `VENTAS`, no se almacena la dirección del cliente, sino únicamente `ID_CLIENTE`.
* La tabla `USUARIOS` se relaciona con `ROLES` mediante `ID_ROL` para evitar redundancias de perfiles.

---

## 2. Entidades y Diccionario de Datos

```
+-------------------------------------------------------------------------------------------------+
|                                    DIAGRAMA ENTIDAD-RELACIÓN (3FN)                              |
+-------------------------------------------------------------------------------------------------+

     [ROLES] 1 ──────────── N [USUARIOS] 1 ──────────── N [VENTAS] 1 ──────────── N [DETALLE_VENTAS]
                                                                                          │
                                                                                          │ N
                                                                                          │
     [CATEGORIAS] 1 ──────── N [PRODUCTOS] 1 ─────────────────────────────────────────────┘
                                   │
                                   │ 1
                                   │
                                   └── N [AUDITORIA_STOCK] (Alimentado por Trigger)

     [CLIENTES] 1 ────────────────────────────── N [VENTAS]
```

### 1. `ROLES` (Perfiles del Sistema)
* `ID_ROL` (NUMBER, PK): Identificador único del rol (1: Administrador, 2: Vendedor, 3: Cliente).
* `NOMBRE_ROL` (VARCHAR2(50), NOT NULL): Nombre del perfil.
* `DESCRIPCION` (VARCHAR2(200)): Alcance de los permisos.

### 2. `USUARIOS` (Control de Acceso / Autenticación)
* `ID_USUARIO` (NUMBER, PK): Identificador del usuario.
* `ID_ROL` (NUMBER, FK -> ROLES.ID_ROL): Rol asignado.
* `NOMBRE_COMPLETO` (VARCHAR2(100), NOT NULL): Nombre y apellidos.
* `EMAIL` (VARCHAR2(100), UNIQUE, NOT NULL): Correo electrónico para inicio de sesión.
* `CLAVE` (VARCHAR2(255), NOT NULL): Contraseña encriptada/hasheada.
* `ESTADO` (CHAR(1), DEFAULT 'A'): 'A' Activo, 'I' Inactivo.
* `FECHA_REGISTRO` (DATE, DEFAULT SYSDATE): Fecha de alta en el sistema.

### 3. `CATEGORIAS` (Clasificación de Productos)
* `ID_CATEGORIA` (NUMBER, PK): Identificador de la categoría.
* `NOMBRE_CATEGORIA` (VARCHAR2(80), NOT NULL): Nombre (ej. Lácteos, Abarrotes, Bebidas).
* `DESCRIPCION` (VARCHAR2(200)): Breve descripción del rubro.

### 4. `PRODUCTOS` (Catálogo de Artículos)
* `ID_PRODUCTO` (NUMBER, PK): Identificador único del producto.
* `ID_CATEGORIA` (NUMBER, FK -> CATEGORIAS.ID_CATEGORIA): Categoría asociada.
* `CODIGO_BARRA` (VARCHAR2(50), UNIQUE, NOT NULL): Código SKU.
* `NOMBRE_PRODUCTO` (VARCHAR2(120), NOT NULL): Nombre descriptivo.
* `PRECIO_VENTA` (NUMBER(10,2), NOT NULL): Precio unitario actual.
* `STOCK_ACTUAL` (NUMBER, NOT NULL): Cantidad física en bodega.
* `STOCK_MINIMO` (NUMBER, DEFAULT 5): Umbral de alerta para reposición.
* `ESTADO` (CHAR(1), DEFAULT 'A'): 'A' Disponible, 'I' Descontinuado.

### 5. `CLIENTES` (Personas o Empresas que Compran)
* `ID_CLIENTE` (NUMBER, PK): Identificador único del cliente.
* `RUT` (VARCHAR2(12), UNIQUE, NOT NULL): Identificación tributaria/nacional.
* `NOMBRES` (VARCHAR2(80), NOT NULL): Nombre del cliente.
* `APELLIDOS` (VARCHAR2(80), NOT NULL): Apellidos del cliente.
* `EMAIL` (VARCHAR2(100)): Correo de contacto.
* `TELEFONO` (VARCHAR2(20)): Número telefónico.
* `DIRECCION` (VARCHAR2(150)): Dirección física.

### 6. `VENTAS` (Cabecera de Transacción - Gestor de Ventas)
* `ID_VENTA` (NUMBER, PK): Identificador del folio de venta.
* `ID_CLIENTE` (NUMBER, FK -> CLIENTES.ID_CLIENTE): Cliente que realiza la compra.
* `ID_USUARIO` (NUMBER, FK -> USUARIOS.ID_USUARIO): Vendedor o usuario que procesó la venta.
* `NUMERO_FOLIO` (VARCHAR2(30), UNIQUE, NOT NULL): Folio fiscal/interno formateado.
* `FECHA_VENTA` (DATE, DEFAULT SYSDATE): Timestamp de la operación.
* `SUBTOTAL` (NUMBER(12,2), NOT NULL): Suma de subtotales de productos.
* `IVA` (NUMBER(12,2), NOT NULL): 19% calculado por función PL/SQL.
* `TOTAL` (NUMBER(12,2), NOT NULL): Monto final de la venta.
* `ESTADO` (VARCHAR2(20), DEFAULT 'PAGADA'): 'PAGADA', 'ANULADA', 'PENDIENTE'.

### 7. `DETALLE_VENTAS` (Desglose de Líneas de la Venta - Tabla N:M desagregada)
* `ID_DETALLE` (NUMBER, PK): Identificador de la línea.
* `ID_VENTA` (NUMBER, FK -> VENTAS.ID_VENTA): Venta asociada.
* `ID_PRODUCTO` (NUMBER, FK -> PRODUCTOS.ID_PRODUCTO): Producto adquirido.
* `CANTIDAD` (NUMBER, NOT NULL): Unidades vendidas.
* `PRECIO_UNITARIO` (NUMBER(10,2), NOT NULL): Precio de congelación histórica.
* `SUBTOTAL_LINEA` (NUMBER(12,2), NOT NULL): `CANTIDAD * PRECIO_UNITARIO`.

### 8. `AUDITORIA_STOCK` (Monitoreo automatizado con Triggers)
* `ID_AUDITORIA` (NUMBER, PK): Identificador único de auditoría.
* `ID_PRODUCTO` (NUMBER, FK -> PRODUCTOS.ID_PRODUCTO): Producto afectado.
* `STOCK_ANTERIOR` (NUMBER): Stock previo al cambio.
* `STOCK_NUEVO` (NUMBER): Stock resultante.
* `DIFERENCIA` (NUMBER): Variación (+/-).
* `OPERACION` (VARCHAR2(20)): 'VENTA', 'AJUSTE', 'INGRESO'.
* `USUARIO_MODIFICA` (VARCHAR2(50)): Usuario de BD o sesión de app.
* `FECHA_EVENTO` (DATE, DEFAULT SYSDATE): Momento exacto del registro.

---

## 3. Mapeo Directo con la Rúbrica

| Exigencia de la Rúbrica | Cómo se cumple en este esquema |
| :--- | :--- |
| **Control de Acceso (Perfiles)** | Tablas `ROLES` y `USUARIOS` con permisos diferenciados. |
| **Mantenedores CRUD (10 req.)** | Tablas maestras independientes listas para CRUD (`PRODUCTOS`, `CLIENTES`, `CATEGORIAS`, etc.). |
| **Gestores (5 req.)** | Proceso `sp_procesar_venta` que afecta simultáneamente `VENTAS`, `DETALLE_VENTAS`, descuenta `STOCK_ACTUAL` y genera boleta. |
| **Reportes (3 req.)** | Consultas agregadas (Top productos, Ventas mensuales por cliente, Reporte de rotación de stock). |
| **Triggers (Monitoreo)** | Trigger automático sobre `PRODUCTOS` que llena `AUDITORIA_STOCK` en cada actualización. |
| **Formato Impreso** | Este modelo está listo para diagramarse en Oracle SQL Developer Data Modeler y exportarse en alta resolución para entregar impreso. |
