-- Esta parte del código se encarga de instalar la base de datos completa en orden.
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT == Limpieza de objetos heredados ==
@@00_limpieza_legacy.sql

PROMPT == Drops de triggers ==
@@08_triggers/01_drop_triggers.sql

PROMPT == Drops de reportes ==
@@07_reportes/Drops/01_drop_reportes.sql

PROMPT == Drops de gestores ==
@@06_gestores/Drop/01_drop_gestores.sql

PROMPT == Drops de mantenedores ==
@@05_mantenedores/drop/01_drop_mantenedores.sql

PROMPT == Drops de funciones ==
@@04_funciones/01_drop_funciones.sql

PROMPT == Drops de seguridad ==
@@03_seguridad/01_drop_seguridad.sql

PROMPT == Drops de tablas ==
@@01_tablas/01_drop_tables.sql

PROMPT == Drops de secuencias ==
@@02_secuencias/01_drop_sequences.sql

PROMPT == 01 Tablas ==
@@01_tablas/02_create_tables.sql

PROMPT == Catalogo de Chile ==
@@01_tablas/03_cat_chile.sql

PROMPT == 02 Secuencias ==
@@02_secuencias/02_create_sequences.sql

PROMPT == 03 Seguridad ==
@@03_seguridad/02_create_seguridad.sql

PROMPT == 04 Funciones ==
@@04_funciones/02_create_funciones.sql

PROMPT == 05 Mantenedores (12) ==
@@05_mantenedores/01_crud_region.sql
@@05_mantenedores/02_crud_comuna.sql
@@05_mantenedores/03_crud_terminal.sql
@@05_mantenedores/04_crud_empresa.sql
@@05_mantenedores/05_crud_bus.sql
@@05_mantenedores/06_crud_asiento.sql
@@05_mantenedores/07_crud_conductor.sql
@@05_mantenedores/08_crud_mecanico.sql
@@05_mantenedores/09_crud_ruta.sql
@@05_mantenedores/10_crud_horario.sql
@@05_mantenedores/11_crud_ruta_parada.sql
@@05_mantenedores/12_crud_pasajero.sql
@@05_mantenedores/14_listar_comunas_chile.sql

PROMPT == 06 Gestores ==
@@06_gestores/01_ges_ventas.sql
@@06_gestores/02_ges_viajes.sql
@@06_gestores/03_ges_conduce.sql
@@06_gestores/04_ges_mantencion.sql
@@06_gestores/05_ges_utilizan.sql
@@06_gestores/06_ges_vistas_tarifas_bajadas.sql
@@06_gestores/07_ges_listar_paradas_bajada.sql
@@06_gestores/08_ges_listar_dominios.sql

PROMPT == 07 Reportes (4) ==
@@07_reportes/01_rep_recaudacion_viajes.sql
@@07_reportes/02_rep_costos_mantencion.sql
@@07_reportes/03_rep_ocupacion_asientos.sql
@@07_reportes/04_rep_itinerario_paradas.sql
@@07_reportes/05_rep_resumen_dashboard.sql
@@07_reportes/06_rep_valor_boleto.sql

PROMPT == 08 Triggers (dominio, monitoreo y auditoria) ==
@@08_triggers/02_create_triggers.sql

PROMPT == 09 Semilla ==
@@09_datos_prueba/01_seed_datos.sql

PURGE RECYCLEBIN;

PROMPT == Verificacion: instalacion completada. Ejecute SHOW ERRORS si sqlplus reporta advertencias. ==
