# Traza requerimiento → PA/tabla/vista → archivo PHP → minuto del video

**31 ítems técnicos de la pauta de cotejo (Pauta, páginas 7–9), agrupados por dominio.**  
**Minutos:** referencia al video de `GUION_VIDEO.md` (B1 0:00–1:30, B2 1:30–3:10, B3 3:10–5:20, B4 5:20–9:00, B5 9:00–11:10, B6 11:10–13:20). `—` = evidencia estática en el código/sql, no requiere apostila en pantalla; se menciona en la defensa.

## A. Modelo de datos y script (ítems 1–6)

| # | Requerimiento (pauta) | PA / tabla / vista | Archivo PHP | Minuto |
|---:|---|---|---|---|
| 1 | PK coherentes e identificables en todas las tablas | `PK_LHAOMRJZ_*` en las 22 tablas (incl. compuestas `LHAOMRJZ_ASIENTO`, `LHAOMRJZ_CONDUCE`, `LHAOMRJZ_UTILIZAN`) | `app/config/modules.php` (envía las PK en cada IUD) | B2 2:00 — ver paradas y su ID |
| 2 | FK respetando tipos y reglas 1:N | `FK_COMUNA_REGION`, `FK_TERMINAL_COMUNA`, `FK_BUS_EMPRESA`, `FK_VIAJE_RUTA`, `FK_BOLETO_*`, `FK_USUARIO_ROL` | `app/config/modules.php` (combos vía `LHAOMRJZ_PS_LISTAR_*`) | B2 1:50; B4 5:40 |
| 3 | Relaciones N:M con tablas intermedias | `LHAOMRJZ_CONDUCE`, `LHAOMRJZ_UTILIZAN`, `LHAOMRJZ_RUTA_PARADA`; PA `LHAOMRJZ_PS_GES_ASIGNAR_CONDUCE`, `LHAOMRJZ_PS_GES_ASOCIAR_TERMINAL`, `LHAOMRJZ_PS_IUD_RUTA_PARADA` | `app/views/conduce.php`, `app/views/utilizan.php`, `app/views/maintainer.php` | B2 2:10; B3 4:30 |
| 4 | Esquema ≥ 3FN justificado | `docs/modelo_relacional/MODELO_3FN.md` + `modelo_relacional.png`; 22 tablas sin atributos derivados | Sin archivo PHP (entrega impresa); se muestra en B2 | B2 1:30–2:00 |
| 5 | Script .sql limpio y secuencial en Oracle | `database/00_instalacion_completa.sql`, `01_tablas/02_create_tables.sql`, `03_seguridad/02_create_seguridad.sql`, `04_funciones/02_create_funciones.sql` | `app/config/database.php` (OCI8 contra el esquema desplegado) | — (defensa técnica) |
| 6 | Poblamiento con datos reales/coherentes | `database/09_datos_prueba/01_seed_datos.sql`: terminales Talca/Cúrico/Santiago, buses `BCDF12`, `XY9876`, `HJKL34`, conductores y boletos | `app/views/dashboard.php`, `app/views/venta.php` | B1 1:10; B4 5:30 |

## B. Objetos de base de datos (ítems 7–17)

