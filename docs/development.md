# AttendHub — Local Development Guide

This guide describes how to run and develop the AttendHub backend and mobile client locally.

---

## 1. Prerequisites

- **Python**: 3.11+ (Python 3.14 tested and supported)
- **Flutter**: 3.19+ / Dart 3.3+
- **Docker**: (Optional) For containerized PostgreSQL deployment

---

## 2. Backend Setup (FastAPI)

### Step 1: Navigate to the Backend Directory
```bash
cd backend
```

### Step 2: Create and Activate a Virtual Environment
**On Windows:**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
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
Copy the environment template:
```bash
cp ../.env.example .env
```

Configure environment variables in `.env`:
```ini
DATABASE_URL=postgresql+asyncpg://postgres.<project-ref>:<db-password>@aws-0-ap-south-1.pooler.supabase.com:6543/postgres
SECRET_KEY=your-secure-backend-jwt-secret-here
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30
```

> **Database Rule**: AttendHub connects strictly to **Supabase-hosted PostgreSQL** (`postgresql+asyncpg`). SQLite has been decommissioned to maintain exact production parity, transactional atomicity, and RLS integrity. Do not reintroduce local SQLite fallbacks.

### Step 5: Start the Development Server
```bash
uvicorn app.main:app --reload --port 8000
```

The backend is now accessible:
- API Root: `http://localhost:8000/`
- Interactive Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

## 3. Mobile Setup (Flutter)

### Step 1: Navigate to the Mobile Directory
```bash
cd mobile
```

### Step 2: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 3: Run the Application
**Run on connected Android/iOS device or emulator:**
```bash
flutter run
```

**Run on Chrome (Web):**
```bash
flutter run -d chrome
```

**Run on Windows Desktop:**
```bash
flutter run -d windows
```

---

## 4. Running Automated Tests

### Backend Test Suite
AttendHub includes comprehensive domain tests for all attendance formulas and API integration tests:
```bash
cd backend
pytest
```

To run with verbose output:
```bash
pytest -v
```

### Flutter Test Suite
```bash
cd mobile
flutter test
```

---

## 5. Architectural & Code Conventions

1. **Product Name Integrity**: Never use or mention the legacy name anywhere in code, comments, or documentation. The product is strictly **AttendHub**.
2. **Deterministic Arithmetic Only**: Never use LLMs or external AI for attendance calculations. Keep all arithmetic in `app/calculations/attendance_engine.py`.
3. **No Percentage Averaging**: Never average percentages to calculate overall semester attendance. Always aggregate raw attended and conducted totals:
   ```python
   total_attended / total_conducted * 100
   ```
4. **Feature-First Architecture**: Group Flutter code by feature (`features/dashboard`, `features/today`, etc.) and avoid placing business logic inside widgets.

---

## 6. Engineering Skill System & Agent Preflight

AttendHub enforces a strict pre-edit preflight protocol for AI coding assistants and contributors. The project maintains a task-relevant skill suite under `.agents/skills/` and persistent rules in `AGENTS.md` and `.agents/rules/engineering-standards.md`.

For a full inventory of installed skills, their trigger use cases, and authority levels, see:
- [`docs/agent-skills.md`](agent-skills.md)

### Pre-Edit Preflight Workflow:
1. **Understand & Identify Invariants**: Review `context.md`, `design.md`, 75% defaults, semester and user isolation.
2. **Inspect Code**: Inspect active implementation before proposing changes.
3. **Load Specialist Skills**: Activate Flutter, Dart, Superpowers process, OWASP security, or FastAPI skills.
4. **Authoritative Guidance**: Consult current official framework docs.
5. **Plan & Implement**: Form small safe plans; preserve database constraints, transaction boundaries, and mathematical determinism.
6. **Test & Verify**: Run `pytest -v` and `flutter test`; independently inspect the diff before completion.

