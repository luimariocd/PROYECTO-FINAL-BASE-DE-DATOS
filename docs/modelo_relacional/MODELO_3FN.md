# Modelo relacional en 3ª Forma Normal (3FN)

**Proyecto:** Proyecto Final de Base de Datos: "Sistema de Gestión Integral de Transporte Público Regional"  
**Curso:** INF324 – Base de Datos · Ingeniería Civil Informática · UCM  
**Esquema Oracle:** `LEHZ`  
**Fuentes de verdad:** `database/01_tablas/02_create_tables.sql` y `database/03_seguridad/02_create_seguridad.sql`  
**Fecha:** 27 de noviembre de 2026

> Documento de defensa e impresión. Todos los nombres de tablas, columnas, claves y restricciones corresponden al DDL ejecutado en Oracle. El modelo gráfico se entrega además en `modelo_relacional.html` / `modelo_relacional.png`. La correspondencia con el ejemplo 3FN de la catedra (RAR INF324) esta detallada en `docs/material_referencia/CORRESPONDENCIA_MATERIAL.md`.

---

## 1. Criterio de normalidad aplicado

El esquema se diseñó directamente con dependencias funcionales explícitas:

- **1FN:** cada celda contiene un solo valor atómico; no hay grupos repetitivos ni listas en columnas. Las relaciones multivaluadas se resolvieron en tablas propias.
- **2FN:** está en 1FN y todo atributo no clave depende de la **clave primaria completa**, no de una parte de una clave compuesta.
- **3FN:** está en 2FN y **ningún atributo no clave depende de otro atributo no clave**. Los datos descriptivos se almacenan una sola vez, en la tabla cuya clave los identifica. Los cálculos (recaudación, ocupación, promedios) no se almacenan: se obtienen en los reportes con `SYS_REFCURSOR`.

Las claves foráneas y los dominios validados por triggers no son "atributos descriptivos copiados": son referencias y reglas de negocio que Oracle aplica en la capa PL/SQL. Por eso no introducen dependencias transitivas entre atributos no clave.

---

## 2. Inventario de las 22 tablas (PK y FK principales)

### 2.1 Geografía, empresas y terminales (5 tablas)

| # | Tabla | Clave primaria (PK) | Foreign keys principales (FK) | Observaciones de diseño |
|---:|---|---|---|---|
| 1 | `LEHZ_REGION` | `ID_REGION` | — | `NOMBRE_REGION` depende solo de `ID_REGION`. |
| 2 | `LEHZ_COMUNA` | `ID_COMUNA` | `ID_REGION` → `LEHZ_REGION.ID_REGION` | `FK_COMUNA_REGION`. La región se referencia por clave, no se copia su nombre. |
| 3 | `LEHZ_TERMINAL` | `ID_TERMINAL` | `ID_COMUNA` → `LEHZ_COMUNA.ID_COMUNA` | `FK_TERMINAL_COMUNA` (agregado con `ALTER TABLE`). |
| 4 | `LEHZ_EMPRESA` | `RUT_EMPRESA` | — | `RAZON_SOCIAL`, teléfono y correo dependen del RUT. `CK_EMPRESA_RUT`, `CK_EMPRESA_TEL`. |
| 5 | `LEHZ_UTILIZAN` | `(ID_TERMINAL, RUT_EMPRESA)` | `ID_TERMINAL` → `LEHZ_TERMINAL`; `RUT_EMPRESA` → `LEHZ_EMPRESA` | **Tabla intermedia N:M** terminal ↔ empresa. Sin atributos no clave. |

### 2.2 Rutas, horarios y paradas (4 tablas)

