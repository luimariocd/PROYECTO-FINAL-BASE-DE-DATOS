# Correcciones exactas del PowerPoint (láminas 1–15)

**Curso:** INF324 – Base de Datos · UCM  
**Aplicar sobre:** texto extraído de la presentación original (`ppt_text.txt`) y reproducir en `Presentacion_Base_Datos_CORREGIDA.pptx`.  
**Convención:** "Actual" es el texto literal que aparece hoy; "Reemplazo" es el texto que debe quedar. Cuando se indica *eliminar*, el elemento no debe aparecer en la lámina corregida.

---

## Lámina 1 — Portada

| Actual | Reemplazo exacto |
|---|---|
| `Sistema de Gestión Integral de Transporte Público Regional` | `Proyecto Final de Base de Datos: "Sistema de Gestión Integral de Transporte Público Regional"` |
| `Nombres de los integrantes:` | `Integrantes:` |
| `Luismario Huenuhueque, Agustin Orellana, Miguel Rivas y José Zamorano` | `Luismario Huenuhueque · Agustín Orellana · Miguel Rivas · José Zamorano` |
| `Académico: Carlos Andrés Castro Bustamante` | `Académico: Carlos Andrés Castro Bustamante` (sin cambios) |
| `Ingeniería Civil Informática · INF324 · 27 de noviembre de 2026` | `Ingeniería Civil Informática · INF324 – Base de Datos · 27 de noviembre de 2026` |

> La pauta exige el prefijo exacto `Proyecto Final de Base de Datos:` y el nombre del curso `INF324 – Base de Datos`.

---

## Lámina 2 — Agenda

| Actual | Reemplazo exacto |
|---|---|
| `UCM  /  INF324 – Base de Datos  /  Proyecto final 2` | `UCM · INF324 – Base de Datos · Proyecto final 2` |
| `01 / Contexto` — `Introducción / Problemática / Propuesta` | Sin cambio de fondo; usar tildes: `Introducción`, `Problemática`. |
| `02 / Desarrollo` — `Arquitectura / Modelo relacional / Objetos PL/SQL` | `Arquitectura / Modelo relacional 3FN / Objetos PL/SQL` |
| `03 / Cierre` — `Demostración funcional / Conclusiones` | Sin cambios. |

---

## Lámina 3 — Introducción

| Actual | Reemplazo exacto |
|---|---|
| `Introduccion` | `Introducción` |
| `UCM  /  INF324 – Base de Datos  /  Proyecto final 3` | `UCM · INF324 – Base de Datos · Proyecto final 3` |
| `La disponibilidad y consistencia de los registros condicionan la gestión del servicio.` | Sin cambios (texto correcto). |

---

## Lámina 4 — Problemática del rubro / Diagnóstico

| Actual | Reemplazo exacto |
|---|---|
| `Diagnostico de la situacion` | `Diagnóstico de la situación` |
| `Registros aislados y sistemas independientes.` | Sin cambios. |
| `Dificultad para asignar buses y conductores y controlar mantenciones.` | Sin cambios. |
| Riesgo de sobreventa de asientos... (bloque existente) | Sin cambios, con tilde en `obtener reportes confiables`. |
| *Sin evidencia de diagnóstico en la original* | Añadir recuadro rotulado: `EVIDENCIA DE DIAGNÓSTICO` con el contenido: `[Carta de compromiso firmada o resultado del formulario de preguntas aplicado]` |

> El recuadro es un **placeholder explícito y único** (evidencia a adjuntar). No debe contener instrucciones sueltas ni texto de trabajo como "esta diapositiva debe…". La pauta de la rúbrica exige justificar el problema con carta de compromiso firmada **o** formulario aplicado.

---

## Lámina 5 — Propuesta de solución

| Actual | Reemplazo exacto |
|---|---|
| `UCM  /  INF324 – Base de Datos  /  Proyecto final 5` | `UCM · INF324 – Base de Datos · Proyecto final 5` |
| `Base Oracle para datos geográficos, flota, personal, rutas y ventas.` | Sin cambios. |
| `PL/SQL para validaciones, transacciones, consultas y auditoría.` | Sin cambios. |
| `Aplicación PHP con AdminLTE 4 y Bootstrap 5; entorno Docker.` | Sin cambios. |

---

## Lámina 6 — Arquitectura cliente-servidor