| # | Requerimiento (pauta) | PA / tabla / vista | Archivo PHP | Minuto |
|---:|---|---|---|---|
| 7 | PA: cantidad, estructura modular, IN/OUT y variables locales | `LHAOMRJZ_PS_IUD_*` (12 mantenedores), `LHAOMRJZ_PS_GES_*` (5 gestores + bajadas), `LHAOMRJZ_PS_REP_*`; `p_id_*_out` | `app/config/modules.php` (`handle_maintainer`), `app/public/index.php` (`db_call`) | B3 3:40; B4 6:10 |
| 8 | Control transaccional COMMIT / ROLLBACK | Todos los `LHAOMRJZ_PS_IUD_*` y `LHAOMRJZ_PS_GES_*` | `app/public/index.php` (catch → `db_error_message`) | B4 6:20; B5 10:00 |
| 9 | Excepciones controladas con mensajes descriptivos | `RAISE_APPLICATION_ERROR` en `LHAOMRJZ_PS_GES_VENDER_BOLETO`, `LHAOMRJZ_PS_LOGIN`, `LHAOMRJZ_PS_GES_PROGRAMAR_VIAJE` | `app/config/helpers.php` (`db_error_message`), `app/views/layout.php` (flash) | B5 10:20 |
| 10 | Funciones PL/SQL con prefijo estándar | `LHAOMRJZ_FN_CALCULAR_TARIFA_BUS`, `LHAOMRJZ_FN_CALCULAR_TARIFA`, `LHAOMRJZ_FN_VALIDAR_PASSWORD`, `LHAOMRJZ_FN_ROL_PERMITE`, `LHAOMRJZ_FN_NORMALIZAR_*` | `app/config/helpers.php` (`can_access`), `app/views/venta.php` | B1 0:50; B4 6:30 |
| 11 | Uso transversal de funciones | `LHAOMRJZ_FN_CALCULAR_TARIFA_BUS` dentro de `LHAOMRJZ_PS_GES_VENDER_BOLETO`; `LHAOMRJZ_FN_ROL_PERMITE` en `LHAOMRJZ_VW_MENU_ROL`/PHP | `app/views/venta.php`, `app/config/helpers.php` | B1 1:00; B4 6:30 |
| 12 | Secuencias creadas y aplicadas | `LHAOMRJZ_SEQ_REGION`, `LHAOMRJZ_SEQ_VIAJE`, `LHAOMRJZ_SEQ_BOLETO`, `LHAOMRJZ_SEQ_PAGO`, `LHAOMRJZ_SEQ_USUARIO`, `LHAOMRJZ_SEQ_*` (22) | `app/config/modules.php` (ids `auto`), `app/public/index.php` | B3 3:50; B4 6:15 |
| 13 | Cursores explícitos/implícitos con FETCH y cierre | `SYS_REFCURSOR` en `LHAOMRJZ_PS_LISTAR_*` y `LHAOMRJZ_PS_REP_*`; `OPEN … FOR` en paquetes | `app/config/database.php` (`db_rows`: bind `OCI_B_CURSOR`, `oci_fetch_assoc`) | B2 2:20; B6 11:40 |
| 14 | Triggers BEFORE/AFTER con `:NEW` / `:OLD` | `LHAOMRJZ_TRG_BOLETO_VALIDA`, `LHAOMRJZ_TRG_ASIENTO_VALIDA`, `LHAOMRJZ_TRG_CONDUCTOR_LICENCIA`, `LHAOMRJZ_TRG_VIAJE_FECHA`, `LHAOMRJZ_TRG_RUTA_PARADA_VALIDA`, `LHAOMRJZ_TRG_HORARIO_VALIDA` | Sin llamada directa: se disparan desde `index.php` → PA | B3 4:50; B5 10:10 |
| 15 | Auditoría y reglas de integridad desde la BD | `LHAOMRJZ_TRG_AUD_*` → `LHAOMRJZ_AUDITORIA`, `LHAOMRJZ_PKG_AUDITORIA`, `UQ_LHAOMRJZ_BOLETO_ASIENTO_ACTIVO`, `CK_*` | `app/public/index.php` (errores), `app/views/layout.php` | B5 10:20 |
| 16 | Arquitectura cliente-servidor en dos capas (lógica pesada en Oracle) | Capa BD: `LHAOMRJZ_PS_*`, `LHAOMRJZ_FN_*`, `LHAOMRJZ_PKG_*`, `LHAOMRJZ_TRG_*`; capa cliente: PHP 8 + OCI8 | `app/config/database.php`, `app/public/index.php` | B1 0:30; B4 5:50 |
| 17 | Desacoplamiento cliente-servidor | El cliente solo invoca PA y renderiza cursores; sin reglas de negocio en PHP | `app/config/modules.php`, `app/views/*.php`, `app/config/database.php` | B4 6:40 |

## C. Aplicación web (ítems 18–31)

