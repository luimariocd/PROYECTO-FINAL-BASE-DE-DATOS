# Sistema de Gestión Integral de Transporte Público Regional (INF324)

Repositorio oficial del Proyecto Final de Base de Datos (UCM). Incluye la arquitectura de base de datos Oracle, objetos PL/SQL, entorno contenedorizado (Oracle + PHP/OCI8), aplicación web y documentación de entrega.

> **Versión actual de la interfaz:** AdminLTE 4 + Bootstrap 5, selector de tema claro/oscuro/automático y gráficos de recaudación. La lógica de negocio sigue estando **solo en Oracle**.

---

## Actualización rápida: venía usando la versión antigua y quiero la nueva en mi Docker

Esta actualización **solo cambia la carpeta `app/`** (interfaz web). **No modifica la base de datos ni los scripts SQL**, así que **no debes borrar volúmenes ni volver a cargar los scripts 01→08** si ya tienes tus datos cargados.

### 1) Guarda primero tu trabajo

```powershell
git status
git add .
git commit -m "WIP antes de actualizar a la interfaz AdminLTE"
```

Si no quieres hacer commit, guarda tus cambios temporalmente:

```powershell
git stash
```

### 2) Trae la versión nueva

**Opción A — si los cambios ya están en GitHub (recomendado):**

```powershell
git fetch origin
git checkout Denunce
git pull origin Denunce
```

Si quieres conservar tu rama personal, fusiona la rama nueva en ella:

```powershell
git checkout nombre-de-tu-rama
git merge origin/Denunce
```

> Cuando el equipo fusione todo en `main`, reemplaza `Denunce` por `main` en los comandos anteriores.

**Opción B — si todavía no está subido a GitHub:**

Copia desde la copia de la rama `Denunce` estos elementos y reemplaza los tuyos:

```text
app/                         # carpeta completa (incluye views/, public/assets/ y public/adminlte/)
```

No reemplaces `database/` ni `docker-compose.yml` si tu base ya funciona.

### 3) Comprueba que los archivos llegaron

```powershell
Test-Path app\public\adminlte\css\adminlte.min.css
Test-Path app\public\assets\css\app.css
Test-Path app\views\report.php
```

Los tres deben devolver `True`.

### 4) Actualiza el contenedor web

Como `docker-compose.yml` monta el repositorio dentro del contenedor, normalmente basta con reiniciar el servicio web:

```powershell
docker compose restart web
```

Si además cambió el `Dockerfile` o el `docker-compose.yml`, reconstruye:

```powershell
docker compose up -d --build
```

### 5) Refresca el navegador y valida

1. Abre **http://localhost:8000** *(antes se indicaba 8080; el puerto real del compose es 8000)*.
2. Haz **Ctrl + F5** (o abre una ventana de incógnito) para evitar caché del CSS/JS antiguo.
3. Inicia sesión con tu usuario (ej. `admin` / `Admin1234`).
4. Debes ver: login con escudo y selector de tema, panel con portada degradada y, en **Recaudación por viaje**, gráfico de línea, circular y barras de boletos.

### 6) Si sigues viendo la interfaz antigua

```powershell
docker compose down
docker compose up -d --build
docker exec lehz-web ls /var/www/html/app/public/adminlte
```

También revisa que Docker Desktop tenga habilitado el *file sharing* de la carpeta del proyecto y que el navegador no esté sirviendo una copia cacheada.

> **No ejecutes `docker compose down -v`** salvo que quieras borrar la base de datos completa.

---

## Requisitos Previos

* **Git** instalado.
* **Windows 10/11** con virtualización habilitada.
* **Visual Studio Code** instalado.

---

## 1. Activar WSL 2 e Instalar Docker Desktop (Solo la primera vez)

Docker Desktop necesita el **Subsistema de Windows para Linux (WSL 2)** para ejecutar los contenedores. Si nunca lo has activado en tu PC, hazlo antes de abrir Docker:

1. Abrir el menú **Inicio**, escribir `PowerShell`, hacer clic derecho sobre **Windows PowerShell** y elegir **Ejecutar como administrador**.
2. Ejecutar el siguiente comando para instalar el motor WSL sin descargar distribuciones pesadas innecesarias:
   ```powershell
   wsl --install --no-distribution
   ```
3. Si Windows indica que WSL ya estaba instalado pero desactualizado, ejecutar enseguida:
   ```powershell
   wsl --update
   ```
4. **Reiniciar el computador** (obligatorio para activar los componentes de virtualización).
5. Descargar e instalar **Docker Desktop para Windows** dejando marcada la opción **Use WSL 2 instead of Hyper-V** (y *All-users installation*).
6. Abrir **Docker Desktop**, aceptar los términos y esperar a que el ícono de la ballena en la barra de tareas quede quieto indicando *Docker Desktop is running*.

---

## 2. Clonar el Repositorio y Levantar Docker (Oracle + Aplicación Web PHP)

> Esta sección es para el PC que corre Docker con el proyecto.

El archivo `docker-compose.yml` junto con el `Dockerfile` levantan automáticamente dos servicios conectados entre sí:
* **`oracle-db`** (contenedor `oracle-lehz`): Base de datos Oracle Database Free (`FREEPDB1`), accesible solo desde la red interna de Docker en el puerto `1521` (**no publicado en el host**).
* **`web`** (contenedor `lehz-web`): Servidor PHP 8 + OCI8 con la interfaz en `http://localhost:8000`.

1. Clonar el proyecto y entrar a la carpeta:
   ```powershell
   git clone https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git
   cd PROYECTO-FINAL-BASE-DE-DATOS
   ```
   *(Si ya tienes el repositorio clonado, ejecuta `git fetch origin` y luego `git pull origin Denunce` —o `main` cuando ya esté fusionado— para traer los últimos cambios).*

2. Construir y levantar los contenedores en segundo plano:
   ```powershell
   docker compose up -d --build
   ```
   > **Nota:** La primera ejecución tardará entre 2 y 4 minutos mientras descarga la imagen de Oracle, compila la extensión `oci8` de PHP, crea el usuario `LEHZ` y ejecuta las tablas iniciales.

3. Verificar que Oracle terminó de inicializarse:
   ```powershell
   docker logs -f oracle-lehz
   ```
   Cuando aparezca el mensaje `DATABASE IS READY TO USE!`, presiona **`Ctrl + C`** para salir de los registros.

4. Verificar que ambos contenedores estén corriendo:
   ```powershell
   docker ps
   ```

---

## 3. Instalar la Extensión de Oracle y Cargar Scripts PL/SQL

1. Abrir la carpeta `PROYECTO-FINAL-BASE-DE-DATOS` en **Visual Studio Code**.
2. Abrir el panel de **Extensiones** (`Ctrl + Shift + X`), buscar **`Oracle SQL Developer for VSCode`** (autor: **Oracle Corporation**) e instalarla.
3. El contenedor **no publica el puerto `1521` en Windows**. Para ejecutar scripts usa SQL*Plus dentro del contenedor:
   ```powershell
   docker exec oracle-lehz sqlplus -s -S LEHZ/Lehz1234@localhost:1521/FREEPDB1
   ```
   Después de instalar verifica con `SELECT 'INVALID=' || COUNT(*) FROM USER_OBJECTS WHERE STATUS='INVALID';` (debe dar 0). Para conectarte con SQL Developer desde otro contenedor usa host `oracle-db`, puerto `1521`, servicio `FREEPDB1`, usuario `LEHZ` y contraseña `Lehz1234`. Desde Windows, si necesitas GUI, usa un túnel SSH en lugar de publicar el puerto.