| Actual | Reemplazo exacto |
|---|---|
| `Arquitectura cliente-servidor ` (espacio final) | `Arquitectura cliente-servidor` |
| `Navegador → PHP 8` / `Formularios, sesión, vistas y dashboards.` | Sin cambios. |
| `db_call: invoca PL/SQL. db_rows: recupera SYS_REFCURSOR. Parámetros enlazados.` | Sin cambios. |
| `Tablas, restricciones, procedimientos, funciones, secuencias y triggers.` | Sin cambios. |
| `Docker: servicios web y oracle-db.` | Sin cambios. |
| *Sin pie de arquitectura* | Añadir pie: `Lógica pesada en Oracle; PHP solo invoca objetos de la BD.` |

---

## Lámina 7 — Modelo relacional

| Actual | Reemplazo exacto |
|---|---|
| `Modelo Relacional` | `Modelo relacional en 3FN` |
| `DISEÑO DE BASE DE DATOS` / `MODELADO` | `DISEÑO DE BASE DE DATOS · ESQUEMA LHAOMRJZ` |
| *Sin texto técnico (solo imagen)* | Añadir tres recuadros: `22 tablas con PK declarada (simples, compuestas y ternaria)` · `FK 1:N y relaciones N:M resueltas en LHAOMRJZ_CONDUCE, LHAOMRJZ_UTILIZAN y LHAOMRJZ_RUTA_PARADA` · `3FN: sin atributos dependientes de atributos no clave` |
| *Sin respaldo impreso anunciado* | Añadir pie: `Respaldo impreso: MODELO_3FN.md y modelo_relacional.html.` |

> Insertar la imagen `modelo_relacional.png` (copia de `modelo_ppt.png`) en esta lámina.

---

## Lámina 8 — Mantenedores y gestores

| Actual | Reemplazo exacto |
|---|---|
| `Diseño de  la Base de datos` | `Diseño de la base de datos` |
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 8` |
| `12 mantenedores` | `10 mantenedores` |
| `Región, comuna, terminal, empresa, bus, asiento, conductor, mecánico, ruta, horario, parada y pasajero.` | `Región, comuna, terminal, empresa, bus, asiento, conductor, mecánico, ruta y horario.` |
| *Sin bloque de extensiones* | Añadir: `2 extensiones: paradas por ruta (LHAOMRJZ_RUTA_PARADA) y pasajeros (LHAOMRJZ_PASAJERO).` |
| `5 gestores principales` | `5 gestores` (ídem contenido: venta de boletos, programación de viajes, asignación de conducción, mantenciones, asociación empresa–terminal) |
| `Registro de bajadas, vistas y tarifas. Rutas con origen, destino y paradas habilitadas.` | `Extensión funcional: registro de bajadas y cálculo de tarifas. Rutas con origen, destino y paradas habilitadas.` |

---

## Lámina 9 — Procedimientos almacenados

| Actual | Reemplazo exacto |
|---|---|
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 9` |
| `¿Que son?` | `¿Qué son?` |
| `Son bloques de codigo PL/SQL almacenados en Oracle que permiten ejecutar operaciones especificas de la base de datos.` | `Son bloques de código PL/SQL almacenados en Oracle que ejecutan operaciones específicas de la base de datos.` |
| `Funciones Principales` | `Funciones principales` |
| `validar informacion antes de modificarla.` | `validar información antes de modificarla.` |
| `eEjecutar operaciones mediante trasacciones` | `Ejecutar operaciones mediante transacciones (COMMIT / ROLLBACK).` |
| `Ejemplos en el projecto` | `Ejemplos en el proyecto` |
| `Funciones` (etiqueta suelta al pie) | `Excepciones controladas con mensajes descriptivos.` |

---

## Lámina 10 — Funciones y secuencias

| Actual | Reemplazo exacto |
|---|---|
| Primera aparición: `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 10` |
| Segunda aparición duplicada del mismo pie | Eliminar (dejar una sola). |
| `Permiten realizar cálculos y devolver resultados que son utilizados por otros procesos del sistema.` | Sin cambios. |
| `Generan identificadores numéricos automáticamente para los registros de las tablas.` | Sin cambios. |
| `LHAOMRJZ_SEQ_REGION / LHAOMRJZ_SEQ_VIAJE / LHAOMRJZ_SEQ_BOLETO / LHAOMRJZ_SEQ_PAGO` | Sin cambios. |
| `LHAOMRJZ_FN_CALCULAR_TARIFA_BUS / LHAOMRJZ_FN_CALCULAR_TARIFA` | Sin cambios; añadir `LHAOMRJZ_FN_VALIDAR_PASSWORD`. |
| `Procedimientos almacenados` (etiqueta suelta al pie) | `Uso transversal: funciones invocadas desde PA, vistas y triggers.` |

