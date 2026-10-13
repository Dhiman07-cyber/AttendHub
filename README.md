# AttendHub

<p align="center">
  <strong>Track · Plan · Stay Above</strong><br>
  <em>A student-side attendance tracking and deterministic forecasting utility built with Flutter and FastAPI.</em>
</p>

---

## 🌟 Overview

**AttendHub** is an independent, student-first attendance companion engineered for fast daily recording and deterministic academic decision-making. Unlike institutional ERPs built for administrative record-keeping, AttendHub empowers students to:

1. **Understand their attendance standing in seconds.**
2. **Mark a full day's attendance in under 1 minute** with intuitive 3-state action controls (`Attended`, `Absent`, `Not Held`).
3. **Forecast future decisions accurately** using pure mathematical models that calculate exact classes needed to reach a target and maximum safe absences before dipping below minimum requirements.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile Client** | Flutter 3.x, Dart 3.x, Riverpod, Dio, Custom Vector Canvas Painters, Liquid Glassmorphism |
| **Backend API** | FastAPI, Python 3.11+ / 3.14, Pydantic v2, Uvicorn |
| **Database & ORM** | Supabase-hosted PostgreSQL 17, SQLAlchemy 2.0 Async (asyncpg), Alembic |
| **Security** | Argon2id password hashing, Cryptographic JWT tokens (Access & Refresh), CORS, User Isolation |
| **DevOps** | Docker, Docker Compose, Multi-stage Dockerfile |

---

## 📐 System Architecture

```text
┌────────────────────────────────────────────────────────┐
│             Flutter Mobile Presentation Layer          │
│  (Warm Light Theme · Liquid Glass · Riverpod · Canvas) │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST (JSON)
┌───────────────────────────▼────────────────────────────┐
│                  FastAPI Application Layer             │
│   (Auth, Routers, Dependency Injection, Validation)   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│             Domain & Calculation Engine (Pure)         │
│ (AttendanceEngine · Target Recovery · Safe Absences)   │
└───────────────────────────┬────────────────────────────┘
                            │ SQLAlchemy 2.0 Async
┌───────────────────────────▼────────────────────────────┐
│           Data Layer (Supabase PostgreSQL)             │
│       (Users · Semesters · Sessions · Audit Trail)     │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Features

- **Persistent Authenticated Shell**: Fixed liquid glass top bar with menu, notifications, route title, and profile avatar; fixed liquid glass bottom navigation; non-blocking scrolling body.
- **Academic Setup Wizard**: Unified 7-step guided setup for profile, semester, subjects, timetable routine, holidays, and initial attendance with atomic PostgreSQL persistence.
- **Draft-Only Document Importers**: In-memory parsing for timetable and holiday documents with zero raw file retention in the database or permanent storage buckets.
- **Daily 1-Tap Attendance**: Fast recording on the Today view with automatic time states (`Done`, `Current`, `Upcoming`), extra class creation, and live attendance impact previews.
- **Deterministic Forecast Engine**:
  - **Classes Needed**: $\lceil \frac{r \cdot C - A}{1 - r} \rceil$
  - **Safe Absences**: $\lfloor \frac{A - r \cdot C}{r} \rfloor$ (strictly 0 if below minimum)
- **Semester Context Switching**: Fully scoped subjects, routines, class sessions, and analytics per semester without cross-semester data leakage or historical record deletion.
- **Audit History**: Transparent tracking of attendance status corrections with before/after status logging.
- **Academic Calendar & Holidays**: Category-tagged holidays (Festivals, University Holidays, Semester Breaks) that automatically exclude from conducted class tallies.
- **Warm Light Liquid Glass UI**: Custom glass cards (`BackdropFilter`), terracotta/sage/amber status accents, and raster-optimized vector landscape artwork.

---

## 📁 Repository Structure

```text
AttendHub/
├── backend/                  # FastAPI Application
│   ├── app/
│   │   ├── api/              # REST Endpoints (v1 routers)
│   │   ├── calculations/     # Pure mathematical calculation & insight engines
│   │   ├── core/             # Configuration, security (Argon2id, JWT)
│   │   ├── db/               # SQLAlchemy async session management
│   │   ├── models/           # SQLAlchemy 2.0 ORM models
│   │   ├── schemas/          # Pydantic v2 validation models
│   │   ├── services/         # Domain business logic & transactions
│   │   └── main.py           # FastAPI application entrypoint
│   ├── migrations/           # Alembic database migrations
│   ├── tests/                # Automated pytest test suite
│   ├── Dockerfile            # Multi-stage production container
│   ├── pyproject.toml        # Backend configuration
│   └── requirements.txt      # Python dependencies
│
├── mobile/                   # Flutter Mobile Client
│   ├── lib/
│   │   ├── app/              # App root and navigation shell
│   │   ├── core/             # Theme tokens, API client, local storage
│   │   ├── features/         # Feature modules (Dashboard, Today, Subjects, Calendar, Holidays, Analytics, Auth)
│   │   ├── shared/           # Reusable widgets (Liquid glass, Landscape header, Status badges)
│   │   └── main.dart         # Flutter entrypoint
│   ├── test/                 # Flutter unit & calculation tests
│   └── pubspec.yaml          # Flutter dependencies
│
├── docs/                     # Comprehensive Documentation Suite
│   ├── README.md             # Central documentation hub & index
│   ├── architecture.md       # Architectural deep-dive & math engine
│   ├── api.md                # Complete REST API reference (v1)
│   ├── database.md           # Database ER diagrams, schema & RLS
│   ├── frontend-and-design.md # Mobile architecture & Liquid Glass UI system
│   ├── security.md           # Security architecture & OWASP compliance
│   ├── deployment.md         # Cloud deployment (Render, Supabase, Docker, APK)
│   ├── development.md        # Local setup & development workflow
│   ├── testing.md            # Testing strategy & verification report
│   └── agent-skills.md       # Specialist engineering skills inventory
│
├── docker-compose.yml        # Full-stack container orchestration
├── render.yaml               # Render cloud deployment blueprint
└── README.md                 # Project README
```

---

## ⚡ Quickstart Guide

### 1. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate   # On Windows: .venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run server (connects to Supabase-hosted PostgreSQL)
uvicorn app.main:app --reload --port 8000
```

- API Base: `http://localhost:8000/api/v1`
- Swagger UI: `http://localhost:8000/docs`

### 2. Mobile Setup

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on target device / simulator
flutter run
```

### 3. Docker Deployment (PostgreSQL + Backend)

```bash
docker compose up -d --build
```

---

## 🧪 Testing

### Backend Unit & Integration Tests:
```bash
cd backend
pytest -v
```

All 19 test suites pass across domain math, security invariants, and full API flows.

### Flutter Tests:
```bash
cd mobile
flutter test
```

All 58 unit, widget, shell, and responsive viewport tests pass across 320px to 430px+.

---

## 📖 Documentation

- **[Documentation Hub & Index](docs/README.md)**
- [Architecture & Design Details](docs/architecture.md)
- [REST API Specification](docs/api.md)
- [Database Schema & Supabase RLS Reference](docs/database.md)
- [Frontend Architecture & UI/UX Design System](docs/frontend-and-design.md)
- [Security Architecture & OWASP Compliance](docs/security.md)
- [Cloud Deployment, Docker & Release Build Guide](docs/deployment.md)
- [Local Development Guide](docs/development.md)
- [Testing & Quality Verification](docs/testing.md)
- [Agent Skills & Preflight Inventory](docs/agent-skills.md)

---

## 📄 License

This project is developed as an academic and engineering student utility.
