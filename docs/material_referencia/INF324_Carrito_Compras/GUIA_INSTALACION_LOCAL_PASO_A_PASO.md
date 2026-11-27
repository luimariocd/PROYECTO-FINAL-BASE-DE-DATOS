# Guía Definitiva de Instalación Local: Oracle Database + SQL Developer + PHP + OCI8
**Asignatura:** INF324 - Base de Datos | **Carrera:** Ingeniería Civil Informática (UCM)  
**Objetivo:** Configurar el entorno de desarrollo 100% local, offline y sin dependencias externas para el Proyecto Final (ABPro).

---

## 📋 Resumen de Componentes a Instalar

| Componente | Qué es | ¿Dónde se descarga? |
| :--- | :--- | :--- |
| **1. Oracle Database 21c XE** | El motor de base de datos (DBMS) | Portal Oficial de Oracle (Gratuito) |
| **2. Oracle SQL Developer** | La interfaz gráfica para gestionar la BD | Portal Oficial de Oracle (Gratuito) |
| **3. PHP 8.2 / 8.3 (x64)** | El entorno de ejecución backend | Sitio Oficial de PHP para Windows |
| **4. Oracle Instant Client** | Las librerías DLL para conectar PHP con Oracle | Portal Oficial de Oracle (Gratuito) |

---

## 🛠️ PASO 1: Descarga e Instalación de Oracle Database 21c XE

Este es el servidor de base de datos que correrá en segundo plano en tu computador.