| # | Requerimiento (pauta) | PA / tabla / vista | Archivo PHP | Minuto |
|---:|---|---|---|---|
| 18 | Autenticación usuario/contraseña contra BD | `LHAOMRJZ_PS_LOGIN`, `LHAOMRJZ_USUARIO.PASSWORD_HASH` (SHA-256) | `app/auth/auth.php`, `app/views/login.php`, `app/public/index.php` (action `login`) | B1 0:10–1:00 |
| 19 | Control de acceso por roles (≥2 perfiles) | `LHAOMRJZ_ROL`, `LHAOMRJZ_VW_MENU_ROL`, `LHAOMRJZ_FN_ROL_PERMITE`, `LHAOMRJZ_PS_LISTAR_MENU` | `app/config/helpers.php` (`can_access`), `app/views/layout.php`, `app/views/dashboard.php` | B1 1:05–1:30 |
| 20 | Mantenedores 1–3 invocan PA | `LHAOMRJZ_PS_IUD_REGION`, `LHAOMRJZ_PS_IUD_COMUNA`, `LHAOMRJZ_PS_IUD_TERMINAL` + `LHAOMRJZ_PS_LISTAR_*` | `app/config/modules.php`, `app/views/maintainer.php` | B2 1:35 (Rutas/Paradas, mismo patrón) |
| 21 | Mantenedores 4–7 invocan PA | `LHAOMRJZ_PS_IUD_EMPRESA`, `_BUS`, `_ASIENTO`, `_CONDUCTOR` | `app/config/modules.php`, `app/views/maintainer.php` | B3 4:40 (bus/conductor visibles) |
| 22 | Mantenedores 8–10 invocan PA | `LHAOMRJZ_PS_IUD_MECANICO`, `_RUTA`, `_HORARIO`; extensiones `_RUTA_PARADA`, `_PASAJERO` | `app/config/modules.php`, `app/views/maintainer.php` | B2 2:00; B4 5:30 (pasajero) |
| 23 | Gestores 1–3 generan información nueva | `LHAOMRJZ_PS_GES_VENDER_BOLETO` (+ `LHAOMRJZ_PS_GES_ANULAR_BOLETO`, `LHAOMRJZ_PS_GES_MARCAR_BOLETO_USADO`), `LHAOMRJZ_PS_GES_PROGRAMAR_VIAJE`, `LHAOMRJZ_PS_GES_ASIGNAR_CONDUCE` | `app/public/index.php` (`sale`, `annul`, `use`, `viaje`, `conduce`), `app/views/venta.php`, `app/views/viaje.php`, `app/views/conduce.php` | B3 3:20–5:10; B4 5:30–8:30 |
| 24 | Gestores 4–5 generan información nueva | `LHAOMRJZ_PS_GES_REGISTRAR_MANTENCION`, `LHAOMRJZ_PS_GES_ASOCIAR_TERMINAL`; extensión `LHAOMRJZ_PS_GES_REGISTRAR_BAJADA` | `app/views/mantencion.php`, `app/views/utilizan.php`, `app/views/bajada.php`, `app/public/index.php` | B4 8:20–9:00 |
| 25 | Reportes estratégicos 1–3 con PA y cursores | `LHAOMRJZ_PS_REP_RECAUDACION_VIAJES`, `LHAOMRJZ_PS_REP_COSTOS_MANTENCION`, `LHAOMRJZ_PS_REP_OCUPACION_ASIENTOS`; operativo `LHAOMRJZ_PS_REP_ITINERARIO_PARADAS` | `app/config/modules.php` (`reports`), `app/views/report.php` | B6 11:20–13:20 |
| 26 | Validación de formularios (tipos, obligatorios, formatos) | `LHAOMRJZ_FN_VALIDAR_PASSWORD`, `LHAOMRJZ_FN_VALIDAR_RUT_CL`, `LHAOMRJZ_FN_VALIDAR_TEL_CL`, `CK_*` en BD; validación previa en PHP | `app/config/helpers.php` (`validate_post`, `valid_rut`, `valid_phone`, `action_validation_errors`), `app/views/maintainer.php` | B1 0:20 (clave); B4 5:40 (RUT) |
| 27 | Integridad referencial en interfaz (impide borrados inconsistentes) | FK + `ON DELETE CASCADE` + PA que validan antes de borrar; mensaje desde `RAISE_APPLICATION_ERROR` | `app/public/index.php` (`fail_and_go`), `app/views/maintainer.php`, `app/config/helpers.php` | B5 9:30–11:10 |
| 28 | Navegación y estructura visual coherente | `LHAOMRJZ_VW_MENU_ROL`, `LHAOMRJZ_PS_LISTAR_MENU` | `app/views/layout.php`, `app/views/dashboard.php`, `app/config/modules.php` | B1 1:10; B6 13:00 |
| 29 | Paginación / filtrado operativo de listados | `LHAOMRJZ_PS_LISTAR_*` (cursores ordenados); filtro en cliente con `filterSelect` / `filterParadas` | `app/public/assets/js/app.js`, `app/views/maintainer.php`, `app/views/report.php` | B2 2:30; B6 12:20 |
| 30 | Conexión segura y estable sin credenciales en vistas | OCI8 con parámetros enlazados (`db_call`, `db_rows`, `db_scalar`); credenciales en entorno Docker | `app/config/database.php`, `app/config/config.php`, `docker-compose.yml` | B1 0:40; B4 5:50 |
| 31 | Operación continua sin fallos con datos reales | Flujo completo: login → ruta → viaje → venta → bajada → rechazo → reporte; auditoría en `LHAOMRJZ_AUDITORIA` | `app/public/index.php`, `app/views/*.php` | B1–B6 (0:00–13:20) |