---

## Lámina 11 — Funciones y secuencias (lámina vacía)

| Actual | Reemplazo exacto |
|---|---|
| `Funciones y secuencias` (título) | `Triggers de integridad y auditoría` |
| `Secuencias` / `PL/SQL` (títulos sueltos) | Eliminar. |
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 11` |
| *Contenido vacío* | Bloque 1: `Validación automática: LHAOMRJZ_TRG_BOLETO_VALIDA, LHAOMRJZ_TRG_ASIENTO_VALIDA, LHAOMRJZ_TRG_CONDUCTOR_LICENCIA, LHAOMRJZ_TRG_VIAJE_FECHA, LHAOMRJZ_TRG_RUTA_PARADA_VALIDA.` Bloque 2: `Auditoría: LHAOMRJZ_TRG_AUD_* → LHAOMRJZ_AUDITORIA con LHAOMRJZ_PKG_AUDITORIA; operadores :NEW y :OLD, usuario y fecha.` Pie: `BEFORE/AFTER según el evento de negocio: bloqueo y trazabilidad desde Oracle.` |

---

## Lámina 12 — Cursores y reportes

| Actual | Reemplazo exacto |
|---|---|
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 12` |
| `Permiten trabajar con los resultados obtenidos mediante consultas SQL. En este proyecto se utilizan cursores de tipo SYS_REFCURSOR para entregar los resultados de los reportes a la aplicación.` | Sin cambios (corregido). |
| `Recaudación por viaje` | `Recaudación por viaje (estratégico 1) · LHAOMRJZ_PS_REP_RECAUDACION_VIAJES` |
| `Costos de mantención` | `Costos de mantención (estratégico 2) · LHAOMRJZ_PS_REP_COSTOS_MANTENCION` |
| `Ocupación de asientos` | `Ocupación de asientos (estratégico 3) · LHAOMRJZ_PS_REP_OCUPACION_ASIENTOS` |
| `Itinerario de paradas` | `Itinerario de paradas (operativo) · LHAOMRJZ_PS_REP_ITINERARIO_PARADAS` |
| *Sin encabezado de tubería* | Añadir: `SYS_REFCURSOR → db_rows() → tabla / dashboard.` |

> Resultado: **3 reportes estratégicos + 1 operativo**, según lo solicitado.

---

## Lámina 13 — Triggers y control de acceso

| Actual | Reemplazo exacto |
|---|---|
| `Esta diapositiva debe explicar cómo el sistema realiza validaciones automáticas y protege la informació operaciones.` | `Validaciones automáticas y control de acceso implementados en Oracle.` |
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 13` |
| `¿Qué son los triggers?` (si se mantiene) | `Control de acceso por roles (LHAOMRJZ_PS_LOGIN, LHAOMRJZ_VW_MENU_ROL, LHAOMRJZ_FN_ROL_PERMITE).` |
| `Administrador: acceso a la gestión general.` | `ADMINISTRADOR: acceso a mantenedores, gestores, reportes y seguridad.` |
| `Vendedor: acceso a ventas, pagos y consultas de viajes.` | `VENDEDOR: venta de boletos, pagos y consulta de viajes.` |
| `Operaciones: gestión de flota, viajes, conductores y mantenciones.` | `OPERACIONES: flota, viajes, conductores, mantenciones y paradas.` |

> Se elimina **toda instrucción de trabajo** (" Esta diapositiva debe…"). No quedan frases de consigna en la lámina.

---

## Lámina 14 — Demostración de aplicación funcional

| Actual | Reemplazo exacto |
|---|---|
| `Demostracion de Aplicacion Funcional` (aparece dos veces) | `Demostración de aplicación funcional` (una sola vez) |
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 14` |
| `ESPACIO PARA VIDEO` | `VIDEO DE PRUEBA · ≤ 15 min · datos reales` |
| `Grabación del sistema en ejecución` | `Seis bloques narrados; llenado de formularios acelerado.` |
| `vIDEO DE PRUEBA` | `VIDEO DE PRUEBA` (una sola vez, sin duplicado) |
| Lista `1. Inicio de sesión y perfil … 6. Reporte de recaudación` | Mantener con tiempos: `0:00 login/perfil · 1:35 ruta y paradas · 3:10 programar viaje y asignar bus · 5:40 venta y bajada · 9:20 rechazo de asiento ocupado · 11:40 recaudación.` |
| *Sin guion ni traza* | Añadir recuadro `GUION ACELERADO`: `admin → menú por rol · ver paradas ordenadas · programar viaje y asignar bus · vender boleto y registrar bajada · intentar asiento ocupado → error Oracle · abrir reporte de recaudación.` Añadir recuadro `TRAZA CÓDIGO → BD`: `index.php → db_call() → LHAOMRJZ_PS_GES_* → LHAOMRJZ_BOLETO / LHAOMRJZ_PAGO / LHAOMRJZ_AUDITORIA → SYS_REFCURSOR → vista PHP.` |

