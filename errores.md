# Errores encontrados y estado

Proyecto: Sistema LEHZ – Transporte Regional  
Rama base: `Denunce`  
Esquema objetivo final: `LEHZ` (validacion previa en `LEHZTEST`, sin destruir datos de `LEHZ`)  
Fecha de cierre de pruebas: 26/11/2026

## Leyenda de estado
- **Corregido**: causa raiz corregida y verificada en Oracle/PHP.
- **Pendiente**: no bloquea la entrega, pero queda documentado para una iteracion futura.

---

## 1. Base de datos / Oracle

| # | Error encontrado | Causa raiz | Correccion aplicada | Estado |
|---|------------------|------------|---------------------|--------|
| 1 | RUT rechazado o mal normalizado cuando se ingresaba con puntos o sin DV. | `LEHZ_FN_NORMALIZAR_RUT` no aceptaba todos los formatos. | Se reescribio para aceptar RUT con/sin puntos y con/sin DV; devuelve `NNNNNNNN-DV`. | Corregido |
| 2 | Telefonos chilenos no aceptaban `+56`, `600` ni `809`. | Validacion hardcodeada y restrictiva. | `LEHZ_FN_VALIDAR_TEL_CL` normaliza y valida `+56[2-9]XXXXXXXX`, `600XXXXXX`, `809XXXXXX`; persona solo `+569XXXXXXXX`. | Corregido |
| 3 | Patentes con formato variable no se normalizaban. | Falta de normalizacion. | Se implemento `LEHZ_FN_NORMALIZAR_PATENTE`. | Corregido |
| 4 | Tarifa se recibia como precio arbitrario desde la interfaz. | `LEHZ_PS_GES_VENDER_BOLETO` aceptaba `p_valor_boleto`. | La firma ahora no recibe precio; calcula con `LEHZ_FN_CALCULAR_TARIFA_BUS`. | Corregido |
| 5 | Venta de asiento ocupado no se bloqueaba. | Falta de validacion en trigger/procedimiento. | `LEHZ_TRG_BOLETO_VALIDA` valida capacidad, bus asignado y asiento libre. | Corregido |
| 6 | Bajada en origen o en parada que no permite bajada era aceptada. | Falta de validacion. | `LEHZ_PS_GES_REGISTRAR_BAJADA` valida pertenencia al recorrido y `PERMITE_BAJADA`. | Corregido |
| 7 | Boletos ya usados podian marcarse de nuevo. | No se validaba estado previo. | `LEHZ_PS_GES_MARCAR_BOLETO_USADO` rechaza boletos `USADO`/`ANULADO`. | Corregido |
| 8 | Anular un boleto dos veces generaba inconsistencias. | Falta de control de estado. | `LEHZ_PS_GES_ANULAR_BOLETO` rechaza boletos ya anulados. | Corregido |
| 9 | Trigger de boletos disparaba `ORA-04091` al marcar usado. | Trigger `BEFORE UPDATE` sin excluir `ESTADO`. | Se cambio a `BEFORE INSERT OR UPDATE OF ...` excluyendo `ESTADO`. | Corregido |
| 10 | Login devolvia cursor vacio en vez de error claro. | `LEHZ_PS_LOGIN` no lanzaba excepcion. | Ahora lanza `-20004` con credenciales invalidas o cuenta inactiva. | Corregido |
| 11 | Confirmacion de contrasena solo se validaba en PHP. | Falta de procedimiento en Oracle. | Se creo `LEHZ_PS_REGISTRAR_PUBLICO` y `LEHZ_PS_CREAR_USUARIO_ADMIN`. | Corregido |
| 12 | Menus y privilegios por rol estaban hardcodeados en la interfaz. | No existian vistas/funciones de seguridad. | Se crearon `LEHZ_VW_MENU_ROL`, `LEHZ_FN_ROL_PERMITE` y `LEHZ_PS_LISTAR_MENU`. | Corregido |
| 13 | Listas de dominio (`TIPO_SERVICIO`, `METODO_PAGO`, etc.) hardcodeadas. | No existia vista de dominios. | Se creo `LEHZ_VW_DOMINIOS`. | Corregido |
| 14 | Mantenciones podian registrarse en dias con viaje asignado. | Falta de validacion. | `LEHZ_TRG_MANTENCION` bloquea si el bus tiene viaje ese dia. | Corregido |
| 15 | Conductores con licencia vencida podian asignarse. | Falta de validacion. | `LEHZ_TRG_CONDUCTOR_LICENCIA` exige licencia vigente. | Corregido |
| 16 | Asientos no validaban piso/capacidad/ubicacion 2+2. | Falta de trigger. | `LEHZ_TRG_ASIENTO_VALIDA` calcula ubicacion y valida piso/capacidad. | Corregido |
| 17 | Paradas no validaban origen/permite bajada. | Falta de trigger. | `LEHZ_TRG_RUTA_PARADA_VALIDA` exige parada 1 como origen y destino con bajada. | Corregido |
| 18 | `AÑO_FABRICACION` causaba fallos de codificacion en SQL*Plus. | Identificador con Ñ. | Se renombro a `ANIO_FABRICACION`; todos los scripts son ASCII puro. | Corregido |
| 19 | Drops incompletos en carpetas 04-08. | Faltaban drops integrales. | Se creo `drops/` integral en cada carpeta y se valido reinstalacion 01→08. | Corregido |
| 20 | Seed con fechas pasadas para viajes y futuras para mantenciones. | Datos de prueba incoherentes. | Viajes desde 01/12/2026 y mantenciones en octubre/noviembre 2026. | Corregido |
| 21 | Eliminacion de registros fallaba con "El RUT es obligatorio" / "Telefono obligatorio". | Procedimientos normalizaban campos no enviados en operacion `D`. | Se movio la normalizacion de campos foraneos/telefono/correo al bloque `I/U`. | Corregido |
| 22 | Creacion de bus desde PHP fallaba con `ORA-06502`. | Orden posicional de parametros no coincidia con la firma del procedimiento. | Se cambio a invocacion por nombre (`param => :param`) en `index.php`. | Corregido |
| 23 | `CANTIDAD_PISOS` (dominio) no se convertia a numero. | `bind_expression` no reconocia el dominio. | Se agrego conversion `TO_NUMBER` para `CANTIDAD_PISOS`. | Corregido |

