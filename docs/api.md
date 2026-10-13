# AttendHub — REST API Specification

> **Local Base URL:** `http://localhost:8000/api/v1`  
> **Production Base URL:** `https://attendify-li14.onrender.com/api/v1`  
> **Interactive OpenAPI (Swagger UI):** `/docs`  
> **ReDoc Reference:** `/redoc`

All endpoints (except `/health`, `/`, `/auth/register`, `/auth/login`, and `/auth/refresh`) require a valid JWT Bearer token in the `Authorization` header:
```http
Authorization: Bearer <jwt_access_token>
```

---

## 0. Health & Keep-Alive (`/health`)

### `GET /health` · `HEAD /health` · `GET /api/v1/health`
Health probe and keep-alive endpoint for Render and external cron monitors. Actively queries PostgreSQL (`SELECT COUNT(id) FROM users`) and pings the Supabase REST gateway (`/rest/v1/`) so neither Render nor the Supabase free-tier database pauses due to inactivity.

**Response (`200 OK`):**
```json
{
  "status": "healthy",
  "service": "AttendiFy Backend",
  "version": "1.0.0",
  "database": "connected",
  "supabase_ping": "ok"
}
```

---

## 1. Authentication (`/auth`)

### `POST /auth/register`
Registers a new student account, creates an `AcademicProfile` with `75.0%` minimum and personal target defaults, and optionally seeds initial 5th semester demo data (`seed_demo_data: false` by default).

**Request Body:**
```json
{
  "email": "student@university.edu",
  "password": "StrongPassword123!",
  "full_name": "Alex Mercer",
  "seed_demo_data": false
}
```

**Response (`201 Created`):**
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 604800
}
```

### `POST /auth/login`
Authenticates a student via email and password using Argon2id verification.

**Request Body:**
```json
{
  "email": "student@university.edu",
  "password": "StrongPassword123!"
}
```

**Response (`200 OK`):** Returns `Token` (`access_token`, `refresh_token`, `token_type`, `expires_in`).

### `POST /auth/refresh`
Rotates an expired access token using a valid refresh token signed with `REFRESH_TOKEN_SECRET`.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOi..."
}
```

### `POST /auth/logout`
Confirms session termination for the authenticated student.

**Response (`200 OK`):**
```json
{
  "status": "success",
  "message": "Successfully logged out."
}
```

### `GET /auth/me`
Retrieves the authenticated student's account record (`id`, `email`, `full_name`, `avatar_initial`, `is_active`, `created_at`).

---

## 2. Academic Profile & Unified Setup (`/profile`)

### `GET /profile`
Returns the student's global academic profile and active semester attendance thresholds.

**Response (`200 OK`):**
```json
{
  "id": "profile-uuid",
  "user_id": "user-uuid",
  "full_name": "Alex Mercer",
  "email": "student@university.edu",
  "university_name": "Assam down town University",
  "course_name": "B.Tech Computer Science & Engineering",
  "student_id_number": "ADTU/0/2024-28/BCSM/001",
  "academic_duration_years": 4,
  "academic_session_start": 2024,
  "academic_session_end": 2028,
  "current_semester_id": "semester-uuid",
  "current_semester_label": "5th Semester",
  "minimum_attendance": 75.0,
  "personal_target": 75.0,
  "low_attendance_alert": 70.0
}
```

### `PATCH /profile`
Partially updates global academic profile fields or attendance threshold settings (`minimum_attendance`, `personal_target`, `low_attendance_alert`).

### `GET /profile/setup-status`
Returns server-verified academic setup completeness for onboarding and first-run routing.

**Response (`200 OK`):**
```json
{
  "is_profile_complete": true,
  "has_active_semester": true,
  "is_semester_configured": true,
  "setup_complete": true,
  "current_semester_id": "semester-uuid",
  "current_semester_label": "5th Semester",
  "subject_count": 5
}
```

### `GET /profile/setup-data?semester_number=5`
Fetches stored academic setup configuration (global profile, semester dates, subjects, timetable entries, holidays, starting attendance baseline, and `available_semester_numbers`) to pre-populate the 7-step Academic Setup Wizard.

### `POST /profile/setup`
Commits a unified 7-step academic setup atomically in a single PostgreSQL transaction: updates global profile, creates or activates the target semester, synchronizes subjects, timetable entries, and semester holidays, and materializes optional baseline attendance.