| # | Tabla | Clave primaria (PK) | Foreign keys principales (FK) | Observaciones de diseño |
|---:|---|---|---|---|
| 6 | `LEHZ_HORARIO` | `ID_HORARIO` | — | `HORA_SALIDA` / `HORA_LLEGADA` dependen de `ID_HORARIO`; es un horario reutilizable. |
| 7 | `LEHZ_RUTA` | `ID_RUTA` | `ID_TERMINAL_ORIGEN` → `LEHZ_TERMINAL`; `ID_TERMINAL_DESTINO` → `LEHZ_TERMINAL` | `CK_RUTA_ORIG_DEST` impide origen = destino; `NOMBRE_RUTA`, distancia y duración dependen de `ID_RUTA`. |
| 8 | `LEHZ_RUTA_PARADA` | `ID_RUTA_PARADA` | `ID_RUTA` → `LEHZ_RUTA` (`ON DELETE CASCADE`); `ID_TERMINAL` → `LEHZ_TERMINAL` | **Tabla intermedia N:M** ruta ↔ terminal con atributos propios de la pertenencia. |
| 9 | `LEHZ_VIAJE` | `ID_VIAJE` | `ID_HORARIO` → `LEHZ_HORARIO`; `ID_RUTA` → `LEHZ_RUTA` | `UQ_VIAJE_FECHA_HORARIO_RUTA` evita duplicar un viaje. Un viaje es una ocurrencia concreta de ruta + horario + fecha. |

> `LEHZ_RUTA.HORARIO` es la hora de referencia declarada de la ruta; `LEHZ_HORARIO` es el horario reutilizable que se asocia al viaje. No se copian columnas descriptivas de una tabla a otra: la salida concreta se resuelve por FK en `LEHZ_VIAJE`.

### 2.3 Flota, personal y mantenciones (5 tablas)

| # | Tabla | Clave primaria (PK) | Foreign keys principales (FK) | Observaciones de diseño |
|---:|---|---|---|---|
| 10 | `LEHZ_BUS` | `PATENTE_BUS` | `RUT_EMPRESA` → `LEHZ_EMPRESA` | `MARCA`, `MODELO`, `CAPACIDAD`, `TARIFA_BASE` dependen de la patente. `CK_BUS_PATENTE`. |
| 11 | `LEHZ_ASIENTO` | `(NUMERO_ASIENTO, PATENTE_BUS)` | `PATENTE_BUS` → `LEHZ_BUS.PATENTE_BUS` (`FK_ASIENTO_BUS`); el boleto referencia la PK compuesta `(NUMERO_ASIENTO, PATENTE_BUS)` | `PISO` y `UBICACION` dependen de la **pareja** número + bus; no del número aislado. |
| 12 | `LEHZ_CONDUCTOR` | `RUT_CONDUCTOR` | `RUT_EMPRESA` → `LEHZ_EMPRESA` | Licencia y vigencia dependen del conductor; `CK_CONDUCTOR_LICENCIA`. |
| 13 | `LEHZ_MECANICO` | `RUT_MECANICO` | `RUT_EMPRESA` → `LEHZ_EMPRESA` | `ESPECIALIDAD` depende del mecánico. |
| 14 | `LEHZ_MANTENCION` | `ID_MANTENCION` | `RUT_MECANICO` → `LEHZ_MECANICO`; `PATENTE_BUS` → `LEHZ_BUS` | `FECHA_MANTENCION`, descripción y costo dependen del evento de mantención. |

> Notación de la fila 11: la PK es compuesta `(NUMERO_ASIENTO, PATENTE_BUS)` y la FK a flota es `PATENTE_BUS`; el boleto referencia la **PK compuesta completa** del asiento, por eso no puede existir un asiento "número 5" sin identificar el bus.

### 2.4 Operación comercial (6 tablas)