## 2. Interfaz PHP

| # | Error encontrado | Causa raiz | Correccion aplicada | Estado |
|---|------------------|------------|---------------------|--------|
| 24 | Error de sintaxis en `dashboard.php` linea 93 (`<?=`). | Typo. | Se cambio a `<?php`. | Corregido |
| 25 | Falta de vistas `maintainer.php`, `venta.php`, `bajada.php`, `viaje.php`, `conduce.php`, `mantencion.php`, `utilizan.php`, `usuarios.php`, `report.php`. | No existian. | Se crearon todas con formularios y tablas. | Corregido |
| 26 | Router antiguo en `index.php` llamaba venta con precio. | Codigo legado. | Se reescribio `index.php` como router/controlador con acciones POST. | Corregido |
| 27 | `layout_start()` no estaba disponible. | Falta de include. | Se agrego `require_once` de `layout.php`. | Corregido |
| 28 | Autoformato de telefono/RUT no existia. | Falta de JS. | Se implemento en `app.js`. | Corregido |
| 29 | Mostrar/ocultar contrasena no existia. | Falta de JS/CSS. | Se implemento con `data-toggle-password`. | Corregido |
| 30 | Horarios no se mostraban en formato editable. | `TO_CHAR` sin `T`. | Se agrego formato `YYYY-MM-DD"T"HH24:MI`. | Corregido |
| 31 | Columnas `_TEXTO` aparecian duplicadas en tablas. | Listado exponia ambas. | Se filtraron en `maintainer.php` y `report.php`. | Corregido |
| 32 | Error de conversion en `db_bind_value`. | Longitud `-1` para no string. | Se ajusto a `4000`. | Corregido |
| 33 | `bind_expression` no recibia dominio. | Firma incompleta. | Se agrego parametro `$domain`. | Corregido |

## 3. Entorno / despliegue

