# Correspondencia con la material INF314 / INF324 (RAR de la catedra)

**Proyecto:** Sistema LHAOMRJZ – Transporte Regional  
**Fuentes:** `PREGRADO_2026_001_900001_INF314_S2_...zip` y `PREGRADO_2026_002_900001_INF324_LAB2_...zip`.  
**Material extraida:** `INF314_Ejemplo_ej.sql`, `INF314_Ejemplo_ejercicios_SQL.pdf` y `INF324_Carrito_Compras/` (modelo 3FN, secuencias, funciones, procedimientos, triggers y semilla).

---

## 1. Regla de la material y aplicacion en LHAOMRJZ

| Regla del ejemplo de la catedra | Aplicacion en el proyecto LHAOMRJZ |
| :--- | :--- |
| Esquema en 3FN con PK, FK y UNIQUE (sin `CHECK` en el DDL) | 22 tablas, 22 PK, 27 FK y 9 UNIQUE en claves naturales (tras `PURGE RECYCLEBIN`). Los dominios se validan en 7 triggers nuevos y en los procedimientos, como en el ejemplo de la catedra. Justificacion en `docs/modelo_relacional/MODELO_3FN.md`. |
| Secuencias para generar PK | 14 secuencias `LHAOMRJZ_SEQ_*`; asignacion directa con `.NEXTVAL` en los `INSERT`. |
| Funciones encapsulan `SELECT INTO` y calculos | 38 funciones en total: `database/04_funciones/02_create_funciones.sql` centraliza 33 (validacion de RUT/telefono/patente, tarifas, existencia, region de comuna y valor de boleto); su drop esta en `04_funciones/01_drop_funciones.sql`. Las 5 funciones de seguridad quedan en `03_seguridad/02_create_seguridad.sql`. |
| Cero `SELECT INTO` dentro de procedimientos | Los 57 procedures standalone no contienen `SELECT ... INTO`; usan `LHAOMRJZ_FN_*`. La aplicacion no ejecuta SQL embebido: invoca `LHAOMRJZ_PS_LISTAR_DOMINIOS`, `LHAOMRJZ_PS_LISTAR_COMUNAS_CHILE`, `LHAOMRJZ_PS_LISTAR_PARADAS_BAJADA`, `LHAOMRJZ_PS_RESUMEN_DASHBOARD`, `LHAOMRJZ_PS_OBTENER_VALOR_BOLETO` y `LHAOMRJZ_PS_ROL_PERMITE`. |
| Iteracion simple, sin `WHILE` complejo | No hay `WHILE` en PL/SQL. Los recorridos estan en PHP o en `FOR` acotados de la semilla/normalizacion. |
| Toda visualizacion por cursores | Los 6 reportes, los listados de mantenedores y los listados de apoyo entregan `SYS_REFCURSOR`; los cursores internos usan prefijo `cur_` y registro `v_registro_cursor`. |
| `COMMIT` / `ROLLBACK` y excepciones explicitas | 57/57 procedures standalone con control transaccional y manejo de excepciones. `LHAOMRJZ_PKG_AUDITORIA.REGISTRAR` no hace `COMMIT` porque se ejecuta dentro de triggers; la semilla hace `ROLLBACK` en su excepcion y `COMMIT` al final. |
| Triggers de dominio, monitoreo y auditoria | 51 triggers en un solo `database/08_triggers/02_create_triggers.sql`: 44 anteriores más 7 de dominio. `LHAOMRJZ_PKG_AUDITORIA.REGISTRAR` alimenta `LHAOMRJZ_AUDITORIA` sin `COMMIT` interno. |
| 10 mantenedores, 5 gestores, 3 reportes | 14 procedimientos de mantenedores/listados, 11 gestores/listados y 6 reportes (supera el minimo). |
| Orden del guion de instalacion | `00_instalacion_completa.sql`: drops de triggers, reportes, gestores, mantenedores, funciones, seguridad, tablas y secuencias → tablas → catalogo → secuencias → seguridad → funciones → procedimientos → triggers → semilla → `PURGE RECYCLEBIN`. |

---

## 2. Archivo de funciones nuevo

`database/04_funciones/02_create_funciones.sql` reune, sin duplicarlos:

- Funciones que antes estaban mezcladas en los triggers (`LHAOMRJZ_FN_NORMALIZAR_TEXTO`, `LHAOMRJZ_FN_NORMALIZAR_RUT`, `LHAOMRJZ_FN_VALIDAR_RUT_CL`, `LHAOMRJZ_FN_VALIDAR_TEL_CL`, `LHAOMRJZ_FN_NORMALIZAR_PATENTE`).
- Funciones de tarifa que antes estaban dentro del gestor de ventas (`LHAOMRJZ_FN_CALCULAR_TARIFA_BUS`, `LHAOMRJZ_FN_CALCULAR_TARIFA`).
- Funciones de existencia y obtencion de datos usadas por los procedimientos (`LHAOMRJZ_FN_EXISTE_*`, `LHAOMRJZ_FN_CONTAR_*`, `LHAOMRJZ_FN_OBTENER_*`, `LHAOMRJZ_FN_BUS_ASIGNADO`, `LHAOMRJZ_FN_ASIENTO_OCUPADO`, `LHAOMRJZ_FN_BAJADA_PERMITIDA`).

---

## 3. Verificacion

- `SELECT COUNT(*) FROM USER_OBJECTS WHERE OBJECT_TYPE='FUNCTION' AND STATUS='INVALID'` → 0.
- `SELECT COUNT(*) FROM USER_OBJECTS WHERE OBJECT_TYPE='PROCEDURE' AND STATUS='INVALID'` → 0.
- Busqueda de `SELECT ... INTO` en `03_seguridad/`, `04_funciones/`, `05_mantenedores/`, `06_gestores/` y `07_reportes/` → 0 coincidencias en procedimientos standalone; solo aparece en funciones y validaciones de trigger.
- Busqueda de `WHILE` en `database/` → 0 coincidencias.
- Conteo tras instalacion y `PURGE RECYCLEBIN`: 22 tablas, 22 PK, 27 FK, 9 UNIQUE, 57 procedures, 38 funciones, 51 triggers y 14 secuencias; 0 objetos invalidos.
- Busqueda de `CK_` y `CHECK (` en el DDL → 0 coincidencias.
- Instalador completo ejecutado desde cero sin `ORA-`, `PLS-` ni `SP2-`.

> Nota: los triggers de negocio conservan consultas de lectura para validaciones contextuales de `:NEW`/`:OLD`; la regla de "cero SELECT" de la material se aplica estrictamente a los procedimientos almacenados, que es donde la catedra la exige.