| # | Tabla | Clave primaria (PK) | Foreign keys principales (FK) | Observaciones de diseño |
|---:|---|---|---|---|
| 15 | `LEHZ_PASAJERO` | `RUT_PASAJERO` | — | Nombre, apellidos, teléfono y correo dependen solo del RUT; no se repiten en boleto ni pago. |
| 16 | `LEHZ_CONDUCE` | `(RUT_CONDUCTOR, PATENTE_BUS, ID_VIAJE)` | `RUT_CONDUCTOR` → `LEHZ_CONDUCTOR`; `PATENTE_BUS` → `LEHZ_BUS`; `ID_VIAJE` → `LEHZ_VIAJE` | **Tabla intermedia N:M** (ternaria) conductor ↔ bus ↔ viaje. No tiene atributos no clave. |
| 17 | `LEHZ_BOLETO` | `ID_BOLETO` | `RUT_PASAJERO` → `LEHZ_PASAJERO`; `ID_VIAJE` → `LEHZ_VIAJE`; `(NUMERO_ASIENTO, PATENTE_BUS)` → `LEHZ_ASIENTO` | `VALOR_BOLETO`, `ESTADO`, fecha de emisión y anulación dependen del boleto. `UQ_LEHZ_BOLETO_ASIENTO_ACTIVO` impide doble venta activa del asiento. |
| 18 | `LEHZ_PAGO` | `ID_PAGO` | `ID_BOLETO` → `LEHZ_BOLETO` (`UQ_PAGO_BOLETO`, 1:1); `RUT_PASAJERO` → `LEHZ_PASAJERO` | `MONTO_PAGO` y `METODO_PAGO` dependen del pago. `RUT_PASAJERO` es FK de control, no datos del pasajero. |
| 19 | `LEHZ_PASAJE_BAJADA` | `ID_BAJADA` | `ID_BOLETO` → `LEHZ_BOLETO` (`UQ_LEHZ_BAJADA_BOLETO`, 1:1, `ON DELETE CASCADE`); `ID_TERMINAL_BAJADA` → `LEHZ_TERMINAL` | `OBSERVACION` y `FECHA_REGISTRO` dependen de la bajada. |
| 20 | `LEHZ_AUDITORIA` | `ID_AUDITORIA` | — | Bitácora desacoplada: `TABLA_AFECTADA`, `OPERACION`, `USUARIO_BD` (DEFAULT `USER`) y `FECHA_EVENTO` (DEFAULT `SYSTIMESTAMP`). No apunta a las tablas auditadas para conservar el histórico aunque se eliminen registros. |

### 2.5 Seguridad (2 tablas)

| # | Tabla | Clave primaria (PK) | Foreign keys principales (FK) | Observaciones de diseño |
|---:|---|---|---|---|
| 21 | `LEHZ_ROL` | `ID_ROL` | — | `UQ_LEHZ_NOMBRE_ROL`; descripción depende del rol. |
| 22 | `LEHZ_USUARIO` | `ID_USUARIO` | `ID_ROL` → `LEHZ_ROL` | `USERNAME` es clave candidata (`UQ_LEHZ_USERNAME`); hash, estado y fecha dependen del usuario. |

**Total: 19 tablas en `02_create_tables.sql` + 3 tablas en `02_create_seguridad.sql` = 22 tablas.**

---

## 3. Tablas intermedias N:M (justificación defendible)

| Tabla intermedia | Relación resuelta | Clave primaria | Por qué es una tabla intermedia y no una columna repetida |
|---|---|---|---|
| `LEHZ_CONDUCE` | Conductor ↔ Viaje, con bus participante | `(RUT_CONDUCTOR, PATENTE_BUS, ID_VIAJE)` | Un conductor puede conducir muchos viajes y un viaje puede tener varios conductores/buses. La clave compuesta impide asignar dos veces la misma ternaria. No hay atributos no clave: es dependencia 2FN/3FN trivial. |
| `LEHZ_UTILIZAN` | Empresa ↔ Terminal | `(ID_TERMINAL, RUT_EMPRESA)` | Varias empresas operan en un terminal y una empresa usa varios terminales. No se puede almacenar una "lista de terminales" en `LEHZ_EMPRESA` (violaría 1FN). |
| `LEHZ_RUTA_PARADA` | Ruta ↔ Terminal (paradas) | `ID_RUTA_PARADA` (más claves candidatas `UQ_LEHZ_RUTA_ORDEN` y `UQ_LEHZ_RUTA_TERMINAL`) | Una ruta tiene muchas paradas y una terminal pertenece a muchas rutas. `ORDEN_PARADA`, `MINUTOS_DESDE_ORIG` y `PERMITE_BAJADA` son propiedades de **la pertenencia**, no de la ruta ni de la terminal: por eso están en la intermedia y no se copian en `LEHZ_RUTA`. |

`LEHZ_PASAJE_BAJADA` y `LEHZ_PAGO` **no** son N:M: tienen `UNIQUE` sobre `ID_BOLETO`, por lo que son relaciones 1:1 (un boleto tiene a lo más un pago y una bajada).

---

## 4. Análisis 1FN → 2FN → 3FN sobre el modelo real

### 4.1 Primera Forma Normal (1FN)

