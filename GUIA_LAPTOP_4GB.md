# Guía para laptop de 4 GB (sin Docker ni Oracle local)

Esta guía es para el compañero que tiene una laptop entregada por el gobierno con **4 GB de RAM**.  
**No instales Docker Desktop, Oracle, WSL 2 ni máquinas virtuales en esa laptop.** El proyecto se ejecuta en un **PC servidor** del equipo y la laptop solo se conecta de forma remota.

Hay tres formas de conectarse. Usa la **Opción 1** si solo necesitas mostrar/usar el sistema; la **Opción 2** si además necesitas editar scripts SQL.

---

## Antes de empezar: qué debe tener el PC servidor (SOLO SERVIDOR, NO la laptop de 4 GB)

En el computador que sí tiene Docker (8 GB o 16 GB de RAM), ejecuta:

```powershell
cd PROYECTO-FINAL-BASE-DE-DATOS
docker compose up -d
docker ps
```

Deben aparecer los contenedores `oracle-lehz` y `lehz-web`.

Si es la primera vez, el servidor debe tener cargados los scripts SQL (`01_tablas` → `08_datos_prueba`, incluyendo `01_tablas/03_cat_chile.sql`). Si solo se actualizó la interfaz, **no vuelve a cargar la base**.

El servidor debe compartirte su **IP de Tailscale** (`100.x.y.z`). Para verla:

```powershell
tailscale ip -4
```

---

## Opción 1 (recomendada): usar el sistema solo con el navegador

Ideal para 4 GB: **no requiere clonar el repo ni instalar VS Code**.

### En el PC servidor (una sola vez)

Abrir PowerShell como Administrador y permitir los puertos:

```powershell
New-NetFirewallRule -DisplayName "LEHZ Web 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Oracle Docker 1521" -Direction Inbound -LocalPort 1521 -Protocol TCP -Action Allow
```

### En la laptop de 4 GB

1. Instalar **Tailscale** para Windows e iniciar sesión con la misma cuenta/red del equipo (`tailnet`).
2. Verificar que veas el PC servidor:
   ```powershell
   tailscale status
   ping 100.x.y.z
   ```
   *(Reemplaza `100.x.y.z` por la IP real que te dio el servidor).*
3. Abrir Microsoft Edge o Chrome y entrar a:
   ```text
   http://100.x.y.z:8000
   ```
4. Iniciar sesión con:
   - **Usuario:** `admin`
   - **Contraseña:** `Admin1234`
   *(o el usuario que tu equipo haya creado).*
5. Presionar **Ctrl + F5** para cargar la interfaz nueva (AdminLTE) y evitar caché del CSS antiguo.

Con esto ya puedes: iniciar sesión, ver el panel, usar mantenedores, gestores y los reportes con gráficos de recaudación.

> La aplicación web se conecta a Oracle **dentro del Docker del servidor** usando el nombre `oracle-db`. Por eso la laptop no necesita configurar `DB_HOST`.

---

## Opción 2: editar/ejecutar scripts SQL desde la laptop (opcional)

Solo si necesitas trabajar en los `.sql`. Es más pesado que la Opción 1, pero no requiere Docker local.

1. Clonar o actualizar el repositorio:
   ```powershell
   git clone https://github.com/luimariocd/PROYECTO-FINAL-BASE-DE-DATOS.git
   cd PROYECTO-FINAL-BASE-DE-DATOS
   git fetch origin
   git checkout Denunce
   git pull origin Denunce
   ```
   *(Cuando todo esté fusionado, usa `main` en lugar de `Denunce`.)*

2. Abrir VS Code y dejar **solo la extensión necesaria**:
   - Instalar **`Oracle SQL Developer for VSCode`** (de Oracle Corporation).
   - Desactivar extensiones pesadas que no uses.

3. Crear la conexión:
   - **Nombre:** `LEHZ_Remoto`
   - **Tipo:** `Esencial`
   - **Host:** `100.x.y.z` *(IP Tailscale del servidor)*
   - **Puerto:** `1521`
   - **Tipo:** `Nombre de servicio`
   - **Servicio:** `FREEPDB1`
   - **Usuario:** `LEHZ`
   - **Contraseña:** `Lehz1234`

4. Probar conexión y ejecutar/scripts **con coordinación del equipo**: lo que ejecutes afecta la base del servidor.

> Si la laptop se queda corta de memoria, cierra VS Code y vuelve a la Opción 1 (solo navegador).

---

## Opción 3: si no permiten instalar Tailscale en la laptop

Si el equipo no permite instalar software, pide al compañero servidor una de estas alternativas:

**A) URL temporal del sistema web (solo navegador):**

En el servidor:

```powershell
cloudflared tunnel --url http://localhost:8000
```

o:

```powershell
ngrok http 8000
```

El servidor te pasará una URL `https://...`. Abre esa URL en la laptop.  
**No expongas el puerto 1521 de Oracle a Internet**, solo el 8000 de la web.

**B) Escritorio remoto (RDP):**

Si el servidor tiene Windows Pro, conéctate por **Conexión a Escritorio Remoto** a esa máquina y trabaja allí. La laptop solo envía imagen y teclado.

---

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---|---|---|
| El navegador no abre `http://100.x.y.z:8000` | Firewall del servidor o contenedor caído | En el servidor: `docker ps` y la regla de firewall para 8000. |
| `ping 100.x.y.z` falla | Tailscale desconectado | Ejecuta `tailscale status` en ambos equipos y vuelve a iniciar sesión. |
| `ORA-12541` / `ORA-12514` desde VS Code | Oracle no está listo o el servicio es otro | En el servidor espera `DATABASE IS READY TO USE!` y confirma `FREEPDB1` / puerto `1521`. |
| La web carga pero se ve antigua | Caché del navegador | **Ctrl + F5** o ventana de incógnito. |
| La laptop se congela | Demasiados programas abiertos | Usa solo el navegador (Opción 1) y cierra Docker/WSL/VS Code. |
| La web muestra error de base de datos | Faltan scripts en el servidor | El servidor debe cargar `database/` 01→08; la laptop no puede arreglarlo. |

## No hacer en la laptop

- No instalar Docker Desktop ni WSL 2.
- No instalar Oracle local.
- No ejecutar `docker compose down -v` desde la laptop (si llega a usar Docker, borraría datos).
- No ejecutar scripts SQL sin avisar al equipo.

Para más detalle de conexión SQL, ver `CONEXION_REMOTA.md`.
