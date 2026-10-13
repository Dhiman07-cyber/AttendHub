# AttendHub — Cloud Deployment, Docker & Release Build Guide

This document covers deploying the **AttendHub** FastAPI backend to **Render**, configuring **Supabase PostgreSQL 17**, running containerized environments via **Docker Compose**, and building the **Flutter** Android APK and Web clients.

---

## 1. Production Deployment Topology

```mermaid
flowchart LR
    subgraph Clients["Student Devices"]
        APK["Android App (APK)"]
        WEB["Flutter Web Client"]
    end

    subgraph Render["Render Cloud (Web Service)"]
        API["FastAPI + Uvicorn\n(Python 3.11)"]
        HC["/health & /api/v1/health\nKeep-Alive Probe"]
    end

    subgraph Supabase["Supabase Cloud"]
        PGB["PgBouncer Pooler / Direct PG 17"]
        REST["Supabase REST Gateway\n(/rest/v1/)"]
    end

    subgraph Monitor["External Cron / Uptime Monitor"]
        CRON["Cron-job.org / UptimeRobot\n(Every 5–10 mins)"]
    end

    APK -- "HTTPS /api/v1" --> API
    WEB -- "HTTPS /api/v1" --> API
    CRON -- "GET / HEAD /health" --> HC
    API -- "asyncpg (TLS)" --> PGB
    HC -- "SELECT COUNT(id) FROM users" --> PGB
    HC -- "apikey ping" --> REST
```

---

## 2. Supabase PostgreSQL Setup

### 2.1 Provisioning the Schema
1. Open the **Supabase Dashboard** for your project (`[YOUR-PROJECT-REF]` or your custom instance).
2. Navigate to **SQL Editor** $\to$ **New Query**.
3. Paste the full contents of [`supabase/schema.sql`](../supabase/schema.sql) and click **Run**.
4. Verify that all 9 tables (`users`, `academic_profiles`, `semesters`, `subjects`, `timetable_entries`, `class_sessions`, `holidays`, `attendance_records`, `attendance_audit_logs`), indexes, RLS policies, and audit triggers are created.

### 2.2 Connection String & PgBouncer Compatibility
- AttendHub uses `sqlalchemy.ext.asyncio` with the `asyncpg` driver.
- In [`backend/app/core/config.py`](../backend/app/core/config.py), any `postgres://` or `postgresql://` connection string is automatically normalized to `postgresql+asyncpg://`.
- In [`backend/app/db/session.py`](../backend/app/db/session.py), the engine is configured with:
  - `pool_pre_ping=True`
  - `pool_recycle=300`
  - `connect_args={"statement_cache_size": 0, "command_timeout": 60}`
  - Setting `statement_cache_size=0` ensures full compatibility with Supabase's PgBouncer Transaction Pooler (port `6543`) as well as Direct Connections (port `5432`).

---

## 3. Render Backend Deployment

The repository includes an Infrastructure-as-Code blueprint in [`render.yaml`](../render.yaml) as well as [`backend/Procfile`](../backend/Procfile) and [`backend/runtime.txt`](../backend/runtime.txt).

### 3.1 Deploying via Render Blueprint (`render.yaml`)
1. Push your repository to GitHub.
2. In the **Render Dashboard**, click **New +** $\to$ **Blueprint** and connect the repository.
3. Render automatically detects [`render.yaml`](../render.yaml) with:
   - **Root Directory**: `backend`
   - **Runtime**: Python (`3.11.9`)
   - **Build Command**: `pip install --upgrade pip && pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path**: `/health`

### 3.2 Environment Variables on Render

| Variable | Example / Default | Description |
|---|---|---|
| `PYTHON_VERSION` | `3.11.9` | Python runtime version on Render. |
| `DATABASE_URL` | `postgresql+asyncpg://postgres:[PASS]@db.[REF].supabase.co:5432/postgres` | Supabase PostgreSQL connection URL (mark as secret / `sync: false`). |
| `SUPABASE_URL` | `https://[YOUR-PROJECT-REF].supabase.co` | Supabase project URL used by `/health` keep-alive ping. |
| `SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_...` | Supabase anon/publishable key for REST gateway ping. |
| `JWT_SECRET` | *(Auto-generated 256-bit secret)* | Signing secret for JWT access tokens. |
| `REFRESH_TOKEN_SECRET` | *(Auto-generated 256-bit secret)* | Separate signing secret for JWT refresh tokens. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `10080` (7 days) | Access token lifetime in minutes (`60` locally, `10080` on mobile/Render). |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `60` | Refresh token lifetime in days. |
| `CORS_ORIGINS` | `["*"]` | Allowed CORS origins (JSON list or comma-separated URLs). |
| `LOCAL_STORAGE_DIR` | `/tmp/storage_uploads` | Ephemeral scratch path on Render container filesystem. |

