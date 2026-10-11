# AttendHub — Product & Engineering Context

> **Status:** Product source of truth
> **Project:** Student-focused attendance tracking and planning utility
> **Initial platform:** Flutter mobile application
> **Backend:** FastAPI + PostgreSQL (Supabase Hosted)
> **Primary UX principle:** A student should understand their attendance state in seconds and record a normal day's attendance in roughly 1–2 minutes.

## 1. Product Overview

**AttendHub** is a student-side attendance utility that gives students an independent, transparent and useful view of their academic attendance. It is not the institution's official attendance system. It allows a student to maintain a personal record from the timetable, actual class sessions, holidays and attendance entries they provide.

The product is valuable because a student may otherwise depend completely on faculty-maintained records and may not notice an incorrect entry until the attendance becomes critical. AttendHub therefore does two things: it keeps a personal attendance history and converts the raw numbers into useful actions such as how many classes are needed to reach a threshold or how many can be missed while remaining above it.

The product should feel like a polished consumer productivity application, not a traditional university ERP. It must be calm, fast, accurate, readable and predictable.

## 2. Core Problem

Students need a lightweight way to independently track attendance and understand its future impact. The product should answer:

- What is my current attendance?
- Which subjects are risky?
- Am I above the required minimum?
- How many classes must I attend to reach the minimum?
- How many classes must I attend to reach my personal target?
- How many upcoming classes can I miss while staying above the minimum?
- What holidays and academic dates are coming?

The product is therefore more than a percentage calculator.

## 3. Product Promise

**Dashboard:** Where do I stand?

**Today:** What happened today?

**Subjects:** How is each subject doing and how do I manage my subjects?

**Calendar:** When are classes, holidays and important academic dates?

**Holidays:** What breaks and no-class days are coming?

**Analytics:** What should I do about my attendance?

## 4. Final Information Architecture

### Primary screens

1. Dashboard
2. Today
3. Subjects
4. Calendar
5. Holidays
6. Analytics

### Supporting screens / flows

- onboarding
- login / registration / password reset
- academic profile
- semester management
- subject detail
- timetable setup
- routine import review
- holiday import review
- add/edit attendance
- add extra class
- profile/account surface

### Deliberately not standalone pages

**Planner** is not a separate page. Planning and prediction are core capabilities surfaced inside Dashboard, Subjects and especially Analytics.

**Settings** is not a primary page. Academic and account configuration is accessed through Profile / Academic Setup and focused sheets.

## 5. Navigation

### Desktop reference

A left sidebar contains Dashboard, Today, Subjects, Calendar, Holidays and Analytics. The **semester selector belongs at the bottom-left of the sidebar**, not in the main page header. The top-right area contains profile/account controls.

### Mobile

The primary bottom navigation is intentionally limited to the highest-frequency destinations:

**Dashboard · Today · Subjects · Calendar**

Analytics and Holidays remain first-class screens, but are opened through contextual links and secondary navigation so the bottom bar does not become crowded.

The mobile navigation should support normal tap navigation and may support an optional iOS-inspired press-drag-release tab interaction. Taps must always work and gestures must never be the only way to navigate.

## 6. Academic Profile

Profile should contain:

- full name
- university name
- course/program
- academic duration in years
- academic session
- current semester
- email/account identifier
- minimum attendance requirement
- personal target

Defaults:

- **minimum attendance = 75%** when the user has not configured it
- **personal target = 75%** until the user chooses another value

The default must be configurable, not hard-coded into every calculation.

## 7. Semester Model

Academic information is semester-scoped.

A student may have Semester 1, Semester 2, Semester 3, etc. Switching semester must change the active subjects, timetable, holidays/events, attendance and analytics context. Historical data must never be mixed between semesters.

## 8. Subject Model

Minimum required field:

- subject name

Optional:

- subject code
- faculty/teacher name
- active/inactive state

Do not force faculty details when the student does not know them. Do not display subject codes everywhere just because they exist.

## 9. Timetable / Routine

The user can set up a timetable in two ways.

### Manual

Required:

- subject

Optional:

- day
- date
- start time
- end time
- faculty
- room/location
- effective date range

A routine can represent a recurring weekly slot or a one-off session.

### Upload

The user can upload an image/PDF of a routine. The future import flow is:

**Upload → OCR/document parsing → pre-filled draft → user review → confirm → save**

The first release should not pretend OCR is reliable if it has not been implemented. The architecture must make this importer replaceable.

The same approach applies to holiday-list import.

## 10. Class Session vs Timetable

A timetable describes what is scheduled. A **Class Session** describes what actually happened on a particular date.

Example:

> Timetable: Software Engineering every Monday.
>
> Class Session: Software Engineering actually occurred on 6 October 2026.

