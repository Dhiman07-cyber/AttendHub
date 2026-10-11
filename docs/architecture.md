# AttendHub — System Architecture & Engineering Design

> **Track · Plan · Stay Above**

---

## 1. High-Level Architectural Overview

AttendHub is an independent, student-first attendance tracking and forecasting utility. Unlike institutional ERP systems designed for administrative record-keeping, AttendHub is optimized for student decision-making: providing deterministic insight into required attendance, safe absences, and upcoming schedules within seconds.

The system is organized around a strict four-layer architecture:

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

## 2. Layer Responsibilities

### 2.1 Presentation Layer (Flutter Mobile)
- **Framework**: Flutter 3.x / Dart 3.x.
- **State Management**: Riverpod (`NotifierProvider`, `FutureProvider`) for immutable, reactive state transitions.
- **Navigation & App Shell**: Persistent Authenticated Shell with a fixed top glass app bar (`PersistentTopBar`), persistent floating bottom liquid glass pill (`LiquidGlassBottomNav`), and `IndexedStack` preserving state across primary tabs (`Dashboard`, `Today`, `Subjects`, `Calendar`).
- **Design Tokens**: Centralized tokens in `core/theme/` (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radii.dart`, `app_shadows.dart`).
- **Liquid Glass System**: Translucent container surfaces (`BackdropFilter` with Gaussian blur, low-opacity border, warm tint `#FAF4F0`). Optimized to avoid stacking live blurs over repeatedly scrolled list items.
- **Custom Visual Art**: Procedural vector painters (`landscape_header.dart`) providing sunrise, mountain layers, birds, and pine trees cached at 800px width with `RepaintBoundary` isolation to prevent raster thread jank.

### 2.2 Application & Service Layer (FastAPI)
- **Framework**: FastAPI (Python 3.11+ / 3.14).
- **Authentication**: Argon2id password hashing + cryptographically signed JWT access tokens (60 min) and refresh tokens (30 days).
- **Service Isolation**: Each domain concept (Academic, Subject, Attendance, Analytics, Holidays, Import) is encapsulated into its own service class with async database sessions injected via FastAPI's `Depends(get_db)`.
- **Validation**: Strict Pydantic v2 schemas validating ranges, relationships, and preventing malformed state transitions.

### 2.3 Domain & Pure Calculation Engine
The business rules for attendance calculations are isolated into pure, side-effect-free domain functions in `app/calculations/attendance_engine.py` and `app/calculations/insight_engine.py`:
- No external I/O or network requests.
- No reliance on non-deterministic AI/LLM models for basic arithmetic.
- 100% unit-tested with mathematical boundary conditions.

### 2.4 Persistence Layer
- **ORM**: SQLAlchemy 2.0 async engine (`create_async_engine`).
- **Database**: Cloud-hosted PostgreSQL 17 on Supabase (`postgresql+asyncpg` through Transaction Pooler port 6543). SQLite has been retired to ensure strict production parity and RLS compatibility.
- **Migrations**: Alembic managing forward and backward schema transformations.

---

## 3. Deterministic Attendance Mathematics

AttendHub adheres strictly to formal mathematical equations for all calculations.

### 3.1 Basic Metrics
Let:
- $A$ = Total Attended classes
- $B$ = Total Absent classes
- $C$ = Total Conducted classes = $A + B$

Sessions marked as `NOT_HELD` or occurring on registered `HOLIDAY` dates are strictly excluded from $C$:

$$\text{Attendance Percentage } P = \begin{cases} \text{None (No data)}, & \text{if } C = 0 \\ \frac{A}{C} \times 100, & \text{if } C > 0 \end{cases}$$

### 3.2 Semester-Wide Aggregation Rule
For overall attendance across an entire semester, subject percentages are **never averaged**:

$$P_{\text{overall}} = \frac{\sum_{i=1}^{N} A_i}{\sum_{i=1}^{N} C_i} \times 100$$

Averaging percentages across subjects with differing conducted class counts produces statistically invalid numbers. AttendHub aggregates raw totals directly.

### 3.3 Target Recovery Forecast
To determine the minimum number of consecutive future classes $x$ a student must attend to elevate their attendance to target threshold $r = \frac{\text{target\_percentage}}{100}$:

$$\frac{A + x}{C + x} \ge r \implies A + x \ge r \cdot C + r \cdot x \implies x(1 - r) \ge r \cdot C - A$$

$$x = \max\left(0, \left\lceil \frac{r \cdot C - A}{1 - r} \right\rceil\right)$$

If current percentage $P \ge \text{target}$, $x = 0$ and the student receives a status confirmation: *"Already at target."*

### 3.4 Maximum Safe Absences
To determine the maximum number of consecutive future classes $x$ a student may miss while remaining at or above the minimum required threshold $r = \frac{\text{minimum\_percentage}}{100}$:

$$\frac{A}{C + x} \ge r \implies r(C + x) \le A \implies r \cdot x \le A - r \cdot C$$

$$x = \max\left(0, \left\lfloor \frac{A - r \cdot C}{r} \right\rfloor\right)$$

If current attendance is strictly below the minimum threshold ($P < \text{minimum}$), the safe absence count is $0$, preventing misleading "you can miss" recommendations.

---

## 4. Context & Multi-Tenancy Isolation

AttendHub enforces strict isolation across two dimensions:

1. **User Tenancy**: Every query joins on `user_id` or filters by user-owned foreign keys. Cross-tenant reads and mutations are rejected with HTTP 403 / 404.
2. **Semester Scoping**: Academic context is strictly bounded by `semester_id`. Switching semesters replaces subjects, timetable routines, session logs, and attendance counters completely. No historical records bleed into adjacent semesters.

---

## 5. Review-Before-Save Import Pipeline

Timetables and academic holiday calendars may be ingested through files or external data. To prevent inaccurate routine corruption:

```text
Uploaded File / Image / PDF
         │
         ▼
File Validation (MIME, size, safe key)
         │
         ▼
Parser Boundary (Heuristic / Future OCR adapter)
         │
         ▼
Draft Preview (Structured Schema)
         │
         ▼
Interactive User Review & Edit (Client UI)
         │
         ▼
Confirmed Save (Atomic Transaction in DB)
```

Uncertain data is never saved directly to the database without explicit user confirmation.

---

## 6. Global Profile vs. Semester-Scoped Data

AttendHub strictly demarcates global student identity from semester-bound academic configurations:

### 6.1 Global User Scope
- **Entities**: `users`, `academic_profiles`.
- **Attributes**: Full Name, University Name, Course/Program Name, Academic Duration (Years), Graduation Start Year, Expected Graduation Year, Account Email.
- **Invariance**: Global profile identity persists across semester transitions and is never duplicated inside semester rows.

### 6.2 Semester-Scoped Data
- **Entities**: `semesters`, `subjects`, `timetable_entries`, `class_sessions`, `attendance_records`, `attendance_audit_logs`, and semester-bound `holidays`.
- **Attributes**: Semester Number & Label, Enrolled Subjects, Weekly Class Routine, Recorded Daily Sessions, Calculated Metrics & Target Forecasts.
- **Invariance**: Every query and mutation is strictly parameterized by `(user_id, semester_id)`. Switching semesters resets the active context without mixing records across semesters.

---

## 7. Semester Lifecycle & History Preservation

Semester switching behaves as an authoritative academic context switch:

1. **Context Activation**:
   - The user selects an existing semester in Profile or drawer navigation.
   - The client invokes `POST /api/v1/semesters/{id}/activate`.
   - The backend validates ownership, resets previous active flags (`is_active = FALSE`), and activates the target semester (`is_active = TRUE`).
2. **State Invalidation**:
   - On successful HTTP response, the client updates the active `semester_id` and invalidates all semester-scoped Riverpod providers (`subjectsProvider`, `todayProvider`, `dashboardProvider`, `calendarProvider`, `analyticsOverviewProvider`, `holidaysProvider`).
   - If activation fails, the client retains the current semester context and shows an honest error message without flickering stale state.
3. **Historical Preservation**:
   - Earlier semester records, attendance logs, and subjects are **never deleted or soft-archived** upon switching.
   - Students can freely switch back to prior semesters to review past attendance audits and statistics.

---

## 8. Unified Academic Setup Wizard

To eliminate fragmented configuration across separate screens, AttendHub provides a guided 7-step Academic Setup Wizard (`AcademicSetupScreen`):

```text
Step 1: Academic Profile    ── (Name, University, Course, Years, Expected Graduation)
Step 2: Semester Details    ── (Semester Number, Term Label, Target 75%, Min 75%)
Step 3: Subjects List       ── (Enrolled subjects with optional code and faculty)
Step 4: Routine / Timetable ── (Manual schedule or draft CSV/document import)
Step 5: Academic Holidays   ── (Manual holidays or draft CSV/document import)
Step 6: Starting Attendance ── (Optional verified historical attended/conducted baseline)
Step 7: Review & Save       ── (Atomic transactional commit via POST /profile/setup)
```

### Server-Checked Setup Completeness
First-run detection uses the dedicated `GET /api/v1/profile/setup-status` endpoint rather than assuming an empty list means a new user. The backend returns:
- `is_profile_complete`: Whether university, course, and graduation years are configured.
- `has_active_semester`: Whether an active semester exists.
- `active_semester_id`: The authoritative active semester UUID.
- `is_setup_complete`: True only when both global profile and active semester are established.

---

## 9. Draft-Only Document Import & Zero Storage Retention

Imported timetables and academic calendars are processed strictly for data extraction:

1. **Zero Retention Rule**:
   - Original PDF documents and image files are **never stored** in PostgreSQL (no binary/Base64 columns) or Supabase Storage buckets.
   - The FastAPI backend validates MIME type, magic bytes, and file size (< 10MB) in bounded memory, parses the data, and immediately releases file handles.
2. **In-Memory Draft Review**:
   - Extracted routine slots or holidays are returned directly as structured draft models to the Flutter client.
   - Draft records remain strictly in client-side component state (`RoutineImportDialog`, `HolidayImportDialog`).
   - The user can review, edit, add, or remove draft entries.
3. **Explicit Confirmation**:
   - Only when the user taps "Confirm & Save" are structured entities committed to the active semester via atomic API transactions.
   - If the user taps "Discard" or navigates away, draft state is wiped, resulting in zero persisted academic records.

---

## 10. Persistent App Shell & Rendering Performance

### 10.1 Persistent Authenticated Shell
The authenticated view (`App` in `mobile/lib/app/app.dart`) is wrapped in a unified shell:
- **Persistent Top Bar (`PersistentTopBar`)**: Fixed liquid glass header containing drawer trigger, active route context, notification bell with unread badge, and profile avatar.
- **Scrollable Viewport**: Page content (`LandscapeHeaderWidget` with `topOffset: 52`) scrolls beneath the fixed top bar without top controls scrolling out of view.
- **Persistent Bottom Nav (`LiquidGlassBottomNav`)**: Fixed floating navigation pill respecting SafeArea.
- **`IndexedStack` Tab Management**: Keeps primary destinations (`Dashboard`, `Today`, `Subjects`, `Calendar`) alive to eliminate rebuild jank on tab switching.

### 10.2 Render & Raster Optimizations
- **Header Art Caching**: `LandscapeHeaderWidget` rasterizes custom vector art at `cacheWidth: 800` inside a `RepaintBoundary` to prevent continuous UI isolate repaint during scrolling.
- **Backdrop Blur Optimization**: Stacking live `BackdropFilter` shaders over repeating list rows has been removed in favor of translucent tinted containers, reserving live blur for persistent shell overlays.
- **100% Overflow-Free Layout**: All card headers, metric rings, and wizard step indicators use flexible wrapping and `Expanded` boundaries, verified across viewports from 320px to 430px+.
