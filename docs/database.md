# AttendHub — Database Architecture & Schema Reference

AttendHub uses a relational persistence model engineered for transactional consistency, referential integrity, and complete semester isolation.

---

## 1. Entity Relationship Overview

```text
┌──────────────┐
│    users     │
└──────┬───────┘
       │ 1:1
       ├─────────────────────────┐
       ▼                         ▼
┌──────────────┐          ┌──────────────┐
│  profiles    │          │  semesters   │
└──────────────┘          └──────┬───────┘
                                 │ 1:N
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
       ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
       │   subjects   │   │  timetable   │   │   holidays   │
       └──────┬───────┘   └──────────────┘   └──────────────┘
              │ 1:N
              ▼
       ┌──────────────┐
       │class_sessions│
       └──────┬───────┘
              │ 1:1
              ▼
       ┌──────────────┐
       │  attendance  │
       └──────┬───────┘
              │ 1:N
              ▼
       ┌──────────────┐
       │  audit_logs  │
       └──────────────┘
```

---

## 2. Table Specifications

### 2.1 `users`
Represents student accounts with Argon2id password hashes.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | UUID string identifier |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL, INDEX | Verified email address |
| `hashed_password` | VARCHAR(255) | NOT NULL | Argon2id secure hash |
| `full_name` | VARCHAR(100) | NOT NULL | Student's full name |
| `is_active` | BOOLEAN | DEFAULT TRUE | Account state |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Account creation |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last profile update |

### 2.2 `academic_profiles`
Maintains institutional and academic configuration.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Profile UUID |
| `user_id` | VARCHAR(36) | FK(`users.id`), UNIQUE, INDEX | Owner reference |
| `university_name` | VARCHAR(150) | NULLABLE | University or College |
| `course_name` | VARCHAR(100) | NULLABLE | Degree / Program |
| `academic_duration_years` | INTEGER | DEFAULT 4 | Program length in years |
| `academic_session_start` | DATE | NULLABLE | Academic session start date |
| `academic_session_end` | DATE | NULLABLE | Academic session end date |
| `current_semester` | INTEGER | DEFAULT 1 | Active semester integer |
| `minimum_attendance` | FLOAT | DEFAULT 75.0 | Mandatory threshold (0-100) |
| `personal_target` | FLOAT | DEFAULT 75.0 | Student personal goal (0-100) |

### 2.3 `semesters`
Defines discrete academic terms. All subjects, timetables, and sessions belong to a semester.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Semester UUID |
| `user_id` | VARCHAR(36) | FK(`users.id`), NOT NULL, INDEX | Owner reference |
| `semester_number` | INTEGER | NOT NULL | Semester digit (1-12) |
| `label` | VARCHAR(100) | NOT NULL | Display name (e.g., "Semester 5") |
| `start_date` | DATE | NOT NULL | Semester start date |
| `end_date` | DATE | NOT NULL | Semester end date |
| `is_active` | BOOLEAN | DEFAULT FALSE, INDEX | Active semester flag |

### 2.4 `subjects`
Course units enrolled within a specific semester.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Subject UUID |
| `semester_id` | VARCHAR(36) | FK(`semesters.id`), NOT NULL, INDEX | Semester scoping |
| `name` | VARCHAR(150) | NOT NULL | Subject title |
| `code` | VARCHAR(50) | NULLABLE | Course code (e.g. CS-501) |
| `faculty_name` | VARCHAR(100) | NULLABLE | Instructor name |
| `is_active` | BOOLEAN | DEFAULT TRUE, INDEX | Active / Archived flag |
| `color_tag` | VARCHAR(20) | NULLABLE | Hex color code for UI |

*Note: Deleting a subject performs a soft archive (`is_active = FALSE`) to protect attendance history.*

