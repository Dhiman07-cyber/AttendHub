# Attendify — Full-Stack Development Prompt

## Role

You are the lead product engineer building **Attendify**, a production-quality student attendance tracking and planning utility.

Build the complete application end-to-end. Do not stop at static UI.

The final project must include:

- Flutter mobile application
- FastAPI backend
- PostgreSQL database
- secure authentication
- academic profile and semester management
- subject management
- recurring timetable/routine management
- class-session management
- holiday management
- daily attendance recording
- attendance correction/history
- deterministic attendance calculations
- subject-wise analytics
- future attendance forecasting
- calendar
- useful reminders
- secure file import infrastructure
- automated tests
- documentation
- local development setup
- deployment-ready configuration

The application must use real API/database data. Avoid fake buttons, fake calculations and hard-coded production behaviour.

---

# 1. Product Identity

Use the name **Attendify** consistently.

Suggested tagline:

**Track · Plan · Stay Above**

This is a student-side utility, not an institutional or faculty attendance portal.

---

# 2. Non-Negotiable UX Principle

A student should be able to:

1. understand their attendance state in seconds
2. mark a normal day's attendance in roughly 1–2 minutes

Prioritize:

**clarity → speed → accuracy → consistency → aesthetics → depth on demand**

Do not add screens or features simply because they sound impressive.

---

# 3. Technology Stack

## Flutter

Use:

- Flutter / Dart
- Riverpod
- go_router
- Dio
- Freezed
- json_serializable
- intl
- flutter_secure_storage
- Drift/SQLite where offline resilience is implemented

Use a feature-first architecture.

Do not put business logic inside widgets.

## Backend

Use:

- Python
- FastAPI
- Pydantic
- SQLAlchemy 2.x
- Alembic
- PostgreSQL
- pytest
- httpx

Keep the backend lightweight. Do not add Redis/Kafka/Celery unless an actual requirement makes one necessary.

## Storage

Uploaded PDFs/images may use an S3-compatible object store in production. Hide storage behind an adapter/interface. Local development may use filesystem storage.

---

# 4. Repository Structure

Use a clean feature-oriented structure, e.g.:

```text
attendify/
├── mobile/
│   ├── lib/
│   │   ├── app/
│   │   ├── core/
│   │   ├── shared/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── onboarding/
│   │   │   ├── dashboard/
│   │   │   ├── today/
│   │   │   ├── subjects/
│   │   │   ├── calendar/
│   │   │   ├── holidays/
│   │   │   ├── analytics/
│   │   │   ├── profile/
│   │   │   └── timetable/
│   │   └── main.dart
│   ├── test/
│   └── pubspec.yaml
│
├── backend/
│   ├── app/
│   │   ├── core/
│   │   ├── db/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── calculations/
│   │   ├── api/
│   │   └── main.py
│   ├── migrations/
│   ├── tests/
│   └── pyproject.toml
│
├── docs/
├── .env.example
├── docker-compose.yml
└── README.md
```

Keep feature-specific code with the feature. Shared design components belong in a small design-system layer.

---

# 5. Architecture

Use a clear separation:

```text
Presentation
↓
State / Application
↓
Domain
↓
Data / API
```

Attendance formulas must live in domain/application services.

The Dashboard, Today and Analytics screens must not each implement their own calculation formulas.

The server is the authoritative business-rule engine. The Flutter client can optimistically reflect changes but must reconcile with server results.

---

# 6. Authentication

Implement:

- register
- login
- logout
- token/session refresh
- forgot password
- reset password

Use strong password hashing such as Argon2id.

Never store plain-text passwords.

Protect tokens appropriately. Never embed secrets in the Flutter app.

Enforce authorization at the API layer. A user must only be able to access their own academic data.

---

# 7. Academic Profile

Store:

```text
name
university_name
course_name
academic_duration_years
academic_session_start
academic_session_end
current_semester
minimum_attendance
personal_target
```

Defaults:

```text
minimum_attendance = 75
personal_target = 75
```

Users can change both later.

The value 75 is a default, not a hard-coded universal rule.

---

# 8. Semester Management

Create a semester entity scoped to the user.

Suggested fields:

```text
id
user_id
semester_number
label
start_date
end_date
status
```

Switching semester must switch the full academic context:

- subjects
- timetable
- class sessions
- attendance
- holidays/events
- analytics

Never mix records across semesters.

Desktop concept: semester selector sits at bottom-left of sidebar.

Mobile concept: semester switching is available from profile/menu surfaces.

---

# 9. Subject Model

Suggested fields:

```text
id
semester_id
name
code nullable
faculty_name nullable
is_active
```

Subject name is required.

Faculty and subject code are optional.

---

# 10. Timetable Model

Separate recurring timetable definitions from actual sessions.

Suggested:

```text
TimetableEntry
- id
- semester_id
- subject_id
- day_of_week nullable
- start_time nullable
- end_time nullable
- faculty_name nullable
- room nullable
- effective_from nullable
- effective_to nullable
```

Do not invent a time when none exists.

Support both recurring and one-off schedule information.

---

# 11. Class Session Model

Suggested:

```text
ClassSession
- id
- semester_id
- subject_id
- date
- start_time nullable
- end_time nullable
- faculty_name nullable
- room nullable
- session_status
```

Keep the session concept separate from the recurring timetable.

Suggested attendance states:

```text
ATTENDED
ABSENT
NOT_HELD
```

A cancelled or holiday session must not become ABSENT.

---

# 12. Holiday Model

Suggested:

```text
Holiday
- id
- semester_id or academic_profile_id
- start_date
- end_date
- title
- category
- notes nullable
- source
```

Categories:

```text
University Holiday
Festival
Semester Break
Exam Break
Other
```

Support multi-day periods using start/end dates.

---

# 13. Attendance Record Model

Suggested:

```text
AttendanceRecord
- id
- class_session_id
- student_id
- status
- marked_at
- updated_at
- source
```

Source may be:

```text
manual
import
future_ai_import
system_generated
```

The first release primarily uses manual entry.

---

# 14. Source of Truth

Do not make aggregate counters the primary data source.

Prefer actual class sessions and attendance records.

Derived:

```text
attended_count
conducted_count
absent_count
attendance_percentage
```

can be calculated from them.

This makes history, corrections, semester switching and recalculation reliable.

---

# 15. Attendance Calculation Rules

For subject or overall attendance:

```text
conducted = attended + absent
percentage = attended / conducted * 100
```

If conducted is zero, show **No attendance data yet** rather than a misleading number.

For overall attendance, do not average subject percentages. Aggregate counts across the selected semester:

```text
total_attended / total_conducted
```

Holiday/not-held/cancelled sessions are excluded.

---

# 16. Target Forecast

To find classes needed to reach target:

```text
(A + x) / (T + x) >= r
```

Return the smallest non-negative integer `x` satisfying the condition.

If already at/above target, return 0 internally but expose a meaningful UI message such as:

> Already at target.

---

# 17. Maximum Safe Absences

For maximum future absences while remaining above threshold:

```text
A / (T + x) >= r
```

Return the largest integer `x >= 0` satisfying the condition.

If current attendance is below minimum, do not expose a positive “you can miss” recommendation.

---

# 18. Attendance Insight Engine

Build deterministic insight rules in a service.

Examples:

```text
IF attendance < minimum
→ critical recovery insight

IF attendance is near minimum
→ caution insight

IF attendance >= target
→ positive insight

IF maximum_safe_absence <= 2
→ caution insight

IF target gap exists
→ target-recovery insight
```

Return structured insight data:

```text
type
severity
subject_id
headline
message
action
```

Write natural language suitable for students.

Good:

> Attend the next 6 Mathematics classes to reach 75%.

Avoid:

> Threshold violation detected.

Do not use an AI model for deterministic arithmetic or basic status generation.

---

# 19. Today Time Logic

If timing exists:

```text
now >= end → Done
start <= now < end → Current
now < start → Upcoming
```

If timing does not exist, do not invent a current/upcoming state.

Sort timed sessions chronologically. Keep untimed entries after timed sessions in stable routine order.

---

# 20. Daily Attendance UX

The Today page must let the user mark:

```text
Attended
Absent
Not Held
```

Use a pending state before selection.

After save:

1. persist attendance
2. recalculate affected subject/overall values
3. update dashboard
4. update analytics
5. update calendar
6. confirm success

Support extra-class creation through a bottom sheet/modal.

Required for an extra class:

**Subject**

Optional:

- date
- start/end
- faculty
- room

---

# 21. Attendance Correction

Allow previous records to be edited.

Recommended lightweight audit trail:

```text
original_status
new_status
changed_at
changed_by
```

Prefer safe archive/soft-delete rules over destructive deletion when historical attendance exists.

---

# 22. Dashboard Implementation

Build Dashboard from real state/API data.

Sections:

1. Header
2. Overall Attendance
3. Today's Classes
4. Subjects Needing Attention
5. Upcoming Holiday/Event
6. Quick Insight
7. Small Attendance Trend

Dashboard is intentionally light.

It should not reproduce the full Analytics page.

---

# 23. Today Implementation

Today is action-first.

Show:

- date
- today's sessions
- Done / Now / Upcoming if timing exists
- attendance controls
- extra class
- save action
- post-save impact

The UI should be easy to finish with one hand.

---

# 24. Subjects Implementation

Subjects is management-first.

Support:

- add
- edit
- archive/delete safely
- search/filter
- timetable/faculty management
- subject detail

Main list remains visually clean.

Keep heavy “can miss X / need Y” information on Analytics.

---

# 25. Calendar Implementation

Month cells must remain compact even when many subjects occur on one day.

Use markers/dots.

On selected date, show actual sessions in a detail list.

Support:

- month navigation
- date selection
- today shortcut
- attendance markers
- holiday markers
- event markers

---

# 26. Holidays Implementation

Support:

- upcoming list
- past list
- categories
- month/calendar representation
- add holiday
- upload holiday list
- multi-day holiday details

Upcoming information has visual priority.

---

# 27. Analytics Implementation

Analytics is the heaviest information screen.

Per-subject information:

```text
Subject
Attendance %
Attended / Conducted
Maintain Minimum
Reach Target
Status
```

Show deterministic insights such as:

> You can miss up to 4 classes and still stay above 75%.

or:

> Attend the next 6 classes to reach 75%.

Also provide:

- overall trend
- attendance distribution
- subjects on track
- subjects needing attention
- selected semester context

Charts should be useful, not decorative.

---

# 28. Routine Setup

Manual routine form:

Required:

**Subject**

Optional:

- day
- date
- time
- faculty
- room

Support recurring weekly classes and one-off sessions.

---

# 29. Routine Import Architecture

Design an importer boundary:

```text
ImportSource
├── Manual
├── OCR
└── Future AI Parser
```

Future flow:

```text
Image/PDF
→ parser
→ extracted draft
→ validation
→ user review
→ confirm
→ timetable entries
```

Do not directly save uncertain extracted records.

---

# 30. Holiday Import Architecture

Use the same review-first pattern:

```text
Image/PDF
→ parser
→ extracted holiday draft
→ validation
→ user review
→ confirm
→ holiday records
```

---

# 31. Flutter Design System

Create centralized design tokens:

```text
colors.dart
typography.dart
spacing.dart
radii.dart
shadows.dart
motion.dart
```

Do not scatter arbitrary colours and padding values throughout widgets.

Current theme is light only.

Future dark mode must be possible through an alternate theme configuration.

---

# 32. Liquid Glass Implementation

Use custom Attendify material surfaces with:

- translucent warm-white fill
- backdrop blur
- subtle low-opacity border
- soft shadow
- warm tint

Apply selectively.

Do not put strong blur behind critical text.

Implement graceful fallback to an opaque surface when accessibility settings or rendering conditions require it.

---

# 33. Visual Identity

Match the established visual concept:

- warm off-white background
- muted terracotta/rose accent
- sage success
- amber warning
- coral critical
- lavender academic events
- soft nature/landscape artwork
- rounded surfaces
- subtle glass
- clean typography

The target is premium restraint, not visual overload.

---

# 34. Mobile Navigation

Primary bottom navigation:

```text
Dashboard | Today | Subjects | Calendar
```

Analytics and Holidays are secondary destinations accessed contextually or from profile/menu surfaces.

The bottom nav should be a floating glass surface and safe-area aware.

Implement normal tap interaction first.

Then optionally implement an iOS-inspired horizontal press-drag-release selection interaction:

```text
Pointer down
→ horizontal drag
→ indicator tracks finger
→ release
→ nearest tab selected
→ navigate
```

Do not create a giant navigation animation. It should feel instant and fluid.