4. Ejecutar el instalador único, que limpia objetos heredados y carga todo en orden:
   ```powershell
   docker cp .\database\. oracle-lehz:/tmp/lehz_database
   docker exec -w /tmp/lehz_database oracle-lehz sqlplus -s -S LEHZ/Lehz1234@localhost:1521/FREEPDB1 @/tmp/lehz_database/00_instalacion_completa.sql
   ```
   El script incluye drops de todos los objetos, catálogo, secuencias, seguridad, funciones, mantenedores, gestores, reportes, triggers y semilla con fechas relativas, y termina con `PURGE RECYCLEBIN`. Al terminar deben quedar 22 tablas, 22 PK, 27 FK, 9 UNIQUE, 57 procedures, 38 funciones, 51 triggers, 14 secuencias y 0 objetos inválidos. Al terminar deben quedar 22 tablas y 0 objetos inválidos. Las carpetas están ordenadas por creación: `01_tablas`, `02_secuencias`, `03_seguridad`, `04_funciones`, `05_mantenedores`, `06_gestores`, `07_reportes`, `08_triggers`, `09_datos_prueba`. Todos los archivos con formato `0x_y` se unieron en su base: `08_triggers/01_drop_triggers.sql` y `08_triggers/02_create_triggers.sql`. Ya no existen `01_1`, `01_2`, `02_1`, `02_2` ni `02_3`. Mantenedores, gestores y reportes conservan un archivo por objeto.
   * Si necesitas ejecutar scripts individuales, el orden es `08_triggers/01_drop_triggers.sql` → `07_reportes/Drops` → `06_gestores/Drop` → `05_mantenedores/drop` → `04_funciones/01_drop_funciones.sql` → `03_seguridad/01_drop_seguridad.sql` → `01_tablas/01_drop_tables.sql` → `02_secuencias/01_drop_sequences.sql` → `01_tablas/02_create_tables.sql` → `01_tablas/03_cat_chile.sql` → `02_secuencias/02_create_sequences.sql` → `03_seguridad/02_create_seguridad.sql` → `04_funciones/02_create_funciones.sql` → `05_mantenedores` → `06_gestores` → `07_reportes` → `08_triggers/02_create_triggers.sql` → `09_datos_prueba/01_seed_datos.sql`.
   * Dentro de `01_tablas`, ejecuta `01_drop_tables.sql`, `02_create_tables.sql` y luego **`03_cat_chile.sql`** (catálogo fijo de 16 regiones y 346 comunas).
   * La correspondencia con la material de la catedra esta en `docs/material_referencia/CORRESPONDENCIA_MATERIAL.md`.

> La interfaz usa `DB_USER=LEHZ` por defecto; no definas `DB_USER=LEHZTEST` salvo que quieras probar contra el esquema de validación.

---

## 4. Acceso a la Aplicación Web

Una vez levantados los contenedores y cargados los scripts PL/SQL:

1. Abrir el navegador e ingresar a **`http://localhost:8000`**.
2. Iniciar sesión con las credenciales creadas en `database/03_seguridad/` (por ejemplo `admin` / `Admin1234`).
3. No existe registro público: los usuarios los crea únicamente el administrador desde el módulo **Usuarios**.

---

## 5. Flujo de Trabajo en Git: Cómo Crear una Rama Propia desde `main`

Para evitar conflictos al trabajar en equipo, **ningún integrante debe trabajar ni hacer push directo sobre `main`**. Cada integrante debe crear su propia rama a partir de `main` siguiendo estos pasos:

### Paso 1: Asegurarse de tener `main` actualizado
Antes de crear tu rama, sitúate en `main` y descarga los últimos cambios del repositorio remoto:
```powershell
git checkout main
git pull origin main
```

### Paso 2: Crear y cambiar a tu rama personal
Crea tu rama usando un nombre descriptivo con tu nombre o módulo asignado (por ejemplo `rama-luismario`, `rama-nicolas`, `feature-reportes`, etc.):
```powershell
git checkout -b nombre-de-tu-rama
```
*(Ejemplo: `git checkout -b rama-nicolas`)*

