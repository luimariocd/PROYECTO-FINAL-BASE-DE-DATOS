# Migracion estructural de `LEHZTEST` a `LEHZ`

Esta carpeta documenta la migracion aplicada el 26/11/2026 para que la aplicacion web deje de apuntar a `LEHZTEST` y use el esquema definitivo `LEHZ`, conservando los datos originales de `LEHZ` en tablas de respaldo.

## Estado final

- Interfaz web: `DB_USER=LEHZ` (valor por defecto en `docker-compose.yml`).
- Estructura de `LEHZ` equivalente a `LEHZTEST`: 22 tablas de negocio + 20 tablas `LEHZ_BAK_*` de respaldo.
- Objetos: 9 funciones, 2 paquetes (+2 bodies), 57 procedimientos, 15 secuencias, 44 triggers y 14 vistas, todos `VALID`.
- Restricciones: 88 habilitadas, 0 deshabilitadas.
- Datos de prueba sincronizados desde `LEHZTEST`: 20 boletos, 9 bajadas, 43 asientos, 6 viajes, 6 buses, 5 empresas, 8 pasajeros y 4 usuarios.
- Los datos originales de `LEHZ` permanecen intactos en `LEHZ_BAK_*` (`LEHZ_BAK_LEHZ_EMPRESA`, `LEHZ_BAK_LEHZ_BUS`, etc.).

## Orden de ejecucion

Ejecutar los scripts **con el usuario `LEHZ`** y en este orden:

1. `01_estructura_y_objetos.sql` — respaldo `LEHZ_BAK_*`, columnas nuevas, tablas `LEHZ_RUTA_PARADA` / `LEHZ_PASAJE_BAJADA`, secuencias y objetos PL/SQL.
2. `02_recrear_objetos.sql` — corrige la separacion de specs/bodies de paquetes y vuelve a crear funciones, procedimientos y vistas.
3. `03_recrear_triggers.sql` — elimina triggers heredados y crea los 44 triggers de la version nueva.
4. `04_tipos_y_restricciones.sql` — convierte RUT/telefonos numericos a `VARCHAR2`, elimina restricciones heredadas y prepara la recreacion.
5. `05_restricciones.sql` — crea 61 restricciones (`P`/`U`/`C`), 27 llaves foraneas y 2 indices de `LEHZTEST` dentro de `LEHZ`.
6. `06_datos_prueba.sql` — copia datos de `LEHZTEST` a `LEHZ` con `UPDATE`/`INSERT` por llave primaria; hace `COMMIT` por tabla.
7. `07_activar_y_verificar.sql` — habilita los 44 triggers y recompila objetos invalidos.
8. `08_verificacion.sql` — consultas de control.

## Notas importantes

- `01_estructura_y_objetos.sql` **borra y vuelve a crear** las tablas `LEHZ_BAK_*`. No las uses como fuente original despues de una segunda ejecucion.
- `CK_BUS_PATENTE` quedo creado con `ENABLE NOVALIDATE` porque tres patentes heredadas de `LEHZ` no cumplen el formato nuevo. Los triggers si validan las altas nuevas. Los datos originales siguen en `LEHZ_BAK_LEHZ_BUS`.
- La columna historica `AÑO_FABRICACION` se conserva solo en los respaldos; la tabla activa usa `ANIO_FABRICACION`.
- Si necesitas volver a probar con `LEHZTEST`, usa una variable de entorno **solo en ese contenedor**: `DB_USER=LEHZTEST`. Para la entrega, no definas esa variable.

## Recrear el contenedor web apuntando a `LEHZ`

```powershell
docker compose up -d --force-recreate web
docker inspect lehz-web --format '{{range .Config.Env}}{{println .}}{{end}}' | Select-String '^DB_USER='
```

Debe mostrar `DB_USER=LEHZ`.
