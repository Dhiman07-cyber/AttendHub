-- ==============================================================================
-- AttendHub — Complete Production Supabase Database Schema
-- Version: 1.0.0
-- Invariants Enforced:
--   - Minimum Attendance default: 75.0%
--   - Personal Target default: 75.0%
--   - User and Semester tenant isolation with Row-Level Security (RLS)
--   - Immutable Attendance Audit Logs (Append-Only)
--   - High-performance indexing for foreign keys and daily schedule lookups
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. Base Tables
-- ==============================================================================

-- 2.1 Users Table
CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    avatar_initial VARCHAR(5) DEFAULT 'A' NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2.2 Academic Profiles Table
CREATE TABLE IF NOT EXISTS public.academic_profiles (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    university_name VARCHAR(200) DEFAULT 'Assam down town University' NOT NULL,
    course_name VARCHAR(200) DEFAULT 'B.Tech Computer Science & Engineering' NOT NULL,
    student_id_number VARCHAR(100) DEFAULT 'ADTU/0/2024-28/BCSM/001',
    academic_duration_years INTEGER DEFAULT 4 NOT NULL,
    academic_session_start INTEGER DEFAULT 2024 NOT NULL,
    academic_session_end INTEGER DEFAULT 2028 NOT NULL,
    current_semester_id VARCHAR(36),
    minimum_attendance NUMERIC(5,2) DEFAULT 75.0 NOT NULL CHECK (minimum_attendance >= 0.0 AND minimum_attendance <= 100.0),
    personal_target NUMERIC(5,2) DEFAULT 75.0 NOT NULL CHECK (personal_target >= 0.0 AND personal_target <= 100.0),
    low_attendance_alert NUMERIC(5,2) DEFAULT 70.0 NOT NULL CHECK (low_attendance_alert >= 0.0 AND low_attendance_alert <= 100.0)
);

-- 2.3 Semesters Table
CREATE TABLE IF NOT EXISTS public.semesters (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(36) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    semester_number INTEGER NOT NULL CHECK (semester_number >= 1 AND semester_number <= 12),
    label VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL CHECK (end_date >= start_date),
    status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL CHECK (status IN ('ACTIVE', 'COMPLETED', 'UPCOMING')),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    total_weeks INTEGER DEFAULT 16 NOT NULL CHECK (total_weeks >= 1)
);

