# Guion narrado del video de demostración funcional

**Duración total planificada: 13:20 (≤ 14 min; límite de la pauta: 15 min).**  
**Formato:** proyección de la aplicación real sobre Oracle (esquema `LEHZ`) con datos precargados por `database/09_datos_prueba/01_seed_datos.sql`.  
**Regla de grabación:** el llenado de cajas de texto y los clics repetitivos se presentan **acelerados**; la voz narra el resultado, no teclea cada carácter.

## Tabla de tiempos acumulados

| Bloque | Contenido | Inicio | Término | Acumulado |
|---:|---|---:|---:|---:|
| 1 | Inicio de sesión y perfil | 0:00 | 1:30 | 1:30 |
| 2 | Ruta y paradas | 1:30 | 3:10 | 3:10 |
| 3 | Programar viaje y asignar bus | 3:10 | 5:20 | 5:20 |
| 4 | Venta de boletos y bajada | 5:20 | 9:00 | 9:00 |
| 5 | Rechazo de asiento ocupado | 9:00 | 11:10 | 11:10 |
| 6 | Reporte de recaudación | 11:10 | 13:20 | **13:20** |

---

## Bloque 1 — Inicio de sesión y perfil (0:00 → 1:30)

**En pantalla (acelerado):** abrir `?page=login` → usuario `admin` / clave `Admin1234` → `Ingresar` → panel principal con menú por rol. Repetir rápidamente con `vendedor1` / `Ventas1234` para mostrar otro perfil, sin esperar entre teclas.

**Narración:**
> "Iniciamos con un usuario real creado en Oracle. El login no valida en PHP: `index.php` invoca `LEHZ_PS_LOGIN`, que compara el hash SHA-256 contra `LEHZ_USUARIO` y devuelve el perfil por `SYS_REFCURSOR`. Según `LEHZ_VW_MENU_ROL` y `LEHZ_FN_ROL_PERMITE`, el administrador ve mantenedores, gestores, reportes y seguridad; el vendedor ve venta, pasajeros y consultas. El menú que aparece —no una bandera en el navegador— es el que autoriza la base de datos."

**Resultado esperado:** mensaje de bienvenida y menú distinto por rol. Cerrar la repetición con el usuario administrador para continuar.

**Acelerar:** escritura de usuario/clave y espera de redirección. Mantener visible el menú 3–4 s.

---

## Bloque 2 — Ruta y paradas (1:30 → 3:10)

**En pantalla (acelerado):** menú *Rutas* → abrir una ruta Talca–Santiago → menú *Paradas por ruta* → listado ordenado con minutos desde el origen y columna `PERMITE_BAJADA`.

**Narración:**
> "La ruta guarda origen, destino, distancia y nombre en `LEHZ_RUTA`; las paradas no son una lista de texto: son filas en `LEHZ_RUTA_PARADA`, la tabla intermedia N:M entre ruta y terminal. Cada fila tiene su propio orden, minutos desde el origen y permiso de bajada; por eso el orden no depende de la ruta sola ni de la terminal sola. El listado que vemos sale de `LEHZ_PS_LISTAR_RUTA_PARADAS` y el formulario escribe con `LEHZ_PS_IUD_RUTA_PARADA`."

**Resultado esperado:** paradas en orden `1, 2, 3…`, sin duplicar terminal dentro de una misma ruta (`UQ_LEHZ_RUTA_TERMINAL`).

**Acelerar:** desplazamiento por la tabla y selección de opciones del formulario.

---

## Bloque 3 — Programar viaje y asignar bus (3:10 → 5:20)

**En pantalla (acelerado):** menú *Programar viaje* → fecha, horario y ruta → Guardar → mensaje con `ID_VIAJE` → menú *Asignar conductor y bus* → conductor con licencia vigente, bus y el viaje recién creado → Guardar.

**Narración:**
> "Programar un viaje crea una ocurrencia concreta de ruta y horario en `LEHZ_VIAJE`; el índice único `UQ_VIAJE_FECHA_HORARIO_RUTA` evita repetirlo. `LEHZ_PS_GES_PROGRAMAR_VIAJE` devuelve el identificador generado por `LEHZ_SEQ_VIAJE`. Después asignamos conductor y bus mediante `LEHZ_PS_GES_ASIGNAR_CONDUCE`: la tabla `LEHZ_CONDUCE` es N:M ternaria y su clave primaria es conductor + bus + viaje. Los triggers de negocio revisan licencia, capacidad y fechas antes de confirmar."