### 2.5 `timetable_entries`
Recurring weekly routine schedule.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Timetable UUID |
| `semester_id` | VARCHAR(36) | FK(`semesters.id`), NOT NULL, INDEX | Semester scoping |
| `subject_id` | VARCHAR(36) | FK(`subjects.id`), NOT NULL, INDEX | Subject reference |
| `day_of_week` | INTEGER | NOT NULL | 0 = Monday, 6 = Sunday |
| `start_time` | TIME | NULLABLE | Class start time |
| `end_time` | TIME | NULLABLE | Class end time |
| `room` | VARCHAR(50) | NULLABLE | Classroom / Hall |
| `faculty_name` | VARCHAR(100) | NULLABLE | Faculty override |

### 2.6 `class_sessions`
Discrete class instances on specific calendar dates.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Session UUID |
| `timetable_entry_id` | VARCHAR(36) | FK(`timetable_entries.id`), NULLABLE, INDEX | Originating recurring timetable slot |
| `semester_id` | VARCHAR(36) | FK(`semesters.id`), NOT NULL, INDEX | Semester scoping |
| `subject_id` | VARCHAR(36) | FK(`subjects.id`), NOT NULL, INDEX | Subject reference |
| `date` | DATE | NOT NULL, INDEX | Date of class occurrence |
| `start_time` | TIME | NULLABLE | Session start time |
| `end_time` | TIME | NULLABLE | Session end time |
| `room` | VARCHAR(50) | NULLABLE | Classroom / Lab |
| `session_status` | VARCHAR(20) | DEFAULT 'SCHEDULED' | SCHEDULED / CANCELLED |
| `is_extra` | BOOLEAN | DEFAULT FALSE | Extra class indicator |

*Note: Read endpoints (GET `/attendance/day`, GET `/timetable/weekly-status`) synthesize virtual slots on-the-fly without side-effect DB writes. Concrete `class_sessions` are materialized only when the student explicitly confirms/saves attendance for that date.*

### 2.7 `attendance_records`
Student attendance marks for individual sessions.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Record UUID |
| `class_session_id` | VARCHAR(36) | FK(`class_sessions.id`), NOT NULL, INDEX | Class session reference |
| `student_id` | VARCHAR(36) | FK(`users.id`), NOT NULL, INDEX | Student reference |
| `status` | VARCHAR(20) | NOT NULL | ATTENDED, ABSENT, NOT_HELD |
| `marked_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Initial recording timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last modification |
| `source` | VARCHAR(50) | DEFAULT 'MANUAL' | MANUAL, IMPORT, etc. |

### 2.8 `attendance_audit_logs`
Immutable audit log tracing all attendance corrections.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Log UUID |
| `attendance_record_id` | VARCHAR(36) | FK(`attendance_records.id`), NOT NULL, INDEX | Target record |
| `user_id` | VARCHAR(36) | FK(`users.id`), NOT NULL | Actor user |
| `original_status` | VARCHAR(20) | NOT NULL | Previous state |
| `new_status` | VARCHAR(20) | NOT NULL | New state |
| `changed_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Mutation timestamp |
| `reason` | VARCHAR(255) | NULLABLE | Correction reason |

### 2.9 `holidays`
Registered academic holidays, festivals, and breaks.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(36) | PRIMARY KEY | Holiday UUID |
| `user_id` | VARCHAR(36) | FK(`users.id`), NOT NULL, INDEX | Student owner |
| `semester_id` | VARCHAR(36) | FK(`semesters.id`), NULLABLE, INDEX | Semester scoping |
| `title` | VARCHAR(150) | NOT NULL | Holiday title |
| `category` | VARCHAR(50) | NOT NULL | Holiday category |
| `start_date` | DATE | NOT NULL, INDEX | Holiday start |
| `end_date` | DATE | NOT NULL, INDEX | Holiday end |
| `notes` | TEXT | NULLABLE | Additional context |

---

## 3. Database Indexes

- `ix_users_email`: B-tree index on user email for fast authentication lookups.
- `ix_semesters_user_active`: Composite indexing on user and active flag.
- `ix_class_sessions_date`: Index on session dates for efficient Daily Today and Calendar range queries.
- `ix_attendance_records_session`: Foreign key index enabling instant lookup of session status.