| # | Error encontrado | Causa raiz | Correccion aplicada | Estado |
|---|------------------|------------|---------------------|--------|
| 34 | Contenedor `lehz-web` detenido (`Exited (137)`). | Proceso anterior terminado. | Se reinicio y se sincronizo con el directorio montado. | Corregido |
| 35 | `lehz-web` montaba `PROYECTO-FINAL-BASE-DE-DATOS`, no el directorio de trabajo. | Ruta de bind distinta. | Se sincronizaron archivos con `robocopy`. | Corregido |
| 36 | `oracle-lehz` se detuvo durante las pruebas. | Contenedor apagado. | Se reinicio y se reinstalo `LEHZTEST`. | Corregido |

## 4. Migracion de interfaz a AdminLTE 4 / Bootstrap 5

| # | Hallazgo | Causa raiz | Correccion aplicada | Estado |
|---|----------|------------|---------------------|--------|
| 37 | La interfaz usaba CSS propio en vez de AdminLTE. | Diseno inicial artesanal. | Se migraron `layout.php`, `login.php`, `dashboard.php`, `maintainer.php`, `venta.php`, `usuarios.php`, `report.php`, `viaje.php`, `mantencion.php`, `conduce.php`, `utilizan.php` y `bajada.php` a `card`, `table`, `btn`, `form-control`, `form-select`, `modal`, `small-box`, `callout` y `input-group`. | Corregido |
| 38 | Selector de tema propio duplicado. | JS propio para claro/oscuro. | Se uso el `ColorMode` nativo de AdminLTE (`data-bs-theme-value`, iconos `data-lte-theme-icon`, `localStorage lte-theme`). | Corregido |
| 39 | `bg-body-tertiary` / `bg-body-secondary` en `<body>` tapaban el fondo del tema. | Clases de Bootstrap con `!important`. | Se quitaron de `layout.php` y `login.php`; `app.css` quedo como capa delgada de tokens. | Corregido |
| 40 | Modales propios no respetaban el ciclo de Bootstrap. | Clase `.show` manual. | `app.js` usa `bootstrap.Modal.getOrCreateInstance(...)` y `getInstance(...).hide()`. | Corregido |
| 41 | El boton "Mostrar" contrasena no encontraba el input. | Buscaba `.password-field`. | Ahora busca `.input-group` o `.password-field`. | Corregido |
| 42 | Telefono `+56 9` + 9 digitos generaba 12 digitos y `ORA-20011`. | El prefijo ya incluye el `9` movil. | `syncPhone()` quita el `9` duplicado; Oracle normaliza a `+569XXXXXXXX`. Verificado con CRUD real. | Corregido |
| 43 | Autocompletado de regiones/comunas no se limpiaba al crear ni se llenaba al editar. | Solo se sincronizaba el input oculto. | `openCreate()` y `editMaintainer()` sincronizan `ac_<campo>`. | Corregido |
| 44 | Al editar horarios quedaban vacios fecha, salida y llegada. | Oracle devuelve timestamps `YYYY-MM-DDTHH24:MI` y los inputs son `date`/`time`. | `editMaintainer()` separa fecha y hora; llegada anterior a salida vuelve a sumar 1 dia en Oracle (verificado). | Corregido |
| 45 | El scroll del menu lateral no se restauraba. | Se buscaba `.sidebar` en vez de `.sidebar-wrapper`. | Selector corregido; `sessionStorage sidebarScroll` probado entre paginas. | Corregido |

## 5. Mejora visual y graficos de recaudacion

| # | Hallazgo | Causa raiz | Correccion aplicada | Estado |
|---|----------|------------|---------------------|--------|
| 46 | La paleta era demasiado plana y gris. | Tokens iniciales poco contrastados. | Nueva identidad azul profundo + cian/menta + acento ambar, con gradientes suaves, sombras y tarjetas redondeadas en claro y oscuro. | Corregido |
| 47 | El login tenia etiquetas ocultas y poca jerarquia. | Marcos AdminLTE sin personalizar. | Icono de marca, escudo de acceso, etiquetas visibles, selector rapido de tema y notas de seguridad. | Corregido |
| 48 | Los reportes solo mostraban una tabla y totales. | No habia visualizacion de series temporales. | `report.php` genera un grafico de linea (SVG) por dia, un grafico circular (conic-gradient) por categoria y barras de boletos vendidos por dia, usando solo datos de Oracle. | Corregido |
| 49 | El reporte de costos de mantencion no detectaba fechas ni categoria. | Las columnas se llamaban `ULTIMA_MANTENCION` y `RAZON_SOCIAL`. | Deteccion de fechas por contenido y de categoria por `NOMBRE/RAZON/RUTA/PATENTE`. | Corregido |
| 50 | La portada del panel era un bloque plano. | `bg-gradient` generico de Bootstrap. | Hero con gradiente propio y detalle decorativo, mas `page-kicker` en el encabezado. | Corregido |
| 51 | El registro publico permitia crear cuentas sin administrador. | Formulario y accion `register` expuestos en login. | Se quitaron la pestaña "Crear cuenta", el formulario y el handler PHP. Los usuarios se crean solo desde el modulo Usuarios (procedimiento de Oracle). | Corregido |