---

## Lámina 15 — Conclusión

| Actual | Reemplazo exacto |
|---|---|
| `Conclusion` | `Conclusión` |
| `Problematica` (subtítulo) | `CIERRE` |
| `UCM  /  INF324 – Base de Datos  /  Proyecto final xxx` | `UCM · INF324 – Base de Datos · Proyecto final 15` |
| `Una estructura común para datos operativos y comerciales.` | Sin cambios. |
| `Reglas de negocio y transacciones implementadas en Oracle.` | Sin cambios. |
| `Facilita trazabilidad, gestión de itinerarios y análisis de la operación.` | Sin cambios. |
| `Validar en ejecución antes de entregar.` | `Demostración ejecutada con datos reales y traza código → BD verificada.` |

---

## Comprobación global antes de entregar

- [x] Portada con prefijo `Proyecto Final de Base de Datos:` y `INF324 – Base de Datos`.
- [x] `Agustín` con tilde; `Introducción`, `Diagnóstico`, `Demostración`, `Conclusión`, `¿Qué son?`, `código`, `específicas`, `información`, `transacciones`, `proyecto`.
- [x] Lámina 4 con recuadro único de carta de compromiso / formulario (placeholder claro, sin consignas).
- [x] Lámina 7 con 3FN, PK, FK y N:M + imagen del modelo.
- [x] Ningún `xxx` en láminas 8–15: numeración `8` a `15`.
- [x] Lámina 11 con contenido técnico real; sin láminas vacías.
- [x] Lámina 13 sin instrucciones de trabajo.
- [x] Lámina 14 con video acelerado y traza código → BD.
- [x] 10 mantenedores + 2 extensiones; 5 gestores; 3 reportes estratégicos + 1 operativo.
- [x] Sin textos de consigna tipo "esta diapositiva debe…" ni marcadores `xxx`.
- [x] Las cuatro notas de orador (`Estudiante1` a `Estudiante4`) están en **cada** lámina del PPTX corregido.

---

## Ajustes finales aplicados tras la auditoría del código (27-11-2026)

| Lámina | Texto anterior | Texto vigente | Motivo |
|---|---|---|---|
| 7 | `Seguridad y auditoria:` | `Seguridad y auditoría:` | Falta de tilde. |
| 12 | `3 reportes estratégicos para decisión + 1 reporte operativo de itinerario.` | `3 estratégicos + 1 operativo + 2 de apoyo (dashboard y valor de boleto).` | El esquema final tiene 6 procedures de reporte, no 4. |
| 15 | `PK, FK, CHECK, PA y triggers.` | `PK, FK, UNIQUE, PA y triggers; sin CHECK en DDL.` | El DDL final tiene **0 CHECK**: las validaciones están en triggers y procedures. |

## Pendiente que NO se puede corregir con texto

1. **Lámina 4 — evidencia real.** El recuadro `EVIDENCIA DE DIAGNÓSTICO` sigue siendo un placeholder. Reemplazar `[Carta de compromiso firmada o resultado del formulario de preguntas aplicado]` por una imagen o captura real: carta firmada escaneada, o captura del formulario con respuestas. Ver `docs/evidencia/` si el archivo ya fue guardado por el equipo.
2. **Lámina 14 — video real.** El PDF/PPTX solo contiene la estructura narrada; no hay archivo de video incrustado. Grabar con `docs/video_demo/GUION_VIDEO.md` (13:20) y `TRAZA_VIDEO.md` (31 pasos), insertar el MP4 en la lámina 14 y exportar de nuevo el PDF.
3. **Exportación PDF.** Ya existe `Presentacion_Base_Datos_CORREGIDA.pdf` generado desde el PPTX corregido con LibreOffice (15 páginas). Usar ese archivo, nunca la versión antigua de 17 láminas que circuló en `Descargas`. El PDF **no incluye las notas de orador**: para exponer, abrir el PPTX.

> La versión antigua (17 láminas, `21 tablas`, `12 mantenedores`, `ESPACIO PARA VIDEO`) no debe entregarse.