**Request Body:**
```json
{
  "full_name": "Alex Mercer",
  "university_name": "Assam down town University",
  "course_name": "B.Tech Computer Science & Engineering",
  "student_id_number": "ADTU/0/2024-28/BCSM/001",
  "academic_duration_years": 4,
  "academic_session_start": 2024,
  "academic_session_end": 2028,
  "semester_id": null,
  "semester_number": 5,
  "semester_label": "5th Semester",
  "start_date": "2026-08-01",
  "end_date": "2026-12-31",
  "minimum_attendance": 75.0,
  "personal_target": 75.0,
  "low_attendance_alert": 70.0,
  "subjects": [
    {
      "name": "Design & Analysis of Algorithms",
      "code": "CS-501",
      "faculty_name": "Dr. Sarah Jenkins",
      "color": "#C96E5B"
    }
  ],
  "timetable_entries": [
    {
      "subject_name": "Design & Analysis of Algorithms",
      "day_of_week": 0,
      "start_time": "09:00",
      "end_time": "10:00",
      "room": "Hall B",
      "faculty_name": "Dr. Sarah Jenkins"
    }
  ],
  "holidays": [
    {
      "title": "Independence Day",
      "category": "University Holiday",
      "start_date": "2026-08-15",
      "end_date": "2026-08-15",
      "notes": null
    }
  ],
  "starting_attendance": [
    {
      "subject_name": "Design & Analysis of Algorithms",
      "attended_count": 12,
      "conducted_count": 15
    }
  ]
}
```

**Response (`200 OK`):** Returns the updated `AcademicProfileOut`.

---

## 3. Semesters (`/semesters`)

### `GET /semesters`
Lists all semesters owned by the authenticated student with progress metrics (`current_week`, `total_weeks`, `weeks_remaining`, `progress_percentage`).

### `POST /semesters`
Creates a new semester context (`semester_number`, `label`, `start_date`, `end_date`, `total_weeks`).

### `POST /semesters/switch`
Switches the student's active semester context via request body `{"semester_id": "..."}`. All subsequent subject, timetable, session, holiday, and analytics queries scope to this semester.

### `POST /semesters/{id}/activate`
Activates the specified semester by path parameter `id`.

---

## 4. Subjects (`/subjects`)

### `GET /subjects?semester_id=...&include_inactive=false`
Returns subjects for the active (or specified) semester with lightweight attendance metrics (`attended`, `conducted`, `percentage`, `status`, `status_label`, `schedule_summary`).

### `POST /subjects`
Creates a new subject in the active (or specified) semester.

**Request Body:**
```json
{
  "name": "Design & Analysis of Algorithms",
  "code": "CS-501",
  "faculty_name": "Dr. Sarah Jenkins",
  "color": "#C96E5B",
  "icon": "book"
}
```

### `GET /subjects/{id}`
Returns detailed single-subject metrics including `absent`, `classes_needed_for_min`, `classes_needed_for_target`, `max_safe_absences`, `can_miss_message`, and `recovery_message`.

### `PATCH /subjects/{id}`
Updates subject attributes (`name`, `code`, `faculty_name`, `color`, `icon`, `is_active`).

### `DELETE /subjects/{id}`
Safely archives a subject (`is_active = false`) if it has attendance records, or deletes it if unused, preserving historical attendance integrity.

---

## 5. Timetable & Weekly Routine (`/timetable`)

### `GET /timetable?semester_id=...`
Lists recurring weekly timetable entries for the active semester.

### `POST /timetable`
Creates a recurring timetable slot (`subject_id`, `day_of_week` `0..6`, `start_time`, `end_time`, `room`, `faculty_name`).

### `PATCH /timetable/{id}`
Updates an existing timetable slot.

### `DELETE /timetable/{id}`
Deletes a timetable slot.

### `GET /timetable/weekly-status?week_offset=0&semester_id=...`
Read-only endpoint synthesizing the 7-day weekly routine grid for the target week offset (`-52..52`) joined with persisted attendance statuses (`is_attended`, `is_absent`, `is_not_held`, `is_unmarked`) and holiday indicators.

---

## 6. Class Sessions & Daily Attendance (`/sessions`, `/attendance`)

### `POST /sessions/extra`
Creates an unscheduled extra class session on a specific date (`subject_id`, `date`, `start_time`, `end_time`, `faculty_name`, `room`).

### `GET /attendance/today` · `GET /attendance/day?date=YYYY-MM-DD`
Side-effect-free read query returning scheduled virtual sessions and persisted class sessions for the target date, time-aware status (`Done`, `Now`, `Upcoming`), and live attendance impact projection.

**Response (`200 OK`):**
```json
{
  "selected_date": "2026-10-13",
  "selected_date_str": "Tuesday, 13 October 2026",
  "semester_label": "5th Semester",
  "total_classes": 3,
  "marked_classes": 2,
  "pending_classes": 1,
  "not_held_classes": 0,
  "sessions": [
    {
      "id": "session-uuid-or-virtual-id",
      "semester_id": "semester-uuid",
      "subject_id": "subject-uuid",
      "subject_name": "Software Engineering",
      "subject_code": "CS-502",
      "subject_color": "#C96E5B",
      "subject_icon": "book",
      "date": "2026-10-13",
      "start_time": "09:00",
      "end_time": "10:00",
      "faculty_name": "Prof. Alan Vance",
      "room": "Lab 3",
      "session_status": "SCHEDULED",
      "is_extra": false,
      "timetable_entry_id": "tt-entry-uuid",
      "time_status": "Done",
      "attendance_status": "ATTENDED",
      "attendance_id": "record-uuid"
    }
  ],
  "current_overall_percentage": 82.5,
  "projected_overall_percentage": 82.5,
  "projected_delta": 0.0
}
```