---

## 4. Cloud Supabase Architecture & Row-Level Security (RLS)

AttendHub is backed by a production PostgreSQL database hosted on **Supabase** (`vaoesgmcrzywmkhbjqvq`).

### Complete Schema File:
The comprehensive single-file schema definition is maintained in:
- [`supabase/schema.sql`](../supabase/schema.sql)

### Security & RLS Features:
1. **Multi-Tenant Row-Level Security**:
   - Every table in the `public` schema has `ROW LEVEL SECURITY` enabled.
   - Ownership checks combine `TO authenticated` with `USING ((select auth.uid())::text = user_id)` (or hierarchical semester lookup).
2. **Strict Immutability for Audit Trails**:
   - `attendance_audit_logs` has `UPDATE` and `DELETE` policies unconditionally set to `USING (false)`.
   - Automated triggers (`log_attendance_correction()`) append audit records when `status` is mutated.
3. **Function Security**:
   - Database functions declare `SECURITY INVOKER` and explicit `SET search_path = public` to mitigate search path escalation risks.
4. **Foreign Key Performance Indexes**:
   - Every foreign key and tenant scoping filter (`user_id`, `semester_id`, `class_session_id`, `date`) is indexed to ensure efficient plan execution and prevent table locks.

---

## 5. Draft Document Import & Zero Storage Retention Policy

AttendHub enforces a strict **Zero-Retention Guarantee** for uploaded academic documents (timetables, holiday lists):

1. **No Database File Storage**:
   - PostgreSQL schema contains **zero binary columns** (`BYTEA`, `BLOB`, or Base64 strings) for raw uploaded files.
   - Timetable documents and holiday circulars are strictly transient inputs.
2. **No Permanent Object Storage**:
   - AttendHub does not provision or persist files to Supabase Storage buckets.
3. **In-Memory Draft Extraction**:
   - Uploaded files are validated for MIME type and file signature in bounded FastAPI memory buffers (< 10MB).
   - Extracted routine entries and holidays are converted to structured JSON responses and streamed to the client as editable drafts.
   - Raw file buffers and temporary descriptors are immediately closed and unlinked (`unlink()`).
4. **Confirmed Persistence Only**:
   - Only validated, user-confirmed domain entities (`subjects`, `timetable_entries`, `holidays`) are inserted into PostgreSQL.

---

## 6. Semester Scoping & Historical Preservation Semantics

1. **Global vs Semester Scoping**:
   - **Global Entities**: `users`, `academic_profiles` (University Name, Course, Duration, Graduation Start/End Years).
   - **Semester-Scoped Entities**: `semesters`, `subjects`, `timetable_entries`, `class_sessions`, `attendance_records`, `attendance_audit_logs`, `holidays`.
2. **History Preservation**:
   - When a student switches semesters (`POST /api/v1/semesters/{id}/activate`), the previous semester's records are preserved intact.
   - AttendHub does not delete, overwrite, or mutate past attendance records upon semester switching.
   - Enrolled subjects from prior semesters remain associated with their respective `semester_id` and are not cloned into new semesters without explicit user import.

---

## 7. Multi-Entity Atomic Setup Transactions

The Academic Setup Wizard commits multi-entity configurations through a single atomic database transaction (`POST /api/v1/profile/setup`):

```text
BEGIN TRANSACTION;
  1. Lock & Update user academic profile (name, university, course, graduation years).
  2. Create or verify target semester (set is_active = TRUE, deactivate other semesters).
  3. Create subjects linked to semester_id.
  4. Create timetable routine entries linked to subjects.
  5. Create semester-bound academic holidays.
  6. (Optional) Create baseline attendance sessions and attendance records.
COMMIT;
```

If any validation rule fails or an exception occurs during the process, the entire transaction rolls back cleanly, leaving zero orphaned or half-configured records.