**Resultado esperado:** mensaje "Viaje programado con ID …" y "Asignación registrada"; fila visible en el listado de asignaciones.

**Acelerar:** selección de fecha y combos. Dejar visible el ID generado al menos 3 s para la traza.

---

## Bloque 4 — Venta de boletos y bajada (5:20 → 9:00)

**En pantalla (acelerado):** menú *Venta de boletos* → pasajero existente `19111222-9` → viaje → asiento disponible, por ejemplo asiento 6 del bus `BCDF12` → método `TARJETA` → terminal de bajada → Vender → mensaje con monto calculado por Oracle → menú *Registrar bajada* → seleccionar el boleto recién emitido → terminal → Guardar.

**Narración:**
> "La venta es un gestor, no un insert suelto: `index.php` llama a `LEHZ_PS_GES_VENDER_BOLETO` con parámetros enlazados. Oracle calcula la tarifa con `LEHZ_FN_CALCULAR_TARIFA_BUS`, inserta el boleto, su pago con `LEHZ_SEQ_PAGO` y, si se indicó terminal de bajada, el registro en `LEHZ_PASAJE_BAJADA`. El precio que aparece en pantalla viene de `LEHZ_BOLETO`: el cliente nunca envía un monto. Luego registramos la bajada con `LEHZ_PS_GES_REGISTRAR_BAJADA`, relación 1:1 con el boleto. Cada movimiento queda en `LEHZ_AUDITORIA` mediante los triggers `LEHZ_TRG_AUD_*`."

**Resultado esperado:** boleto emitido con valor, pago asociado y bajada listada.

**Acelerar:** llenado de RUT y selección de listas; mantener 4 s el mensaje con el monto y el ID de boleto.

---

## Bloque 5 — Rechazo de asiento ocupado (9:00 → 11:10)

**En pantalla (acelerado):** volver a *Venta de boletos* → mismo viaje del bloque 3 / viaje precargado con asiento 1 del bus `BCDF12` → intentar vender ese asiento a otro pasajero → mensaje de error de Oracle en rojo → recargar listado y mostrar que el asiento sigue con un solo boleto activo.

**Narración:**
> "Ahora repetimos la venta sobre un asiento que ya tiene boleto `EMITIDO`. El índice único funcional `UQ_LEHZ_BOLETO_ASIENTO_ACTIVO` y el trigger `LEHZ_TRG_BOLETO_VALIDA` bloquean la operación dentro de la transacción: hay `ROLLBACK` y mensaje descriptivo. No es una validación visual: aunque se llame al procedimiento desde otro cliente, Oracle rechaza el doble asiento. El listado confirma que no se generó un segundo boleto activo."

**Resultado esperado:** error visible, sin boleto nuevo, consistencia preservada en `LEHZ_BOLETO`.

**Acelerar:** selección de los mismos datos; hacer una pausa de 5 s en el mensaje de error para que la comisión lo lea.

---

## Bloque 6 — Reporte de recaudación (11:10 → 13:20)

**En pantalla (acelerado):** menú *Recaudación por viaje* → tabla con boletos vendidos, monto total y viaje → ordenar/filtrar un viaje → abrir brevemente *Ocupación de asientos* para contrastar → volver al panel.

**Narración:**
> "Cerramos con el reporte estratégico de recaudación. `LEHZ_PS_REP_RECAUDACION_VIAJES` abre un `SYS_REFCURSOR`, `db_rows()` lo recorre en PHP y la vista `report.php` lo despliega en tabla. Los boletos `ANULADO` se excluyen del total: el dato no está duplicado ni calculado en la interfaz. Es el mismo patrón de los otros dos reportes estratégicos —costos de mantención y ocupación— más el reporte operativo de itinerario de paradas."

**Resultado esperado:** tabla con totales coherentes con los boletos emitidos en los bloques anteriores.

**Acelerar:** carga y filtrado; dejar 5 s la tabla final.

---

## Notas de producción

- Grabar con resolución legible (1080p) y zoom del navegador al 100–110 %; evitar capturas borrosas.
- Usar datos ya cargados: no improvisar registros durante la exposición.
- Cada bloque debe poder narrarse con la mirada en la comisión; la pantalla es referencia, no guion leído.
- La traza requerida entre código y base de datos está en `TRAZA_VIDEO.md`; en la lámina 14 se resume como `index.php → db_call() → LEHZ_PS_GES_* → tablas LEHZ_* → SYS_REFCURSOR → vista PHP`.
- Tiempo total 13:20 deja 1:40 de margen dentro del límite de 15 minutos de la pauta.
