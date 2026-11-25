# Aplicación RutaGestión

Interfaz web PHP para el Sistema de Gestión Integral de Transporte Público Regional.

## Versión actual

La interfaz usa **AdminLTE 4 + Bootstrap 5** y se sirve desde `app/public`. Incluye:

- `public/adminlte/`: assets de AdminLTE 4 (CSS/JS) incluidos en el repositorio, sin dependencia de CDN.
- `public/assets/css/app.css` y `public/assets/js/app.js`: tema claro/oscuro/automático, gráficos de reportes, autocompletado y formatos de teléfono/RUT.
- `views/`: vistas migradas (login, dashboard, mantenedores, gestores y reportes con gráficos).

Toda la validación, normalización y lógica de negocio permanece en Oracle; PHP solo muestra y envía datos a los procedimientos almacenados.

## Inicio local (sin Docker)

Desde la raíz del repositorio:

```powershell
php -S localhost:8000 -t app/public
```

Luego abre `http://localhost:8000`.

## Forma recomendada (Docker)

```powershell
docker compose up -d --build
```

La aplicación queda en `http://localhost:8000`. Si solo actualizaste archivos de `app/`, basta con:

```powershell
docker compose restart web
```

Consulta `../README.md` para la guía completa de instalación y actualización desde la versión anterior.