- **Atomicidad:** `NOMBRE`, `APELLIDO1`, `APELLIDO2`, `TELEFONO`, `CORREO_ELECTRONICO_*` están separados; `FECHA_EMISION_BOLETO` y `HORA_EMISION_BOLETO` son columnas distintas con dominios `DATE` / `TIMESTAMP`.
- **Sin grupos repetitivos:** no existen columnas `PARADA1`, `PARADA2`, `ASIENTO1`… Las paradas viven en `LEHZ_RUTA_PARADA`; los asientos en `LEHZ_ASIENTO`; los boletos en `LEHZ_BOLETO`.
- **Dominios controlados por la capa de servicios:** `LEHZ_TRG_DOM_BUS`, `LEHZ_TRG_ASIENTO_VALIDA`, `LEHZ_TRG_DOM_BOLETO`, `LEHZ_TRG_DOM_PAGO`, `LEHZ_TRG_DOM_RUTA_PARADA` y `LEHZ_TRG_DOM_USUARIO`; RUT, teléfono y patente se validan en `LEHZ_FN_*` desde los triggers de normalización. Un dominio enumerado se controla en PL/SQL, no queda como texto libre repetido.
- **Claves atómicas:** las PK compuestas están formadas por columnas simples (por ejemplo `(NUMERO_ASIENTO, PATENTE_BUS)`).

### 4.2 Segunda Forma Normal (2FN)

La única fuente de riesgo son las tablas con PK compuesta:

| Tabla | Dependencia de la clave completa | Verificación |
|---|---|---|
| `LEHZ_ASIENTO` | `PISO`, `UBICACION` → `(NUMERO_ASIENTO, PATENTE_BUS)` | El asiento 5 del bus A puede ser ventana y el asiento 5 del bus B pasillo; `NUMERO_ASIENTO` solo **no** determina `UBICACION`. |
| `LEHZ_CONDUCE` | Sin atributos no clave | Tabla pura de intersección: 2FN se satisface por vacuidad. |
| `LEHZ_UTILIZAN` | Sin atributos no clave | Idem. |
| `LEHZ_RUTA_PARADA` | `ORDEN_PARADA`, `MINUTOS_DESDE_ORIG`, `PERMITE_BAJADA` → `ID_RUTA_PARADA` (y son funcionalmente dependientes de la clave candidata `(ID_RUTA, ID_TERMINAL)`) | Conocer solo `ID_RUTA` no permite saber el orden; conocer solo `ID_TERMINAL` no permite saber los minutos desde el origen. |

En el resto de las tablas la PK es simple, por lo que no existen dependencias parciales posibles: `RAZON_SOCIAL` depende de `RUT_EMPRESA`, `CAPACIDAD` de `PATENTE_BUS`, `VALOR_BOLETO` de `ID_BOLETO`, `MONTO_PAGO` de `ID_PAGO`, `NOMBRE_ROL` de `ID_ROL`.

### 4.3 Tercera Forma Normal (3FN): por qué no hay atributos dependientes de atributos no clave