Para confirmar que estás parado en tu nueva rama y no en `main`:
```powershell
git branch
```
*(Tu rama aparecerá marcada con un asterisco `*` en verde).*

### Paso 3: Guardar y subir tus avances a tu rama en GitHub
Cada vez que modifiques archivos en tu carpeta:
```powershell
git add .
git commit -m "Describe brevemente lo que hiciste"
git push -u origin nombre-de-tu-rama
```
*(A partir del segundo push en esa misma rama, basta con ejecutar `git push`).*

### Paso 4: Integrar tus cambios a `main` (Pull Request)
1. Ingresar al repositorio en GitHub: [PROYECTO-FINAL-BASE-DE-DATOS](https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS).
2. Hacer clic en el botón amarillo **Compare & pull request** que aparece arriba al subir tu rama (o ir a la pestaña **Pull requests** → **New pull request**).
3. Verificar que diga **`base: main` ← `compare: nombre-de-tu-rama`**.
4. Presionar **Create pull request** y luego **Merge pull request** para fusionar tus cambios con `main`.

### Paso 5: Actualizar tu rama local si otro compañero actualizó `main`
Si otro integrante fusionó cambios en `main` y quieres traerlos a tu rama sin perder tu trabajo:
```powershell
git checkout main
git pull origin main
git checkout nombre-de-tu-rama
git merge main
```

---

## 6. Comandos Útiles de Docker

* **Detener todos los contenedores** (libera RAM sin borrar tus datos):
  ```powershell
  docker compose stop
  ```
* **Volver a encender los contenedores:**
  ```powershell
  docker compose start
  ```
* **Reconstruir la imagen web PHP** (si modificaste el `Dockerfile` o `docker-compose.yml`):
  ```powershell
  docker compose up -d --build
  ```
* **Reconstruir la base de datos desde cero** *(elimina todos los datos y vuelve a ejecutar el DDL inicial)*:
  ```powershell
  docker compose down -v
  docker compose up -d --build
  ```

---

## 7. Estructura del Repositorio

```text
PROYECTO-FINAL-BASE-DE-DATOS/
├── app/                   # Capa cliente PHP + OCI8 (interfaz y conexión a Oracle)
│   ├── public/
│   │   ├── adminlte/      # Archivos CSS/JS de AdminLTE
│   │   ├── assets/        # app.css y app.js (tema, gráficos, autocompletado)
│   │   └── index.php      # Router/controlador
│   └── views/             # Vistas migradas a AdminLTE/Bootstrap 5
├── database/              # Scripts Oracle PL/SQL (prefijo LEHZ_)
│   ├── 01_tablas/         # Drops, creación de tablas y catálogo de Chile
│   ├── 02_secuencias/     # Secuencias para llaves primarias
│   ├── 03_seguridad/      # Usuarios, roles y autenticación
│   ├── 04_funciones/      # 01 drop y 02 create de las 31 funciones centralizadas
│   ├── 05_mantenedores/   # 12 CRUDs con PA, funciones y cursores (+ drop/)
│   ├── 06_gestores/       # 8 módulos transaccionales (+ Drop/)
│   ├── 07_reportes/       # 3 reportes estratégicos + 1 operativo (+ Drops/)
│   ├── 08_triggers/       # Disparadores de dominio, monitoreo y auditoría
│   ├── 09_datos_prueba/   # Carga de datos reales para demostración (+ Drops/)
│   ├── 00_instalacion_completa.sql # Instalador único y ordenado
│   └── 00_limpieza_legacy.sql # Limpieza opcional de restos heredados
├── docs/                  # Modelo 3FN, material de referencia INF314/INF324, PPT, guion y traza
├── Dockerfile             # Construcción del contenedor PHP 8 + extensión OCI8
├── docker-compose.yml     # Orquestación de contenedores (Oracle + Web PHP)
└── README.md              # Guía de instalación, actualización y flujo Git
```