## Pendientes no bloqueantes
- Los scripts SQL usan `ALTER SESSION SET CURRENT_SCHEMA = LEHZ;` en su version original; en `LEHZTEST` se ejecutan con el usuario de prueba. No afecta la entrega.
- El `docker-compose.yml` inicializa solo tablas en una instalacion nueva; la carga completa requiere ejecutar 01→08 manualmente (documentado en README).
- El esquema `LEHZ` no se reinstalo desde cero; su estructura se migro desde `LEHZTEST` y los datos originales quedaron en `LEHZ_BAK_*`. Ver `database/04_migracion/README.md`.

## Verificacion final
- Instalacion 01→08 en `LEHZTEST`: `FAILED_COUNT=0`.
- Pruebas Oracle: 47 verificaciones, todas `PASS` (suite original; la base no se modifico en la fase de interfaz).
- Comprobaciones puntuales repetidas: telefonos `+56 9` / `600` / `809` normalizados por Oracle; `t@hh` rechazado con `ORA-20030` y `@outlook.com` aceptado; horario 23:00→01:00 almacenado como dia siguiente.
- Vistas web probadas: login (sin registro publico), dashboard, 12 mantenedores, venta, bajada, viaje, conduce, mantencion, utilizan, usuarios, 4 reportes (24 paginas en total).
- Las 24 paginas cargan con el shell AdminLTE, sin errores de consola ni mensajes PHP/ORA inesperados.
- CRUD completo verificado en empresas (crear/editar/eliminar) y ciclo de horarios con llegada al dia siguiente.
- Selector de tema claro/oscuro/automatico (tambien en login) y persistencia del scroll lateral verificados.
- Graficos verificados: recaudacion por dia (`$148.400` en 4 dias), distribucion por ruta y boletos vendidos por dia; costos de mantencion tambien generan linea y circular.
- Las 24 paginas se reverificaron tras la mejora visual: sin errores PHP/ORA ni errores de consola.
- Docker levantado el 26/11/2026: `oracle-lehz` y `lehz-web` activos; web responde en `http://localhost:8000` con esquema `LEHZ`.
- `lehz-web` recreado sin `DB_USER=LEHZTEST`; `docker inspect` confirma `DB_USER=LEHZ` y montaje sobre `C:\Users\behemoth\Documents\PROYECTO-FINAL-BASE-DE-DATOS`.
- Sincronizacion de `app/`, `docker-compose.yml`, documentacion y `database/04_migracion/` con `C:\Users\behemoth\Documents\PROYECTO-FINAL-BASE-DE-DATOS` completada; `lehz-web` sirve la version migrada y mejorada.

## 6. Migracion definitiva a `LEHZ`

