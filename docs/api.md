# AttendHub — REST API Specification

> Base URL: `http://localhost:8000/api/v1`  
> Interactive OpenAPI Documentation: `http://localhost:8000/docs`  
> ReDoc Documentation: `http://localhost:8000/redoc`

All endpoints (except public authentication routes) require a Bearer token in the `Authorization` header:
```http
Authorization: Bearer <jwt_access_token>
```

---

## 1. Authentication (`/auth`)

### `POST /auth/register`
Creates a new user, default academic profile, and automatically initializes 5th semester demo subjects for instant student onboarding.

**Request Body:**
```json
{
  "email": "student@university.edu",
  "password": "StrongPassword123!",
  "full_name": "Alex Mercer"
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

### `POST /auth/login`
Authenticates a user via email and password using Argon2id verification.

**Request Body:**
```json
{
  "email": "student@university.edu",
  "password": "StrongPassword123!"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

### `POST /auth/refresh`
Rotates an expired access token using a valid refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOi..."
}
```

### `GET /auth/me`
Retrieves the authenticated user's account details.

---

## 2. Academic Profile (`/profile`)

### `GET /profile`
Returns the user's academic profile and active semester settings.

**Response (200 OK):**
```json
{
  "id": "uuid-here",
  "name": "Alex Mercer",
  "university_name": "Apex Technical University",
  "course_name": "B.Tech Computer Science",
  "academic_duration_years": 4,
  "academic_session_start": "2024-08-01",
  "academic_session_end": "2025-05-31",
  "current_semester": 5,
  "minimum_attendance": 75.0,
  "personal_target": 75.0
}
```

### `PATCH /profile`
Updates academic profile settings (e.g., minimum required attendance or personal target).

### `GET /profile/setup-status`
Inspects academic configuration and returns server-computed setup completeness for the authenticated user.

**Response (200 OK):**
```json
{
  "user_id": "uuid-here",
  "is_profile_complete": true,
  "has_active_semester": true,
  "active_semester_id": "semester-uuid-here",
  "active_semester_number": 5,
  "is_setup_complete": true
}
```

### `POST /profile/setup`
Commits a unified 7-step academic setup transactionally in PostgreSQL: updates global profile, creates or activates the target semester, creates enrolled subjects, creates timetable entries, creates semester holidays, and optionally establishes verified initial baseline attendance.

**Request Body:**
```json
{
  "full_name": "Alex Mercer",
  "university_name": "Apex Technical University",
  "course_name": "B.Tech Computer Science",
  "degree_duration_years": 4,
  "graduation_start_year": 2023,
  "expected_graduation_year": 2027,
  "semester_id": null,
  "semester_number": 5,
  "semester_label": "Semester 5",
  "start_date": "2026-08-01",
  "end_date": "2026-12-31",
  "minimum_attendance": 75.0,
  "personal_target": 75.0,
  "subjects": [
    {
      "name": "Design & Analysis of Algorithms",
      "code": "CS-501",
      "faculty_name": "Dr. Sarah Jenkins"
    }
  ],
  "timetable": [
    {
      "subject_name": "Design & Analysis of Algorithms",
      "day_of_week": 0,
      "start_time": "09:00:00",
      "end_time": "10:30:00",
      "room": "Hall B",
      "faculty_name": "Dr. Sarah Jenkins"
    }
  ],
  "holidays": [
    {
      "title": "Independence Day",
      "category": "University Holiday",
      "start_date": "2026-08-15",
      "end_date": "2026-08-15"
    }
  ],
  "starting_attendance": []
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Academic setup completed successfully",
  "semester_id": "semester-uuid-here",
  "is_setup_complete": true
}
```

---

## 3. Semesters (`/semesters`)

### `GET /semesters`
Lists all semesters associated with the authenticated student.

### `POST /semesters`
Creates a new semester context.

### `POST /semesters/{id}/activate`
Switches the active academic context. All subsequent queries for subjects, timetable, and attendance will scope to this semester.

---

## 4. Subjects (`/subjects`)

### `GET /subjects`
Returns active subjects for the currently selected semester. Query param `include_archived=true` includes archived subjects.

### `POST /subjects`
Creates a new subject.

**Request Body:**
```json
{
  "name": "Design & Analysis of Algorithms",
  "code": "CS-501",
  "faculty_name": "Dr. Sarah Jenkins",
  "semester_id": "semester-uuid"
}
```

### `PATCH /subjects/{id}`
Updates subject details.

### `DELETE /subjects/{id}`
Safely archives a subject (sets `is_active = false`) to preserve historical attendance integrity.

---

## 5. Daily Attendance & Sessions (`/attendance`, `/sessions`, `/timetable`)

### `GET /attendance/day?date=YYYY-MM-DD`
Read-only query returning virtual scheduled sessions synthesized from the weekly recurring routine and overlaying any saved attendance records for the specified calendar date. Completely side-effect free (never writes rows).

**Response (200 OK):**
```json
{
  "date": "2026-10-11",
  "is_holiday": false,
  "holiday_name": null,
  "sessions": [
    {
      "id": "session-or-virtual-id",
      "timetable_entry_id": "tt-entry-uuid-1",
      "semester_id": "semester-uuid-1",
      "subject_id": "subject-uuid-1",
      "subject_name": "Software Engineering",
      "subject_code": "CS-502",
      "subject_color": "#C96E5B",
      "subject_icon": "book",
      "date": "2026-10-11",
      "start_time": "09:00:00",
      "end_time": "10:30:00",
      "faculty_name": "Prof. Alan Vance",
      "room": "Lab 3",
      "session_status": "SCHEDULED",
      "is_extra": false,
      "time_status": "Done",
      "attendance_status": "ATTENDED",
      "attendance_id": "record-uuid-1"
    }
  ]
}
```

### `POST /attendance/day/bulk`
The authoritative write boundary for daily attendance confirmation. Enforces server-side rolling 3-calendar-day window (`[today - 2 days, today]`), materializes concrete `class_sessions` atomically in a single transaction, records attendance (`ATTENDED`, `ABSENT`, `NOT_HELD`), and generates audit log entries on corrections.

**Request Body:**
```json
{
  "date": "2026-10-11",
  "records": [
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

### `GET /timetable/weekly-status?week_offset=0`
Read-only endpoint synthesizing weekly routine grid slots for the active semester with real saved attendance indicators (`is_attended`, `is_absent`, `is_not_held`, `is_unmarked`). Only genuine persisted `ATTENDED` records have `is_attended = true`.

### `PATCH /attendance/{id}`
Corrects an existing attendance record within the allowed 3-day window. Automatically generates an audit log entry (`AttendanceAuditLog`) recording the previous status, new status, and modification timestamp.

---

## 6. Dashboard (`/dashboard`)

### `GET /dashboard`
Provides the lightweight dashboard summary for rapid student review:
- Overall attendance summary
- Today's session summary
- Attention list (subjects falling below minimum attendance)
- Upcoming holidays/events
- Quick actionable insight
- 7-day attendance trend

---

## 7. Analytics (`/analytics`)

### `GET /analytics/overview`
Detailed semester-level analytics including aggregate counts, distribution, and status breakdowns.

### `GET /analytics/subjects`
Per-subject deterministic analytics:
- Attendance percentage
- Attended and conducted totals
- Classes needed to reach personal target
- Safe absences before falling below minimum threshold
- Status classification (`HEALTHY`, `CAUTION`, `CRITICAL`, `NO_DATA`)
- Natural-language student insight

### `GET /analytics/subjects/{id}`
Granular single-subject analytics and complete session history.

---

## 8. Calendar & Holidays (`/calendar`, `/holidays`)

### `GET /calendar`
Returns month-level markers (attended, absent, not held, holiday) and detailed day sessions for calendar views. Query param: `month=YYYY-MM`.

### `GET /holidays`
Lists upcoming and past holidays categorized into University Holidays, Festivals, Breaks, and Exams.

---

## 9. Importers (`/imports`)

> **Zero Storage Retention Policy**: Uploaded binary/PDF files are processed in transient memory (< 10MB) for extraction only. Raw file contents are **never stored** in PostgreSQL or Supabase Storage. Extracted draft records remain strictly in component memory until explicit user confirmation.

### `POST /imports/routine/parse`
Accepts a timetable document/image (PDF, PNG, JPEG, WebP up to 10MB) or CSV, validates MIME type and signatures, parses scheduled slots, and returns structured draft objects for client review.

### `POST /imports/routine/confirm`
Atomically commits reviewed and edited timetable draft entries to the student's active semester.

### `POST /imports/holidays/parse`
Accepts an academic calendar document/image or CSV, parses holiday dates and categories, and returns extracted draft holiday entries for client review.

### `POST /imports/holidays/confirm`
Atomically commits reviewed holiday draft entries to the student's semester calendar.

