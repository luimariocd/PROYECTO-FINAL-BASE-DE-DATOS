# Sistema de Gestión Integral de Transporte Público Regional (INF324)

Repositorio oficial del Proyecto Final de Base de Datos (UCM). Incluye la arquitectura de base de datos Oracle, objetos PL/SQL, entorno contenedorizado (Oracle + PHP/OCI8), aplicación web y documentación de entrega.

## Requisitos Previos

* **Git** instalado.
* **Windows 10/11** con virtualización habilitada *(para equipos con 8 GB o 16 GB de RAM; si tu computador tiene 4 GB de RAM, no instales Docker y sigue la guía en `CONEXION_REMOTA.md`)*.
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

El archivo `docker-compose.yml` junto con el `Dockerfile` levantan automáticamente dos servicios conectados entre sí:
* **`oracle-lehz`:** Base de datos Oracle Database Free (`FREEPDB1`) en el puerto `1521`.
* **Servidor Web PHP 8 + OCI8:** Interfaz web del sistema disponible en `http://localhost:8080` (o el puerto configurado en `docker-compose.yml`).

1. Clonar el proyecto y entrar a la carpeta:
   ```powershell
   git clone [https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git](https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git)
   cd PROYECTO-FINAL-BASE-DE-DATOS
   ```
   *(Si ya tienes el repositorio clonado, ejecuta `git pull` para traer los últimos cambios).*

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
3. Hacer clic en el **ícono morado de SQL Developer** en la barra izquierda, presionar **`+`** (*Nueva conexión*) e ingresar:
   * **Nombre de conexión:** `LEHZ_Docker`
   * **Tipo de Conexión:** `Esencial`
   * **Nombre de host:** `localhost`
   * **Puerto:** `1521`
   * **Tipo:** `Nombre de servicio`
   * **Nombre de servicio:** `FREEPDB1`
   * **Nombre de Usuario:** `LEHZ`
   * **Contraseña:** `Lehz1234` *(marcar Guardar Contraseña)*
4. Presionar **Probar** y luego **Establecer conexión**.
5. Ejecutar en orden los scripts de la carpeta `database/` asociados a `LEHZ_Docker` (`01_tablas` → `02_secuencias` → `03_seguridad` → `04_triggers` → `05_mantenedores` → `06_gestores` → `07_reportes` → `08_datos_prueba`).

---

## 4. Acceso a la Aplicación Web

Una vez levantados los contenedores y cargados los scripts PL/SQL:

1. Abrir el navegador e ingresar a **`http://localhost:8080`** (si el puerto configurado en `docker-compose.yml` es `8000` u `80`, usar ese puerto).
2. Iniciar sesión con las credenciales creadas en `database/03_seguridad/` (por ejemplo `admin`).

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
├── .vscode/               # Extensiones recomendadas de VS Code
├── app/                   # Capa cliente PHP + OCI8 (interfaz y conexión a Oracle)
├── database/              # Scripts Oracle PL/SQL (prefijo LEHZ_)
│   ├── 01_tablas/         # Drops y creación de tablas base
│   ├── 02_secuencias/     # Secuencias para llaves primarias
│   ├── 03_seguridad/      # Usuarios, roles y autenticación
│   ├── 04_triggers/       # Disparadores de monitoreo y validación
│   ├── 05_mantenedores/   # 10 CRUDs con PA, funciones y cursores
│   ├── 06_gestores/       # 5 módulos transaccionales
│   ├── 07_reportes/       # 3 consultas estratégicas para dashboards
│   └── 08_datos_prueba/   # Carga de datos reales para demostración
├── docs/                  # Diagrama 3FN, presentación PPT y video demo
├── CONEXION_REMOTA.md     # Guía de conexión remota vía Tailscale
├── Dockerfile             # Construcción del contenedor PHP 8 + extensión OCI8
├── docker-compose.yml     # Orquestación de contenedores (Oracle + Web PHP)
└── README.md              # Guía de instalación, despliegue y flujo Git
```