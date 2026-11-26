# Conexión Remota al Proyecto (Oracle + Web)

Guía para conectarse al proyecto que corre en el **PC servidor** del equipo, sin instalar Docker ni Oracle localmente.

> ¿Tienes una laptop de **4 GB**? Empieza por **`GUIA_LAPTOP_4GB.md`**. Ahí está el paso a paso pensado para esa memoria: usar solo el navegador y, opcionalmente, VS Code para SQL.

El servidor expone dos cosas por Tailscale:

| Servicio | Puerto | Uso |
|---|---|---|
| Web (AdminLTE) | `8000` | Usar el sistema desde el navegador |
| Oracle (`FREEPDB1`) | interno `1521` | Solo dentro de Docker; **no publicado por Tailscale** |

La aplicación web ya se conecta a Oracle internamente (`DB_HOST=oracle-db`), así que para **usar el sistema** solo necesitas el navegador.

---

## 1. Configuración única en el PC servidor (NO en la laptop cliente)

1. Verificar que Docker esté corriendo:

   ```powershell
   docker compose up -d
   docker ps
   ```

   Deben aparecer `oracle-lehz` y `lehz-web`.

2. Abrir **PowerShell como Administrador** y permitir solo el puerto web (solo una vez):

   ```powershell
   New-NetFirewallRule -DisplayName "LEHZ Web 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
   ```
   > No abras el `1521`: Oracle escucha solo en la red interna de Docker.

3. Tener **Tailscale** abierto, iniciado sesión en la red del equipo y compartir la IP privada (`100.x.y.z`):

   ```powershell
   tailscale ip -4
   ```

4. Si solo se actualizó la interfaz, **no vuelvas a cargar los scripts SQL**. Si es una instalación nueva, ejecuta `database/` en orden 01→08 (incluye `01_tablas/03_cat_chile.sql`).

---

## 2. Cliente: usar la web (lo recomendado para equipos de baja memoria)

1. Instalar **Tailscale** e iniciar sesión en la misma red que el servidor.
2. Verificar conectividad:

   ```powershell
   ping 100.x.y.z
   ```

3. Abrir en el navegador:

   ```text
   http://100.x.y.z:8000
   ```

4. Iniciar sesión (ejemplo `admin` / `Admin1234`) y presionar **Ctrl + F5** para ver la interfaz nueva de AdminLTE con los gráficos de recaudación.

No necesitas clonar el repo ni instalar extensiones para esto.

---

## 3. Cliente: conectar VS Code a Oracle (opcional)

Solo si vas a editar o ejecutar scripts `.sql`.

1. Clonar o actualizar el repositorio:

   ```powershell
   git clone https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git
   cd PROYECTO-FINAL-BASE-DE-DATOS
   git fetch origin
   git checkout Denunce
   git pull origin Denunce
   ```

   *(Si el equipo ya fusionó en `main`, usa `main` en lugar de `Denunce`.)*

2. Instalar en VS Code **`Oracle SQL Developer for VSCode`** (publicada por **Oracle Corporation**). Evita la extensión antigua *Oracle Developer Tools*.

3. Como **`1521` no está publicado**, conecta por **Escritorio Remoto (RDP)** al servidor y ejecuta los scripts dentro de él:
   ```powershell
   Get-Content .\database\04_migracion\08_verificacion.sql | docker exec -i oracle-lehz sqlplus -s LEHZ/Lehz1234@localhost:1521/FREEPDB1
   ```
   Si usas SQL Developer dentro de ese escritorio: host `localhost`, puerto `1521`, servicio `FREEPDB1`, usuario `LEHZ`, contraseña `Lehz1234`. Deberían aparecer las tablas `LEHZ_` y las vistas del catálogo de Chile.

> Ejecutar scripts afecta la base del servidor. Coordínalo con el equipo.

---

## 4. Si no se puede instalar Tailscale en la laptop

El servidor puede exponer solo la web con una URL temporal:

```powershell
cloudflared tunnel --url http://localhost:8000
```

o:

```powershell
ngrok http 8000
```

Comparte la URL `https://...` resultante. **No expongas el puerto `1521` públicamente.**  
Otra alternativa es usar **Escritorio Remoto (RDP)** al PC servidor.

---

## 5. Flujo de trabajo con Git

Antes de programar, descarga los cambios:

```powershell
git fetch origin
git pull origin Denunce
```

Guarda y sube tus cambios:

```powershell
git add .
git commit -m "Describe el cambio"
git push origin Denunce
```

---

## 6. Problemas comunes

| Síntoma | Solución |
|---|---|
| No abre `http://100.x.y.z:8000` | Revisar `docker ps` en el servidor y la regla de firewall para 8000. |
| `ping 100.x.y.z` falla | `tailscale status` en ambos equipos; reiniciar Tailscale si hace falta. |
| `ORA-12541` / `ORA-12514` | Esperar `DATABASE IS READY TO USE!` y confirmar `FREEPDB1` + puerto 1521. |
| Web se ve antigua | **Ctrl + F5** o incógnito. |
| Laptop de 4 GB se congela | Usar solo navegador; no instalar Docker/WSL; cerrar VS Code. |

Para el paso a paso completo en equipo de baja memoria: **`GUIA_LAPTOP_4GB.md`**.
