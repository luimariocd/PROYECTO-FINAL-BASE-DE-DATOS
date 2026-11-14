# Sistema de Gestión Integral de Transporte Público Regional (INF324)

Repositorio oficial del Proyecto Final de Base de Datos (UCM). Incluye la arquitectura de base de datos Oracle, objetos PL/SQL, capa de aplicación y documentación de entrega.

## Requisitos Previos

* **Git** instalado.
* **Windows 10/11** con virtualización habilitada *(para equipos con 8 GB o 16 GB de RAM; si tu computador tiene 4 GB de RAM, no instales Docker y sigue la guía en `CONEXION_REMOTA.md`)*.
* **Visual Studio Code** instalado.

---

## 1. Activar WSL 2 e Instalar Docker Desktop (Solo la primera vez)

Docker Desktop necesita el **Subsistema de Windows para Linux (WSL 2)** para ejecutar el contenedor de Oracle. Si nunca lo has activado en tu PC, hazlo antes de abrir Docker:

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

## 2. Clonar el Repositorio y Levantar Oracle con Docker

1. Clonar el proyecto y entrar a la carpeta:
   ```powershell
   git clone [https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git](https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git)
   cd PROYECTO-FINAL-BASE-DE-DATOS
   ```
   *(Si ya tienes el repositorio clonado, ejecuta `git pull` para traer los últimos cambios).*

2. Levantar el contenedor de Oracle en segundo plano:
   ```powershell
   docker compose up -d
   ```
   > **Nota:** La primera ejecución tardará entre 1 y 3 minutos mientras descarga la imagen de Oracle, crea el usuario `LEHZ` y ejecuta automáticamente las 17 tablas de `database/01_tablas/02_create_tables.sql`.

3. Verificar que la base de datos terminó de inicializarse:
   ```powershell
   docker logs -f oracle-lehz
   ```
   Cuando aparezca el mensaje `DATABASE IS READY TO USE!`, presiona **`Ctrl + C`** para salir de los registros.

---

## 3. Instalar la Extensión de Oracle en Visual Studio Code

1. Abrir la carpeta `PROYECTO-FINAL-BASE-DE-DATOS` en **Visual Studio Code**.
2. Si aparece un aviso abajo a la derecha recomendando instalar extensiones del repositorio, hacer clic en **Instalar**.
3. Si no aparece el aviso, abrir el panel de **Extensiones** con **`Ctrl + Shift + X`**, buscar **`Oracle SQL Developer for VSCode`** (verificar que el autor sea **Oracle Corporation** y tenga el ícono de un cilindro con un triángulo verde) y hacer clic en **Instalar**.
   > **Importante:** No instalar la extensión antigua llamada *Oracle Developer Tools*; usar únicamente **Oracle SQL Developer for VSCode**.
4. Esperar a que termine la instalación y aparezca un **ícono morado de base de datos** en la barra vertical izquierda de VS Code.

---

## 4. Conectar Visual Studio Code a Oracle

1. Hacer clic en el **ícono morado de SQL Developer** en la barra izquierda y presionar **`+`** (*Nueva conexión*).
2. Ingresar las credenciales del contenedor local:
   * **Nombre de conexión:** `LEHZ_Docker`
   * **Tipo de Conexión:** `Esencial`
   * **Nombre de host:** `localhost`
   * **Puerto:** `1521`
   * **Tipo:** `Nombre de servicio`
   * **Nombre de servicio:** `FREEPDB1`
   * **Nombre de Usuario:** `LEHZ`
   * **Contraseña:** `Lehz1234` *(marcar Guardar Contraseña)*
3. Presionar **Probar** y luego **Establecer conexión**.
4. Desplegar `LEHZ_Docker` y abrir la carpeta **Tablas** para verificar que las 17 tablas `LEHZ_` estén creadas.
5. Al abrir cualquier archivo `.sql`, hacer clic en **Ninguna conexión asociada** (esquina inferior derecha de VS Code) y seleccionar `LEHZ_Docker`.

---

## 5. Comandos Útiles de Docker

* **Detener Oracle** (para liberar entre 2 y 3 GB de RAM sin borrar tus datos):
  ```powershell
  docker stop oracle-lehz
  ```
* **Volver a encender Oracle:**
  ```powershell
  docker start oracle-lehz
  ```
* **Reconstruir la base de datos desde cero** *(elimina todos los datos y vuelve a ejecutar el DDL inicial)*:
  ```powershell
  docker compose down -v
  docker compose up -d
  ```

---

## 6. Estructura del Repositorio

```text
PROYECTO-FINAL-BASE-DE-DATOS/
├── .vscode/               # Extensiones recomendadas de VS Code
├── app/                   # Capa cliente (interfaz y conexión a Oracle)
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
├── README.md              # Guía de instalación local con WSL 2 y Docker
└── docker-compose.yml     # Configuración del contenedor Oracle
```