---

## Matriz resumida de los 6 bloques del video

| Bloque | Minuto | Entrada usuario | PA invocado | Tablas afectadas | Vista PHP |
|---:|---|---|---|---|---|
| 1 Login/perfil | 0:00–1:30 | `admin` / `Admin1234`; `vendedor1` / `Ventas1234` | `LHAOMRJZ_PS_LOGIN`, `LHAOMRJZ_PS_LISTAR_MENU` | `LHAOMRJZ_USUARIO`, `LHAOMRJZ_ROL` | `login.php`, `dashboard.php`, `layout.php` |
| 2 Ruta y paradas | 1:30–3:10 | Menú *Rutas* → *Paradas por ruta* | `LHAOMRJZ_PS_LISTAR_RUTAS`, `LHAOMRJZ_PS_LISTAR_RUTA_PARADAS` | `LHAOMRJZ_RUTA`, `LHAOMRJZ_TERMINAL`, `LHAOMRJZ_RUTA_PARADA` | `maintainer.php` |
| 3 Viaje y bus | 3:10–5:20 | Fecha + horario + ruta; conductor + bus | `LHAOMRJZ_PS_GES_PROGRAMAR_VIAJE`, `LHAOMRJZ_PS_GES_ASIGNAR_CONDUCE` | `LHAOMRJZ_VIAJE`, `LHAOMRJZ_CONDUCE`, `LHAOMRJZ_BUS` | `viaje.php`, `conduce.php` |
| 4 Venta y bajada | 5:20–9:00 | RUT `19111222-9`, asiento 6 `BCDF12`, `TARJETA`, terminal | `LHAOMRJZ_PS_GES_VENDER_BOLETO`, `LHAOMRJZ_FN_CALCULAR_TARIFA_BUS`, `LHAOMRJZ_PS_GES_REGISTRAR_BAJADA` | `LHAOMRJZ_BOLETO`, `LHAOMRJZ_PAGO`, `LHAOMRJZ_PASAJE_BAJADA`, `LHAOMRJZ_AUDITORIA` | `venta.php`, `bajada.php` |
| 5 Asiento ocupado | 9:00–11:10 | Asiento 1 ocupado en viaje precargado | `LHAOMRJZ_PS_GES_VENDER_BOLETO` (rollback), `LHAOMRJZ_TRG_BOLETO_VALIDA`, índice `UQ_LHAOMRJZ_BOLETO_ASIENTO_ACTIVO` | `LHAOMRJZ_BOLETO`, `LHAOMRJZ_AUDITORIA` | `venta.php`, `layout.php` (mensaje de error) |
| 6 Recaudación | 11:10–13:20 | Menú *Recaudación por viaje*; contraste con ocupación | `LHAOMRJZ_PS_REP_RECAUDACION_VIAJES`, `LHAOMRJZ_PS_REP_OCUPACION_ASIENTOS` | `LHAOMRJZ_BOLETO` (estado `EMITIDO`/`USADO`), `LHAOMRJZ_PAGO` | `report.php` |

**Cómo usar esta traza en la defensa:** al narrar cada bloque, indicar primero el archivo PHP que recibe el POST, luego el PA que ejecuta Oracle y finalmente la tabla que cambia o el cursor que se devuelve. El patrón único es `index.php → db_call()/db_rows() → LHAOMRJZ_PS_* → LHAOMRJZ_* → SYS_REFCURSOR → vista.php`.