| # | Hallazgo | Causa raiz | Correccion aplicada | Estado |
|---|----------|------------|---------------------|--------|
| 52 | `LEHZ` tenia estructura antigua: RUT/telefonos `NUMBER`, sin `ESTADO` en boletos, sin paradas ni bajadas. | Esquema original nunca se alineo con `LEHZTEST`. | Se migraron columnas, tablas, secuencias, vistas, procedures, funciones, paquetes y 44 triggers. | Corregido |
| 53 | `DBMS_METADATA` no podia leer restricciones de `LEHZTEST` desde el usuario `LEHZ`. | Faltaban privilegios de catalogo. | Se extrajeron las DDL con `SYSTEM` y se ejecutaron dentro de `LEHZ` (61 restricciones, 27 FKs, 2 indices). | Corregido |
| 54 | El cambio de `NUMBER` a `VARCHAR2` fallaba por `ORA-01439` / `ORA-01463`. | Columnas con datos y restricciones dependientes. | Se agregaron columnas nuevas, se convirtieron los valores, se borraron las columnas viejas y se recrearon las restricciones. | Corregido |
| 55 | Tres patentes heredadas no cumplian el formato nuevo. | Datos legacy de `LEHZ`. | `CK_BUS_PATENTE` se creo con `ENABLE NOVALIDATE`; los triggers validan las altas nuevas. Originales en `LEHZ_BAK_LEHZ_BUS`. | Corregido |
| 56 | Modo oscuro: AdminLTE/Bootstrap sobreescribian bordes, fondos y sombras de tarjetas. | Falta de especificidad en `app.css`. | Se agregaron overrides con selector `[data-bs-theme="dark"]`. | Corregido |
| 57 | `docker-compose.yml` publicaba el puerto `1521` de Oracle en el host. | Mapeo heredado `1521:1521`. | Se elimino el mapeo y se recreo `oracle-lehz`; Oracle queda solo en la red interna de Docker (`oracle-db:1521`). | Corregido |
| 58 | El login era funcional pero visualmente plano. | Falta de una imagen de identidad. | Se agrego la foto del bus al atardecer como fondo a pagina completa (sin desenfoque, solo realce de color) y el formulario se ubico a la derecha dentro de un panel semi-circular de cristal (`border-radius: 50% 0 0 50% / 48% 0 0 48%`, `backdrop-filter: blur(16px)`). Se quito el texto de regiones. Incluye AVIF/WebP y diseno responsive. | Corregido |
| 59 | En Regiones/Comunas el desplegable quedaba cortado dentro del modal y habia que desplazarse para ver las opciones. | `.ac-dropdown` era `position:absolute` y el `.modal-dialog-scrollable` recortaba el desbordamiento. | Se cambio a `position:static` con `max-height:320px`, se amplio la fuente a `.9rem` y se abre automaticamente al abrir el modal (`shown.bs.modal`). El body del modal crece y no requiere scroll. | Corregido |

### Verificacion de la migracion

- Objetos `INVALID`: **0** (9 funciones, 2 paquetes + 2 bodies, 57 procedimientos, 15 secuencias, 44 triggers, 14 vistas).
- Triggers: **44 habilitados / 0 deshabilitados**. Restricciones: **88 habilitadas / 0 deshabilitadas**.
- Datos en `LEHZ`: 20 boletos, 9 bajadas, 43 asientos, 6 viajes, 6 buses, 5 empresas, 8 pasajeros, 4 usuarios.
- Vistas: `LEHZ_VW_COMUNAS_CHILE` 97 filas, `LEHZ_VW_REGIONES_CHILE` 13, `LEHZ_VW_HORARIOS` 6, `LEHZ_VW_BOLETOS` 20, `LEHZ_VW_VIAJES_DETALLE` 6.
- Las 24 paginas se recargaron contra `LEHZ` despues de recrear el contenedor web: todas `HTTP 200`, titulo correcto, sin `ORA-`, `Fatal error`, `Notice` ni errores de consola.
- Panel en modo oscuro: `body` `rgb(11,17,27)`, texto `rgb(222,226,230)`, 6 `small-box` con contraste correcto; reporte de recaudacion con 5 `stat-card`, 1 SVG y sombras/bordes oscuros aplicados.
- Regiones/Comunas verificados: el modal crece a `433 px`, el desplegable mostraba 13/97 opciones sin recorte, fuente `14.4 px` y la seleccion escribe el campo oculto (`Alhue`).
- `docker ps` confirma que `oracle-lehz` **no publica puertos** y `lehz-web` solo publica `8000`; los datos persisten tras recrear Oracle (`LEHZ_USUARIO` = 4 filas).
- Login verificado en claro y oscuro: imagen AVIF cargada (`740x494`) a pagina completa sin desenfoque (`saturate(1.1) contrast(1.04)`), panel semi-circular a la derecha con `backdrop-filter: blur(16px)` y radio `50% 0 0 50% / 48% 0 0 48%`; sin texto de regiones, sin errores de consola y autenticacion `admin` / `Admin1234` redirige al panel.
- Scripts y orden de ejecucion documentados en `database/04_migracion/README.md`.
