# Errores encontrados y estado

Proyecto: Sistema LEHZ – Transporte Regional  
Rama base: `Denunce`  
Esquema de validacion: `LEHZTEST` (sin destruir `LEHZ`)  
Fecha de cierre de pruebas: 24/11/2026

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

## Pendientes no bloqueantes
- Los scripts SQL usan `ALTER SESSION SET CURRENT_SCHEMA = LEHZ;` en su version original; en `LEHZTEST` se ejecutan con el usuario de prueba. No afecta la entrega.
- El `docker-compose.yml` inicializa solo tablas en una instalacion nueva; la carga completa requiere ejecutar 01→08 manualmente (documentado en README).
- No se reinstalo el esquema `LEHZ` original para no destruir datos; toda la validacion se hizo en `LEHZTEST`.

## Verificacion final
- Instalacion 01→08 en `LEHZTEST`: `FAILED_COUNT=0`.
- Pruebas Oracle: 47 verificaciones, todas `PASS`.
- Vistas web probadas: login, dashboard, 12 mantenedores, venta, bajada, viaje, conduce, mantencion, utilizan, usuarios, 4 reportes.
- Operaciones CRUD y gestores probados exitosamente en `http://localhost:8000` contra `LEHZTEST`.