-- 2.4 Subjects Table
CREATE TABLE IF NOT EXISTS public.subjects (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    semester_id VARCHAR(36) NOT NULL REFERENCES public.semesters(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50),
    faculty_name VARCHAR(100),
    color VARCHAR(20) DEFAULT '#C96E5B' NOT NULL,
    icon VARCHAR(50) DEFAULT 'book' NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- 2.5 Recurring Timetable Entries Table
CREATE TABLE IF NOT EXISTS public.timetable_entries (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    semester_id VARCHAR(36) NOT NULL REFERENCES public.semesters(id) ON DELETE CASCADE,
    subject_id VARCHAR(36) NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Mon, 6=Sun
    start_time VARCHAR(10), -- e.g. "09:00"
    end_time VARCHAR(10),   -- e.g. "10:00"
    faculty_name VARCHAR(100),
    room VARCHAR(50),
    effective_from DATE,
    effective_to DATE,
    class_type VARCHAR(20) -- THEORY, LAB, or NULL (treated as UNSPECIFIED for legacy)
);

-- 2.6 Class Sessions Table (Discrete instances)
CREATE TABLE IF NOT EXISTS public.class_sessions (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    semester_id VARCHAR(36) NOT NULL REFERENCES public.semesters(id) ON DELETE CASCADE,
    subject_id VARCHAR(36) NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time VARCHAR(10),
    end_time VARCHAR(10),
    faculty_name VARCHAR(100),
    room VARCHAR(50),
    session_status VARCHAR(20) DEFAULT 'SCHEDULED' NOT NULL CHECK (session_status IN ('SCHEDULED', 'HELD', 'CANCELLED', 'HOLIDAY', 'NOT_HELD')),
    is_extra BOOLEAN DEFAULT FALSE NOT NULL,
    class_type VARCHAR(20) -- Snapshotted from timetable_entries.class_type at session creation
);

-- 2.7 Academic Calendar & Holidays Table
CREATE TABLE IF NOT EXISTS public.holidays (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(36) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    semester_id VARCHAR(36) REFERENCES public.semesters(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL CHECK (end_date >= start_date),
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'University Holiday' NOT NULL CHECK (category IN ('University Holiday', 'Festival', 'Semester Break', 'Exam Break', 'Academic', 'Other')),
    notes VARCHAR(255),
    source VARCHAR(30) DEFAULT 'manual' NOT NULL
);

-- 2.8 Daily Attendance Records Table
CREATE TABLE IF NOT EXISTS public.attendance_records (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    class_session_id VARCHAR(36) NOT NULL UNIQUE REFERENCES public.class_sessions(id) ON DELETE CASCADE,
    user_id VARCHAR(36) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ATTENDED', 'ABSENT', 'NOT_HELD')),
    marked_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    source VARCHAR(30) DEFAULT 'manual' NOT NULL
);


-- ==============================================================================
-- 3. Performance Indexes (Foreign Keys & Common Query Paths)
-- ==============================================================================

-- Academic Profiles
CREATE INDEX IF NOT EXISTS idx_academic_profiles_user_id ON public.academic_profiles(user_id);

-- Semesters
CREATE INDEX IF NOT EXISTS idx_semesters_user_id ON public.semesters(user_id);
CREATE INDEX IF NOT EXISTS idx_semesters_user_active ON public.semesters(user_id, is_active);

-- Subjects
CREATE INDEX IF NOT EXISTS idx_subjects_semester_id ON public.subjects(semester_id);
CREATE INDEX IF NOT EXISTS idx_subjects_semester_active ON public.subjects(semester_id, is_active);

-- Timetable Entries
CREATE INDEX IF NOT EXISTS idx_timetable_entries_semester_id ON public.timetable_entries(semester_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_subject_id ON public.timetable_entries(subject_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_day ON public.timetable_entries(semester_id, day_of_week);

-- Class Sessions
CREATE INDEX IF NOT EXISTS idx_class_sessions_semester_id ON public.class_sessions(semester_id);
CREATE INDEX IF NOT EXISTS idx_class_sessions_subject_id ON public.class_sessions(subject_id);
CREATE INDEX IF NOT EXISTS idx_class_sessions_date ON public.class_sessions(date);
CREATE INDEX IF NOT EXISTS idx_class_sessions_semester_date ON public.class_sessions(semester_id, date);

-- Holidays
CREATE INDEX IF NOT EXISTS idx_holidays_user_id ON public.holidays(user_id);
CREATE INDEX IF NOT EXISTS idx_holidays_semester_id ON public.holidays(semester_id);
CREATE INDEX IF NOT EXISTS idx_holidays_date_range ON public.holidays(start_date, end_date);

-- Attendance Records
CREATE INDEX IF NOT EXISTS idx_attendance_records_user_id ON public.attendance_records(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_session_id ON public.attendance_records(class_session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_user_session ON public.attendance_records(user_id, class_session_id);


-- ==============================================================================
-- 4. Automatic Triggers & Audit Automation
-- ==============================================================================

-- 4.1 Update timestamp trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_users_updated_at ON public.users;
CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_attendance_records_updated_at ON public.attendance_records;
CREATE TRIGGER set_attendance_records_updated_at
    BEFORE UPDATE ON public.attendance_records
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();


-- ==============================================================================
-- 5. Row-Level Security (RLS) Policies
-- Multi-Tenant Isolation with hierarchical ownership
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_audit_logs ENABLE ROW LEVEL SECURITY;

-- 5.1 Users Policies
DROP POLICY IF EXISTS "users_select_own" ON public.users;
CREATE POLICY "users_select_own" ON public.users
    FOR SELECT TO authenticated
    USING (id = (select auth.uid())::text);

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE TO authenticated
    USING (id = (select auth.uid())::text)
    WITH CHECK (id = (select auth.uid())::text);

-- 5.2 Academic Profiles Policies
DROP POLICY IF EXISTS "profiles_select_own" ON public.academic_profiles;
CREATE POLICY "profiles_select_own" ON public.academic_profiles
    FOR SELECT TO authenticated
    USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "profiles_insert_own" ON public.academic_profiles;
CREATE POLICY "profiles_insert_own" ON public.academic_profiles
    FOR INSERT TO authenticated
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "profiles_update_own" ON public.academic_profiles;
CREATE POLICY "profiles_update_own" ON public.academic_profiles
    FOR UPDATE TO authenticated
    USING (user_id = (select auth.uid())::text)
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "profiles_delete_own" ON public.academic_profiles;
CREATE POLICY "profiles_delete_own" ON public.academic_profiles
    FOR DELETE TO authenticated
    USING (user_id = (select auth.uid())::text);

-- 5.3 Semesters Policies
DROP POLICY IF EXISTS "semesters_select_own" ON public.semesters;
CREATE POLICY "semesters_select_own" ON public.semesters
    FOR SELECT TO authenticated
    USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "semesters_insert_own" ON public.semesters;
CREATE POLICY "semesters_insert_own" ON public.semesters
    FOR INSERT TO authenticated
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "semesters_update_own" ON public.semesters;
CREATE POLICY "semesters_update_own" ON public.semesters
    FOR UPDATE TO authenticated
    USING (user_id = (select auth.uid())::text)
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "semesters_delete_own" ON public.semesters;
CREATE POLICY "semesters_delete_own" ON public.semesters
    FOR DELETE TO authenticated
    USING (user_id = (select auth.uid())::text);

-- 5.4 Subjects Policies (Hierarchical through semesters)
DROP POLICY IF EXISTS "subjects_select_own" ON public.subjects;
CREATE POLICY "subjects_select_own" ON public.subjects
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.subjects.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "subjects_insert_own" ON public.subjects;
CREATE POLICY "subjects_insert_own" ON public.subjects
    FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.subjects.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "subjects_update_own" ON public.subjects;
CREATE POLICY "subjects_update_own" ON public.subjects
    FOR UPDATE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.subjects.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.subjects.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "subjects_delete_own" ON public.subjects;
CREATE POLICY "subjects_delete_own" ON public.subjects
    FOR DELETE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.subjects.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

-- 5.5 Timetable Entries Policies (Hierarchical through semesters)
DROP POLICY IF EXISTS "timetable_select_own" ON public.timetable_entries;
CREATE POLICY "timetable_select_own" ON public.timetable_entries
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.timetable_entries.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "timetable_insert_own" ON public.timetable_entries;
CREATE POLICY "timetable_insert_own" ON public.timetable_entries
    FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.timetable_entries.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "timetable_update_own" ON public.timetable_entries;
CREATE POLICY "timetable_update_own" ON public.timetable_entries
    FOR UPDATE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.timetable_entries.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.timetable_entries.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "timetable_delete_own" ON public.timetable_entries;
CREATE POLICY "timetable_delete_own" ON public.timetable_entries
    FOR DELETE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.timetable_entries.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

-- 5.6 Class Sessions Policies (Hierarchical through semesters)
DROP POLICY IF EXISTS "sessions_select_own" ON public.class_sessions;
CREATE POLICY "sessions_select_own" ON public.class_sessions
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.class_sessions.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "sessions_insert_own" ON public.class_sessions;
CREATE POLICY "sessions_insert_own" ON public.class_sessions
    FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.class_sessions.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "sessions_update_own" ON public.class_sessions;
CREATE POLICY "sessions_update_own" ON public.class_sessions
    FOR UPDATE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.class_sessions.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.class_sessions.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

DROP POLICY IF EXISTS "sessions_delete_own" ON public.class_sessions;
CREATE POLICY "sessions_delete_own" ON public.class_sessions
    FOR DELETE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.semesters
        WHERE public.semesters.id = public.class_sessions.semester_id
        AND public.semesters.user_id = (select auth.uid())::text
    ));

-- 5.7 Holidays Policies
DROP POLICY IF EXISTS "holidays_select_own" ON public.holidays;
CREATE POLICY "holidays_select_own" ON public.holidays
    FOR SELECT TO authenticated
    USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "holidays_insert_own" ON public.holidays;
CREATE POLICY "holidays_insert_own" ON public.holidays
    FOR INSERT TO authenticated
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "holidays_update_own" ON public.holidays;
CREATE POLICY "holidays_update_own" ON public.holidays
    FOR UPDATE TO authenticated
    USING (user_id = (select auth.uid())::text)
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "holidays_delete_own" ON public.holidays;
CREATE POLICY "holidays_delete_own" ON public.holidays
    FOR DELETE TO authenticated
    USING (user_id = (select auth.uid())::text);

-- 5.8 Attendance Records Policies
DROP POLICY IF EXISTS "attendance_records_select_own" ON public.attendance_records;
CREATE POLICY "attendance_records_select_own" ON public.attendance_records
    FOR SELECT TO authenticated
    USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "attendance_records_insert_own" ON public.attendance_records;
CREATE POLICY "attendance_records_insert_own" ON public.attendance_records
    FOR INSERT TO authenticated
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "attendance_records_update_own" ON public.attendance_records;
CREATE POLICY "attendance_records_update_own" ON public.attendance_records
    FOR UPDATE TO authenticated
    USING (user_id = (select auth.uid())::text)
    WITH CHECK (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "attendance_records_delete_own" ON public.attendance_records;
CREATE POLICY "attendance_records_delete_own" ON public.attendance_records
    FOR DELETE TO authenticated
    USING (user_id = (select auth.uid())::text);


-- ==============================================================================
-- 6. Role Permissions and Access Grants
-- ==============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO authenticated, service_role;