### `POST /attendance/bulk` · `POST /attendance/day/bulk`
Authoritative transactional write endpoint for daily attendance confirmation.
- Enforces the server-side rolling 3-calendar-day edit window (`[today - 2 days, today]`).
- Materializes virtual schedule entries into concrete `class_sessions` rows, saves `attendance_records` (`ATTENDED`, `ABSENT`, `NOT_HELD`), and appends `attendance_audit_logs` when updating prior marks.
- Accepts either `items` or `records` array in the request payload.

**Request Body:**
```json
{
  "date": "2026-10-13",
  "items": [
    {
      "timetable_entry_id": "tt-entry-uuid-1",
      "subject_id": "subject-uuid-1",
      "status": "ATTENDED"
    },
    {
      "timetable_entry_id": "tt-entry-uuid-2",
      "subject_id": "subject-uuid-2",
      "status": "ABSENT"
    }
  ]
}
```

### `PATCH /attendance/{id}`
Corrects an existing attendance record within the rolling 3-day window and records an immutable `AttendanceAuditLog` entry.

**Request Body:**
```json
{
  "new_status": "ATTENDED",
  "reason": "Faculty corrected roll call"
}
```

---

## 7. Dashboard (`/dashboard`)

### `GET /dashboard`
Returns the student's lightweight daily overview:
- Overall attendance ring (`overall_percentage`, `total_attended`, `total_conducted`, `target_percentage`, `minimum_percentage`, `trend_from_last_month`)
- Semester progress dial (`current_week`, `total_weeks`, `weeks_remaining`, `semester_progress_pct`)
- Today's sessions snapshot (`today_sessions`)
- Subjects needing attention (`subjects_needing_attention`)
- Next upcoming holiday (`upcoming_holiday`)
- Deterministic quick insight (`quick_insight`)
- Recent attendance trend (`trend_points`)

---

## 8. Analytics (`/analytics`)

### `GET /analytics/overview?semester_id=...`
Returns comprehensive deterministic analytics for the semester:
- Whole-semester raw aggregate totals (`total_attended`, `total_absent`, `total_conducted`, `overall_percentage`)
- Semester-level recovery and safe-absence margins (`total_recovery_classes_needed`, `total_safe_absences_margin`)
- Per-subject analytics array (`subjects`: percentage, attended/conducted, `classes_needed_for_min`, `classes_needed_for_target`, `max_safe_absences`, `can_miss_message`, `recovery_message`, `status`)
- Rule-based student insights (`insights`)
- Monthly attendance trend points (`trends`, `month_over_month_change`)

---

## 9. Calendar & Holidays (`/calendar`, `/holidays`)

### `GET /calendar?year=2026&month=10&selected_date=2026-10-13`
Returns month-level day markers (`has_classes`, `has_holiday`, `dominant_status`, `class_count`) alongside detailed `selected_date_sessions` and `selected_date_holidays`.

### `GET /holidays?filter_type=upcoming&semester_id=...`
Lists holidays filtered by `upcoming`, `past`, or `all`, normalized across categories (`University Holiday`, `Festival`, `Semester Break`, `Exam Break`, `Academic`, `Other`).

### `POST /holidays`
Creates a single-day or multi-day holiday (`title`, `start_date`, `end_date`, `category`, `notes`, `semester_id`).

### `PATCH /holidays/{id}`
Updates an existing holiday record.

### `DELETE /holidays/{id}`
Deletes a holiday record.

---

## 10. Draft-Only Document Importers (`/imports`)

> **Zero Storage Retention Policy**: Uploaded files (`PDF`, `PNG`, `JPG`, `JPEG`, `WEBP`, `CSV` up to 10 MB) are validated and parsed in transient memory. Raw files are never stored in PostgreSQL or object storage buckets.

### `POST /imports/routine/parse`
Multipart file upload (`file`) returning structured `RoutineDraftEntry` items (`ImportParseResponse`) for interactive user review.

### `POST /imports/routine/confirm`
Atomically commits user-reviewed timetable draft entries (`RoutineReviewRequest`) to the active semester.

### `POST /imports/holidays/parse`
Multipart file upload (`file`) returning structured `HolidayDraftEntry` items (`ImportParseResponse`) for interactive user review.

### `POST /imports/holidays/confirm`
Atomically commits user-reviewed holiday draft entries (`HolidayReviewRequest`) to the active semester.
