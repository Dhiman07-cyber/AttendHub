# AttendHub — Local Development Guide

This guide describes how to configure, run, and develop the **AttendHub** FastAPI backend and Flutter mobile/web client locally.

---

## 1. Prerequisites

- **Python**: `3.11+` (`3.11.9` used on Render; `3.13` / `3.14` also supported locally)
- **Flutter SDK**: `3.19+` / **Dart**: `3.3+`
- **PostgreSQL**: Cloud-hosted **Supabase PostgreSQL 17** (or containerized via Docker Compose)
- **Docker Desktop**: *(Optional)* For running the containerized backend stack

---

## 2. Backend Setup (FastAPI)

### Step 1: Navigate to the Backend Directory
```bash
cd backend
```

### Step 2: Create and Activate a Virtual Environment
**On Windows (PowerShell):**
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**On macOS / Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Environment Configuration
Copy the template inside `backend/`:
```bash
cp .env.example .env
```

Edit `backend/.env` with your Supabase PostgreSQL and JWT settings:
```ini
# Supabase PostgreSQL Connection (Cloud Hosted)
DATABASE_URL=postgresql+asyncpg://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres

# Supabase Credentials (used for /health keep-alive ping)
SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...

# Authentication & Security
JWT_SECRET=super_secret_jwt_key_change_in_production_attendhub_2026_xyz
REFRESH_TOKEN_SECRET=super_secret_refresh_jwt_key_change_in_production_attendhub_2026_abc
ACCESS_TOKEN_EXPIRE_MINUTES=10080
REFRESH_TOKEN_EXPIRE_DAYS=60

# CORS
CORS_ORIGINS=["*"]

# Ephemeral Scratch Upload Path
LOCAL_STORAGE_DIR=./storage_uploads
```

> **Database Note**: AttendHub connects via `postgresql+asyncpg` (`config.py` automatically normalizes `postgres://` or `postgresql://` prefixes). Ensure [`supabase/schema.sql`](../supabase/schema.sql) has been applied to your Supabase project.

### Step 5: Start the FastAPI Development Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verify the server is running:
- **Root Info**: `http://localhost:8000/`
- **Health Check**: `http://localhost:8000/health`
- **Interactive Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

---

## 3. Mobile & Web Client Setup (Flutter)

### Step 1: Navigate to the Mobile Directory
```bash
cd mobile
```

### Step 2: Fetch Dart/Flutter Packages
```bash
flutter pub get
```

### Step 3: Run the Client
**Run on Chrome (Web — defaults to `http://127.0.0.1:8000/api/v1`):**
```bash
flutter run -d chrome
```

**Run on Android / iOS / Windows Desktop against a Local Backend:**
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```
*(Use `http://10.0.2.2:8000/api/v1` for Android Emulator, `http://127.0.0.1:8000/api/v1` for Windows/iOS Simulator, or your LAN IP `http://192.168.x.x:8000/api/v1` for a physical phone).*

**Runtime Server URL Switcher:**
You can also switch the backend URL at runtime without rebuilding:
1. Tap the **Server URL (gear icon)** at the top-right of the **Login / Sign Up** screen (or inside **Settings**).
2. Enter your backend URL (e.g., `https://attendify-li14.onrender.com` or `http://192.168.1.5:8000`) and tap **Save**.

---

## 4. Running Automated Tests & Static Analysis

### Backend Test Suite (`pytest`)
```bash
cd backend
pytest -v
```

### Flutter Test Suite & Static Analysis
```bash
cd mobile
flutter analyze
flutter test
```

---

## 5. Architectural & Engineering Conventions

1. **Pure Deterministic Mathematics**: Keep all attendance and forecasting formulas pure and side-effect-free inside [`backend/app/calculations/attendance_engine.py`](../backend/app/calculations/attendance_engine.py) and [`insight_engine.py`](../backend/app/calculations/insight_engine.py).
2. **75.0% Default Thresholds**: `minimum_attendance` and `personal_target` must default to `75.0%` across database schemas, Pydantic models, and Flutter constants.
3. **No Percentage Averaging**: Always compute whole-semester attendance from raw sums ($\sum A / \sum C \times 100$).
4. **Clean Layer Separation**: Maintain `Presentation -> Application/State -> Domain/Calculation -> Data/ORM` without embedding database or business logic inside UI widgets.
5. **Pre-Edit Preflight**: Review [`AGENTS.md`](../AGENTS.md) and [`docs/agent-skills.md`](agent-skills.md) before modifying code.
