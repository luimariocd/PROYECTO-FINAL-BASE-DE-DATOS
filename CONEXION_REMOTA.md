# Conexión Remota a la Base de Datos Oracle (Servidor Principal)

Guía para conectarse desde Visual Studio Code a la instancia de Oracle que corre en el computador servidor del equipo, sin necesidad de instalar Docker ni máquinas virtuales localmente.

## 1. Configuración única en el PC Servidor (quien aloja Docker)

1. Verificar que **Docker Desktop** esté abierto y el contenedor `oracle-lehz` esté activo:
   ```powershell
   docker ps
   ```
2. Abrir **PowerShell como Administrador** y habilitar el puerto `1521` en el Firewall de Windows (solo se hace una vez):
   ```powershell
   New-NetFirewallRule -DisplayName "Oracle Docker 1521" -Direction Inbound -LocalPort 1521 -Protocol TCP -Action Allow
   ```
3. Tener **Tailscale** abierto y compartir la dirección IP privada asignada al equipo (formato `100.x.y.z`).

---

## 2. Pasos para conectarse como Cliente

1. **Liberar memoria RAM:** Mantener cerrado Docker Desktop o cualquier máquina virtual en tu computador.
2. **Instalar Tailscale:** Descargar e instalar Tailscale para Windows, iniciar sesión en la red privada del equipo y verificar que el PC servidor aparezca en la lista junto con su IP (`100.x.y.z`).
3. **Instalar extensión en VS Code:** Abrir Visual Studio Code, ir a Extensiones (`Ctrl + Shift + X`) e instalar **Oracle SQL Developer for VSCode** (publicada por *Oracle Corporation*).
4. **Configurar la conexión:**
   * Abrir el ícono de **SQL Developer** en la barra lateral izquierda y hacer clic en **`+`** (*Nueva conexión*).
   * Completar los datos exactos:
     * **Nombre de conexión:** `LEHZ_Remoto`
     * **Tipo de Conexión:** `Esencial`
     * **Nombre de host:** `<IP_TAILSCALE_DEL_SERVIDOR>` *(ej. `100.x.y.z`)*
     * **Puerto:** `1521`
     * **Tipo:** `Nombre de servicio`
     * **Nombre de servicio:** `FREEPDB1`
     * **Nombre de Usuario:** `LEHZ`
     * **Contraseña:** `Lehz1234` *(marcar Guardar Contraseña)*
   * Hacer clic en **Probar** y luego en **Establecer conexión**.
5. **Verificar tablas:** Desplegar `LEHZ_Remoto > Tablas` en el panel izquierdo para comprobar que aparecen las 17 tablas `LEHZ_`.

---

## 3. Flujo de trabajo con Git

* Antes de programar, descargar los últimos cambios del repositorio:
  ```powershell
  git pull
  ```
* Guardar los scripts `.sql` en su carpeta correspondiente dentro de `database/` y subir los cambios:
  ```powershell
  git add .
  git commit -m "Agrega scripts SQL del modulo"
  git push
  ```