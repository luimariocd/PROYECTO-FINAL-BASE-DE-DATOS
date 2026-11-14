# Sistema de Gestión Integral de Transporte Público Regional (INF324)

Repositorio oficial del Proyecto Final de Base de Datos (UCM). Incluye la arquitectura de base de datos Oracle, objetos PL/SQL, capa de aplicación y documentación de entrega.

## Requisitos Previos (Entorno Local)

* **Git** instalado.
* **Docker Desktop** instalado y ejecutándose con motor **WSL 2** *(recomendado para equipos con 8 GB o 16 GB de RAM; si tu equipo tiene 4 GB de RAM, sigue la guía en `CONEXION_REMOTA.md`)*.
* **Visual Studio Code** con la extensión **Oracle SQL Developer for VSCode** (*Oracle Corporation*).

---

## 1. Clonar el Repositorio y Levantar Oracle con Docker

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

## 2. Conectar Visual Studio Code a Oracle

1. Abrir el proyecto en **Visual Studio Code**.
2. Hacer clic en el ícono de **SQL Developer** en la barra izquierda y presionar **`+`** (*Nueva conexión*).
3. Ingresar las credenciales del contenedor local:
   * **Nombre de conexión:** `LEHZ_Docker`
   * **Tipo de Conexión:** `Esencial`
   * **Nombre de host:** `localhost`
   * **Puerto:** `1521`
   * **Tipo:** `Nombre de servicio`
   * **Nombre de servicio:** `FREEPDB1`
   * **Nombre de Usuario:** `LEHZ`
   * **Contraseña:** `Lehz1234` *(marcar Guardar Contraseña)*
4. Presionar **Probar** y luego **Establecer conexión**.
5. Desplegar `LEHZ_Docker > Tablas` para verificar que las 17 tablas `LEHZ_` estén creadas.

---

## 3. Comandos Útiles de Docker

* **Detener Oracle** (para liberar RAM sin borrar tus datos):
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

## 4. Estructura del Repositorio

```text
PROYECTO-FINAL-BASE-DE-DATOS/
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
├── README.md              # Guía de instalación local con Docker
└── docker-compose.yml     # Configuración del contenedor Oracle
```