### 1.1. Descarga
* **Enlace oficial directo:**  
  👉 [https://www.oracle.com/database/technologies/xe-downloads.html](https://www.oracle.com/database/technologies/xe-downloads.html)
* Descarga el archivo: **Oracle Database 21c Express Edition for Windows x64** (pesa aproximadamente 2.2 GB).  
  *(Requiere crearse una cuenta gratuita en Oracle si no tienes una)*.

### 1.2. Proceso de Instalación en Windows
1. Descomprime el archivo `.zip` descargado.
2. Entra a la carpeta descomprimida y ejecuta como Administrador el archivo **`setup.exe`**.
3. Acepta los términos de licencia y presiona **Next**.
4. **Ruta de instalación:** Deja la ruta por defecto (`C:\app\...` o `C:\oracle\...`).
5. **Paso fundamental - Contraseña del Administrador:**
   * El asistente te pedirá definir una contraseña para las cuentas maestras: `SYS`, `SYSTEM` y `PDBADMIN`.
   * **RECOMENDACIÓN:** Escribe una contraseña simple que recuerdes fácilmente, por ejemplo:  
     `oracle` o `Oracle123*`
   * *¡Anótala! Sin esta clave no podrás entrar como administrador.*
6. Haz clic en **Install**. La instalación puede tardar entre 10 y 25 minutos dependiendo de tu PC.
7. Al finalizar, la pantalla mostrará los datos de conexión:
   * **Host:** `localhost`
   * **Puerto:** `1521`
   * **Nombre de la Pluggable Database (Servicio):** `XEPDB1`

---

## 🖥️ PASO 2: Instalación de Oracle SQL Developer (GUI)

Es la herramienta gráfica para escribir consultas, compilar procedimientos y ver las tablas.

### 2.1. Descarga
* **Enlace oficial directo:**  
  👉 [https://www.oracle.com/database/sqldeveloper/technologies/download/](https://www.oracle.com/database/sqldeveloper/technologies/download/)
* Descarga la opción: **Windows 64-bit with JDK 17 included** (pesa aprox. 450 MB).  
  *(Esta versión ya incluye Java JDK integrado, por lo que no necesitas instalar Java por separado)*.

### 2.2. Instalación y Ejecución
1. Descomprime el archivo `.zip` en la ruta que prefieras (ejemplo: `C:\sqldeveloper`).
2. Entra a la carpeta y ejecuta **`sqldeveloper.exe`**. *(Puedes crearle un acceso directo en tu Escritorio)*.

### 2.3. Probar la Conexión de Administrador
1. Abre SQL Developer y presiona el botón verde **`+`** (Nueva Conexión) en el panel izquierdo.
2. Configura los siguientes campos:
   * **Nombre de la conexión:** `Oracle_System_Local`
   * **Usuario:** `system`
   * **Contraseña:** *(La que definiste en el Paso 1, ej: `oracle`)*
   * **Rol:** `default`
   * **Tipo de conexión:** `Básico`
   * **Nombre de host:** `localhost`
   * **Puerto:** `1521`
   * **Nombre del servicio:** `XEPDB1` (o marca SID si usas `xe`)
3. Presiona **Probar**. Si el estado abajo a la izquierda dice **Correcto**, haz clic en **Guardar** y luego en **Conectar**.

---

## 🐘 PASO 3: Descarga e Instalación de PHP Nativo en Windows

### 3.1. Descarga
* **Enlace oficial directo:**  
  👉 [https://windows.php.net/download/](https://windows.php.net/download/)
* En la sección de PHP 8.2 o PHP 8.3, busca la versión:  
  **VS16 x64 Thread Safe (ZIP)**  
  *(Asegúrate de descargar el archivo ZIP, no el debug pack)*.

### 3.2. Instalación
1. Ve al disco local `C:\` y crea una carpeta llamada **`php`**.
2. Descomprime todo el contenido del ZIP dentro de:
   ```text
   C:\php\
   ```
   *(Verifica que al abrir `C:\php\` veas de inmediato archivos como `php.exe`, `php.ini-development` y la carpeta `ext`)*.

---

## 🌉 PASO 4: Descarga de Oracle Instant Client (El Conector)

PHP necesita las librerías oficiales de Oracle (`oci.dll`) para poder hablar con la base de datos a través del driver `oci8`.

### 4.1. Descarga
* **Enlace oficial directo:**  
  👉 [https://www.oracle.com/database/technologies/instant-client/win-x64-64-downloads.html](https://www.oracle.com/database/technologies/instant-client/win-x64-64-downloads.html)
* Descarga el paquete: **Basic Package (ZIP)** (versión 19.x o 21.x de 64 bits).

### 4.2. Extracción
1. Descomprime el archivo ZIP en el disco local `C:\` con el nombre:
   ```text
   C:\instantclient_19_24\
   ```
   *(O el número de versión que se descargue, por ejemplo `C:\instantclient_21_13`)*.

---

## ⚙️ PASO 5: Configurar las Variables de Entorno de Windows (PATH)

Este paso es indispensable para que Windows reconozca tanto a `php` como a las librerías de Oracle desde cualquier consola.

1. En tu teclado presiona la tecla **Windows** y escribe: `variables de entorno`.
2. Haz clic en **"Editar las variables de entorno del sistema"**.
3. Se abrirá una ventana de Propiedades del sistema; haz clic abajo a la derecha en el botón **"Variables de entorno..."**.
4. En el recuadro inferior titulado **"Variables del sistema"**, busca la variable llamada **`Path`** y hazle doble clic (o pulsa *Editar*).
5. Haz clic en el botón **"Nuevo"** y agrega la ruta de PHP:
   ```text
   C:\php
   ```
6. Haz clic nuevamente en **"Nuevo"** y agrega la ruta del Instant Client:
   ```text
   C:\instantclient_19_24
   ```
7. Presiona **Aceptar** en todas las ventanas para guardar los cambios.

---

## 📝 PASO 6: Configurar `php.ini` para Habilitar OCI8

1. Ve a la carpeta `C:\php\`.
2. Busca el archivo `php.ini-development`.
3. Hazle una copia en la misma carpeta y renómbralo exactamente a:
   ```text
   php.ini
   ```
4. Abre `php.ini` con el Bloc de Notas o VS Code.
5. Busca y modifica las siguientes directivas quitando el punto y coma (`;`) inicial:

   * **1. Habilitar la carpeta de extensiones (aprox. línea 750):**
     ```ini
     extension_dir = "ext"
     ```

   * **2. Habilitar el conector con Oracle (aprox. línea 900):**
     ```ini
     extension=oci8_19
     extension=pdo_oci
     ```
     *(Si la línea dice solo `extension=oci8`, descomenta esa)*.

6. Guarda el archivo (`Ctrl + G` o Archivo -> Guardar) y ciérralo.

---

## ✅ PASO 7: Verificación en Consola

Abre una **NUEVA ventana de PowerShell o Terminal** (es fundamental que sea nueva para que tome el PATH actualizado) y ejecuta:

1. **Comprobar PHP:**
   ```powershell
   php -v
   ```
   *(Debe mostrar: `PHP 8.x.x (cli) ... (64bit)`)*.

2. **Comprobar la extensión OCI8:**
   ```powershell
   php -m | findstr oci8
   ```
   *(Debe responder: `oci8`. Si aparece la palabra `oci8`, **PHP y Oracle ya están enlazados exitosamente**)*.

---

## 🗄️ PASO 8: Crear el Usuario del Proyecto y Cargar los Datos

1. Abre **Oracle SQL Developer** y entra a la conexión de administrador `Oracle_System_Local`.
2. Abre una hoja de trabajo SQL y ejecuta el siguiente script para crear el usuario de trabajo del proyecto:
   ```sql
   -- Crear usuario del proyecto
   CREATE USER PROYECTO_BD IDENTIFIED BY oracle;

   -- Asignar permisos necesarios
   GRANT CONNECT, RESOURCE, DBA TO PROYECTO_BD;
   GRANT UNLIMITED TABLESPACE TO PROYECTO_BD;
   ```
3. En el panel izquierdo de SQL Developer, crea una **Nueva Conexión (`+`)** para este usuario:
   * **Nombre:** `Proyecto_INF324`
   * **Usuario:** `PROYECTO_BD`
   * **Contraseña:** `oracle`
   * **Host:** `localhost` | **Puerto:** `1521` | **Servicio:** `XEPDB1`
4. Conéctate a `Proyecto_INF324` y abre y ejecuta los scripts de la carpeta `sql/` en este orden:
   1. `01_esquema_3fn.sql`
   2. `02_secuencias.sql`
   3. `03_funciones.sql`
   4. `04_procedimientos.sql`
   5. `05_triggers.sql`
   6. `06_datos_iniciales.sql`

---

## 🚀 PASO 9: Levantar y Usar la Aplicación Web

1. Abre PowerShell o CMD y navega hasta la carpeta `app` del proyecto:
   ```powershell
   cd "C:\Users\leone\Desktop\Contenido Base De Datos\Unidad 3\Ejemplo_Carrito_Compras\app"
   ```
2. Inicia el servidor embebido de PHP:
   ```powershell
   php -S localhost:8000
   ```
3. Abre tu navegador web (Chrome, Edge, etc.) en:
   👉 **`http://localhost:8000`**

¡Listo! Ya tienes el sistema funcionando en local, conectado a Oracle mediante procedimientos almacenados, cursores y triggers.

---

## 🆘 Solución a Problemas Frecuentes

* **Error: `ORA-12541: TNS:no listener` o la base de datos no conecta:**
  * En Windows, presiona `Windows + R`, escribe `services.msc` y pulsa Enter.
  * Busca los servicios llamados:
    - `OracleServiceXE`
    - `OracleOraDB21Home1TNSListener` (o `OracleXETNSListener`)
  * Ambos deben estar en estado **"En ejecución"** (Running). Si no lo están, hazles clic derecho y presiona *Iniciar*.

* **Error: `Call to undefined function oci_connect()` en el navegador:**
  * No se descomentó `extension_dir = "ext"` o `extension=oci8_19` en `C:\php\php.ini`.
  * La ruta de `instantclient` no quedó bien escrita en el PATH. Recuerda cerrar la terminal y abrir una nueva tras editar el PATH.