---

# 35. Accessibility

Implement:

- semantics
- screen-reader labels
- minimum touch sizes
- scalable text
- reduced-motion mode
- colour-independent status labels
- readable contrast

Do not rely on colour alone for attendance status.

---

# 36. Loading / Empty / Error UX

Implement intentional states.

Examples:

```text
No subjects yet.
Add your first subject to begin tracking attendance.
```

```text
Your routine is not set up yet.
Add it manually or upload a routine.
```

```text
Could not save today's attendance.
Please try again.
```

Never surface backend stack traces to the user.

---

# 37. Offline Resilience

The Today workflow should be resilient to temporary connectivity loss.

Where local persistence is enabled:

```text
UI
↓
Local state
↓
Pending sync
↓
API
```

Allow attendance entry offline when all required context is already available. Sync later and handle conflicts safely.

Do not claim full offline mode unless it is actually implemented.

---

# 38. REST API

Build clean REST endpoints similar to:

```text
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout

GET    /profile
PATCH  /profile

GET    /semesters
POST   /semesters
PATCH  /semesters/{id}

GET    /subjects
POST   /subjects
PATCH  /subjects/{id}
DELETE /subjects/{id}

GET    /timetable
POST   /timetable
PATCH  /timetable/{id}
DELETE /timetable/{id}

GET    /sessions
POST   /sessions
PATCH  /sessions/{id}

GET    /attendance/today
POST   /attendance/bulk
PATCH  /attendance/{id}

GET    /holidays
POST   /holidays
PATCH  /holidays/{id}
DELETE /holidays/{id}

GET    /calendar

GET    /analytics/overview
GET    /analytics/subjects
GET    /analytics/subjects/{id}

POST   /imports/routine
POST   /imports/holidays
```

Use consistent response shapes and validation.

---

# 39. Validation

Validate on the server:

- authentication
- ownership
- IDs
- relationships
- dates
- times
- percentages
- semester boundaries
- duplicate records
- state transitions

Reject invalid examples such as:

```text
minimum < 0
minimum > 100
target < 0
target > 100
end_time < start_time
subject belongs to another user
```

---

# 40. Database Rules

Use:

- foreign keys
- indexes
- unique constraints where appropriate
- safe migrations
- transaction boundaries for multi-record attendance updates

Index likely query fields such as user, semester, subject, date and class session.

---

# 41. File Upload Security

For uploaded images/PDFs:

- validate MIME type
- validate file extension
- enforce size limits
- check content signatures where practical
- generate safe server-side object keys
- do not trust user-provided file names
- do not expose filesystem paths
- protect uploaded objects from unauthorized access

---

# 42. Security Hardening

Include:

- secure password hashing
- secure token/session strategy
- HTTPS in production
- safe CORS
- rate limiting on sensitive endpoints
- secret management through environment configuration
- least-privilege database credentials
- structured server logs without passwords/tokens
- authorization checks on every user-scoped endpoint

---

# 43. Testing Strategy

## Domain tests

Test:

- correct percentage
- zero-conducted behaviour
- max safe absences
- target recovery count
- already-at-target behaviour
- below-minimum behaviour
- holiday exclusion
- not-held exclusion
- overall aggregate calculation
- semester isolation

## API tests

Test:

- registration/login
- unauthorized requests
- cross-user access prevention
- CRUD
- attendance updates
- holidays
- semester switching
- analytics

## Flutter tests

Test:

- navigation
- Today controls
- save workflow
- Dashboard states
- Subjects management
- semester selector
- calendar date selection

## End-to-end test

```text
Register
→ academic profile
→ semester
→ subjects
→ timetable
→ holiday
→ mark today's classes
→ save
→ Analytics
→ verify calculation
```

---

# 44. Critical Edge Cases

Handle explicitly:

1. no attendance yet
2. zero conducted classes
3. current attendance = 100%
4. current attendance below minimum
5. current attendance already at target
6. target lower than current attendance
7. holiday on scheduled day
8. not-held class
9. missing timings
10. changed routine
11. semester switch
12. attendance correction
13. deleted/archived subject with historical attendance
14. multi-day holiday
15. duplicate import results
16. offline attendance entry
17. session exists but subject is archived
18. imported timetable has incomplete data

---

# 45. Notifications

Start with useful, non-invasive reminders:

- attendance below minimum
- attendance approaching minimum
- target recovery
- today's attendance not yet recorded

Allow user control.

Do not create excessive notifications.

---

# 46. Profile / Semester UX

The profile screen should expose academic information clearly.

The active semester must be easy to identify.

When the user switches semesters, show a short loading/skeleton state and then replace the academic context completely.

Never show stale Semester 5 data underneath Semester 4 labels while switching.

---

# 47. README and Documentation

Create:

```text
README.md
docs/architecture.md
docs/api.md
docs/database.md
docs/development.md
docs/testing.md
```

README must explain:

- product purpose
- architecture
- setup
- environment variables
- database initialization
- migrations
- Flutter run/build
- backend run
- tests
- deployment overview

---

# 48. Environment Configuration

Provide `.env.example` containing placeholders such as:

```text
DATABASE_URL=
JWT_SECRET=
REFRESH_TOKEN_SECRET=
ACCESS_TOKEN_EXPIRE_MINUTES=
CORS_ORIGINS=
STORAGE_ENDPOINT=
STORAGE_BUCKET=
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=
```

Never commit real credentials.

---

# 49. Deployment

Provide local development support for:

- Flutter
- FastAPI
- PostgreSQL
- optional local object storage

Provide production guidance for:

- Flutter build
- backend deployment
- PostgreSQL
- object storage
- HTTPS
- environment secrets
- migrations
- logging/monitoring

Do not hard-code a cloud provider unless required.

---

# 50. Implementation Order

Build vertically in this order:

### Phase 1 — Foundation

- repo
- Flutter app
- FastAPI app
- PostgreSQL
- migrations
- authentication foundation
- API client
- design tokens

### Phase 2 — Academic Setup

- profile
- semesters
- subjects
- timetable
- holidays

### Phase 3 — Attendance Core

- class sessions
- attendance records
- calculation engine
- correction history

### Phase 4 — Core UI

- Dashboard
- Today
- Subjects
- Calendar
- Holidays

### Phase 5 — Intelligence

- Analytics
- insight engine
- recovery calculations
- safe-absence calculations

### Phase 6 — Reliability

- loading/error states
- accessibility
- testing
- offline resilience where implemented
- security hardening

### Phase 7 — Import Infrastructure

- upload pipeline
- review screens
- parser interfaces
- future OCR integration hooks

Do not make AI/OCR a prerequisite for completing the core product.

---

# 51. Definition of Done

A feature is complete only when:

```text
UI
↓
State
↓
API
↓
Database
↓
Validation
↓
Error handling
↓
Tests
↓
Documentation
```

all exist and work coherently.

A visible number must come from real data.

A Save button must save.

A semester selector must really switch academic context.

A holiday must affect calendar/session behaviour.

Analytics must use the actual attendance engine.

---

# 52. Final Product Experience

The application should feel like a real utility.

The core loop is:

```text
Routine
↓
Actual Class Sessions
↓
One-Tap Daily Attendance
↓
Accurate Attendance History
↓
Current Status
↓
Actionable Analytics
```

The product's defining value is not merely:

> “Your attendance is 78.4%.”

It is:

> “You are at 78.4%. You are above the required 75%. You can miss 3 more classes in this subject and remain above the minimum, or attend the next 4 classes to reach your 80% target.”

---

# 53. Final Build Instruction

Implement the complete Attendify project according to this prompt and the accompanying `context.md` and `design.md` files.

Start with architecture and data modelling before polishing every screen.

Build real vertical slices rather than disconnected mockups.

Use the established warm light visual system with restrained liquid glass and subtle nature artwork.

Do not implement the dark theme now.

Do not create a Planner page.

Do not create a standalone Settings page unless a genuine future requirement demands it.

Keep Dashboard light.

Keep Today extremely fast.

Keep Subjects management-first.

Keep Calendar compact.

Keep Holidays useful for forward planning.

Make Analytics the heavy decision-making screen.

Keep all deterministic attendance calculations on the domain/backend side.

Design all future OCR/AI import features behind replaceable interfaces and a review-before-save workflow.

Prioritize correctness, security, accessibility, speed, maintainability and UX over unnecessary complexity.

The finished result should be suitable for real student use, final-year project demonstration, viva, documentation, future extension and production-style engineering review.