This separation is required for correct historical attendance, cancellations, holidays and timetable changes.

## 11. Attendance States

For an actual session:

- **Attended**
- **Absent**
- **Not Held**

A holiday/cancelled/not-held session is not an absence.

Attendance is calculated as:

`Attendance % = Attended Classes / Conducted Classes × 100`

where:

`Conducted Classes = Attended + Absent`

Holiday, cancelled and not-held sessions are excluded from the denominator.

## 12. Time-Aware Today Behaviour

When valid timings exist:

- class whose end time has passed → **Done**
- class currently between start and end → **Current**
- class whose start time is still ahead → **Upcoming**

If timings are missing, do not invent a temporal state. Show the class in routine order without fabricated timing.

Teacher/faculty information is shown only when supplied.

## 13. Attendance Forecasting

For target reach:

`(A + x) / (T + x) >= r`

where `A` is attended classes, `T` is conducted classes, `x` is future classes attended and `r` is the target as a decimal.

Return the smallest integer `x >= 0` satisfying the equation.

For maximum safe future absences:

`A / (T + x) >= r`

Return the largest integer `x >= 0` satisfying the condition.

If the student is already at/above target, show a meaningful message such as **“Already at target”** rather than “Attend 0 classes.”

If below minimum, do not show a misleading “can miss” number.

## 14. Daily Workflow

The intended daily flow is:

**Open app → see today's classes → select Attended/Absent/Not Held → Save → recalculate → show result.**

The goal is roughly 1–2 minutes.

## 15. Dashboard

Dashboard is deliberately a **light glimpse of everything**.

It should show:

- overall attendance
- minimum requirement
- personal target
- current status
- today's class snapshot
- subjects needing attention
- one or two useful insights
- upcoming holiday/event
- small trend glimpse

It must not become a complete Analytics page.

## 16. Today

Today is the fastest operational screen.

It must show the current date, scheduled classes, current/done/upcoming state when timings exist, attendance controls, extra-class entry, save action and post-save impact.

## 17. Subjects

Subjects is primarily a **management** screen.

It should support:

- add subject
- edit subject
- archive/delete subject safely
- search/filter
- light attendance status/trend
- subject detail
- timetable/faculty management

The main list must stay visually clean. Heavy calculations belong in Analytics.

## 18. Calendar

Calendar is for understanding the academic timeline without putting every subject name into a month cell.

Use compact markers/dots for activity. When a date is selected, show the full list of that day's sessions in a separate detail area.

Never place eight subject names inside a calendar cell.

## 19. Holidays

Holidays is a first-class page because students need to plan around upcoming breaks.

It should support:

- upcoming holidays
- past holidays
- categories
- month/list view
- add holiday
- upload holiday list
- multi-day breaks

## 20. Analytics

Analytics is the most information-rich screen.

For every subject it should expose:

- current attendance percentage
- attended / conducted
- minimum requirement
- personal target
- number of classes that may be missed while staying above minimum
- number of consecutive classes needed to reach minimum when below it
- number needed to reach personal target
- status

It can also show overall trend, distribution, subjects on track and subjects needing attention.

Insights should be generated from deterministic rules and be written in normal student-friendly language.

## 21. Holidays and Timetable Interaction

Holidays must affect the academic calendar/session logic. A holiday must not become an absence simply because a recurring timetable contains a class on that date.

## 22. Security Expectations

Use secure authentication, strong password hashing, authorization by user ownership, server-side validation, protected file access, safe uploads, secure secrets, HTTPS in production and rate limiting on authentication-sensitive endpoints.

A student can only read/write their own academic data.

## 23. Non-Goals

Do not turn the project into:

- a faculty portal
- a university ERP
- a social network
- a chat system
- an AI-first application
- an animation showcase
- a chart-heavy dashboard

OCR/AI is a future extension, not a dependency for the core product.

## 24. Engineering Quality

The application should follow:

- strong typing
- feature-based architecture
- reusable components
- server-side business rules
- database constraints
- migrations
- automated testing
- accessible UI
- robust loading/error/empty states
- structured logging
- documented APIs
- environment-based configuration
- maintainable code

## 25. Success Criteria

A student should be able to:

1. create an academic profile
2. create/switch semesters
3. add or import subjects/routine
4. add or import holidays
5. mark daily attendance quickly
6. correct previous attendance
7. see correct subject and overall attendance
8. understand whether they are safe
9. know exactly how many classes they need to attend or may miss
10. plan around future holidays
11. use the application comfortably every day

## 26. Product Definition

AttendHub is successful when it feels less like “enter numbers and calculate percentage” and more like a reliable academic companion that turns a student's routine and attendance records into a clear current status and a useful next action.