---

## 4. Keep-Alive & Health Check Architecture (`/health`)

Free-tier cloud services (Render free web services and Supabase free-tier databases) can spin down after 15 minutes of inactivity or pause after 7 days without API/DB traffic.

AttendHub provides a dual-purpose health check at both `GET /health` (and `HEAD /health`) and `GET /api/v1/health`:

1. **PostgreSQL Active Query**: Executes `SELECT COUNT(id) FROM users` (with fallback to `SELECT 1`) over the SQLAlchemy async pool to register genuine database read activity.
2. **Supabase REST Gateway Ping**: Sends an asynchronous HTTP request to `${SUPABASE_URL}/rest/v1/` with the `apikey` header so Supabase's API gateway records active project traffic.

**Sample Response (`200 OK`):**
```json
{
  "status": "healthy",
  "service": "AttendiFy Backend",
  "version": "1.0.0",
  "database": "connected",
  "supabase_ping": "ok"
}
```

> **Tip**: Configure an external uptime monitor (such as UptimeRobot or Cron-job.org) to ping `https://<your-render-service>.onrender.com/health` every 5 to 10 minutes using `GET` or `HEAD`.

---

## 5. Docker & Docker Compose Deployment

### 5.1 Multi-Stage Production Dockerfile
[`backend/Dockerfile`](../backend/Dockerfile) uses a two-stage build based on `python:3.11-slim`:
- **Builder Stage**: Installs `gcc` and `libpq-dev`, compiles Python wheels into `/install`.
- **Production Stage**: Copies pre-built wheels, creates an unprivileged `attendhub` system user, sets up `/app/storage_uploads`, exposes port `8000`, and runs Uvicorn with 2 workers.

### 5.2 Running with Docker Compose
From the repository root:
```bash
docker compose up -d --build
```
Check container logs and health:
```bash
docker compose ps
docker compose logs -f backend
curl http://localhost:8000/health
```

To stop and remove containers:
```bash
docker compose down
```

---

## 6. Flutter Mobile & Web Release Builds

### 6.1 Backend URL Resolution in Mobile
Defined in [`mobile/lib/core/network/api_endpoints.dart`](../mobile/lib/core/network/api_endpoints.dart):
1. **Runtime Override (Highest Priority)**: If the user configures a custom Server URL inside the app (via the **Server URL** gear button on the top-right of the Login/Sign-Up screen or in **Settings**), `LocalStorage` persists it and `ApiClient` routes all requests to that URL.
2. **Compile-Time `--dart-define`**: If `API_BASE_URL` is provided at build time, `ApiEndpoints.baseUrl` normalizes and uses it (automatically appending `/api/v1` if omitted).
3. **Platform Default**:
   - **Android / iOS / Desktop (`!kIsWeb`)**: Defaults to the production Render deployment (`https://attendify-li14.onrender.com/api/v1`).
   - **Web (`kIsWeb`)**: Defaults to `http://127.0.0.1:8000/api/v1`.

### 6.2 Building the Android Release APK
```bash
cd mobile

# Fetch packages
flutter pub get

# Build release APK with default Render backend
flutter build apk --release

# Or build release APK with a custom backend URL
flutter build apk --release --dart-define=API_BASE_URL=https://your-service.onrender.com/api/v1
```
The compiled APK is output to:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

### 6.3 Building for Flutter Web
```bash
cd mobile

flutter build web --release --dart-define=API_BASE_URL=https://your-service.onrender.com/api/v1
```
The static web bundle is generated in `mobile/build/web/` and can be hosted on Vercel, Netlify, Cloudflare Pages, Firebase Hosting, or Render Static Sites.