1. **La descripción vive con su clave.** `NOMBRE_REGION` está solo en `LEHZ_REGION`; `NOMBRE_COMUNA` solo en `LEHZ_COMUNA`; `RAZON_SOCIAL` solo en `LEHZ_EMPRESA`; `NOMBRE_RUTA` solo en `LEHZ_RUTA`; `MARCA`/`MODELO` solo en `LEHZ_BUS`; nombres y apellidos solo en `LEHZ_PASAJERO`, `LEHZ_CONDUCTOR` y `LEHZ_MECANICO`. Las demás tablas guardan únicamente la FK. Si un nombre cambia, se actualiza **una** fila y no se produce anomalía de actualización.
2. **Los atributos derivados no se almacenan.** No hay columnas `TOTAL_RECAUDADO`, `ASIENTOS_DISPONIBLES` ni `PROMEDIO_COSTO`. Esos valores se calculan en `LEHZ_PS_REP_RECAUDACION_VIAJES`, `LEHZ_PS_REP_OCUPACION_ASIENTOS` y `LEHZ_PS_REP_COSTOS_MANTENCION`, y se entregan por `SYS_REFCURSOR`. Por tanto no existe `ID_PAGO → MONTO_PAGO → TOTAL` ni cadena transitiva equivalente.
3. **Los estados y tipos son dominios, no entidades repetidas.** `ESTADO`, `TIPO_SERVICIO`, `METODO_PAGO`, `UBICACION` y `PERMITE_BAJADA` se validan en procedures/triggers de la capa de servicios, siguiendo el ejemplo de la catedra (PK/FK/UNIQUE en el DDL y validaciones en PL/SQL). Si mañana se requiere una descripción literal para cada código, se crearía una tabla catálogo con PK = código; nunca se copiaría la descripción dentro de cada boleto o bus.
4. **La tarifa no se duplica como dato maestro.** `TARIFA_BASE` pertenece al bus (atributo del bus). `VALOR_BOLETO` es un hecho de la transacción, calculado por `LEHZ_FN_CALCULAR_TARIFA_BUS` al vender y persistido en el boleto por necesidades de auditoría comercial. No es una copia de un atributo ajeno: es el valor acordado en ese boleto.
5. **Caso límite declarado: `LEHZ_PAGO.RUT_PASAJERO`.** Es una FK redundante respecto de `LEHZ_BOLETO.RUT_PASAJERO`, pero no transporta atributos del pasajero (ni nombre, ni teléfono, ni correo). Como `ID_BOLETO` tiene `UQ_PAGO_BOLETO`, `ID_PAGO` y `ID_BOLETO` son **claves candidatas**: la relación es de clave a clave, no de un atributo no clave a otro atributo no clave. Su función es permitir validar el pago contra el titular del boleto en la capa PL/SQL sin copiar datos descriptivos. No genera dependencia transitiva prohibida por 3FN.
6. **Caso límite declarado: `LEHZ_AUDITORIA`.** Guarda `TABLA_AFECTADA` y `ID_REGISTRO` como texto, no como FK, precisamente para que la bitácora sobreviva a borrados y para no incorporar dependencias funcionales hacia tablas que cambian. Es un registro de eventos, no una entidad de negocio normalizada por FK.
7. **Índices parciales y `UNIQUE` no son atributos.** `UQ_LEHZ_BOLETO_ASIENTO_ACTIVO` usa expresiones `CASE` para garantizar que solo un boleto `EMITIDO`/`USADO` ocupe un asiento por viaje; es una restricción de integridad, no una columna calculada almacenada.

**Conclusión formal:** para toda tabla `R`, cada determinante funcional relevante es una clave candidata de `R` (PK o `UNIQUE`). No existe `A → B` donde `A` y `B` sean atributos no clave. El esquema cumple 3FN y, por construcción, también 1FN y 2FN.

---

## 5. Guion breve para la defensa (90 segundos)

> "El esquema `LEHZ` tiene 22 tablas: 19 del modelo funcional y 3 de seguridad. Todas tienen PK declarada: simples como `ID_REGION`, compuestas como `(NUMERO_ASIENTO, PATENTE_BUS)` y ternarias como `(RUT_CONDUCTOR, PATENTE_BUS, ID_VIAJE)`. Las FK respetan los tipos y las relaciones 1:N; los N:M se resolvieron en `LEHZ_CONDUCE`, `LEHZ_UTILIZAN` y `LEHZ_RUTA_PARADA`. En 1FN no hay listas ni grupos repetitivos: paradas, asientos y boletos son filas. En 2FN, los atributos de las claves compuestas dependen de la clave completa: el piso y la ubicación de un asiento dependen de número **y** bus; el orden de una parada depende de ruta **y** terminal. En 3FN, los nombres y descripciones se guardan una sola vez en su tabla madre y los datos derivados —recaudación, ocupación, costos— no se almacenan: se calculan en procedimientos con `SYS_REFCURSOR`. La única FK aparentemente redundante es `RUT_PASAJERO` en `LEHZ_PAGO`, pero `ID_BOLETO` es única, así que es clave-candidata a clave-candidata, sin copiar atributos descriptivos. Por eso el modelo alcanza 3FN sin perder trazabilidad."

---

## 6. Impresión

Este documento y `modelo_relacional.html` están preparados para imprimir en A4, blanco y negro, con el diagrama `modelo_relacional.png` incrustado en la versión HTML. Entréguese impreso al inicio de la presentación, según la pauta.
