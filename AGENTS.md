# AttendHub — Permanent Project Engineering Rules

## 1. Primary Directives & Invariants
AttendHub is a student-first attendance tracking and forecasting utility.

### Critical Product Invariants
1. **Attendance Defaults**:
   - `minimum_attendance = 75.0%`
   - `personal_target = 75.0%`
   - Never use or retain an 80% default.
2. **Attendance Calculation**:
   - $\text{Conducted} = \text{Attended} + \text{Absent}$.
   - Sessions marked `NOT_HELD`, cancelled, or scheduled on registered holidays must **never** reduce attendance or count in conducted totals.
   - If conducted count is zero ($C = 0$), status must be `"No attendance data yet"` (never `0%` or divide-by-zero).
   - Overall semester attendance must aggregate raw totals: $\frac{\sum A}{\sum C} \times 100$. Never average subject percentages.
3. **Forecasting**:
   - Classes required to reach target: $x = \max\left(0, \left\lceil \frac{r \cdot C - A}{1 - r} \right\rceil\right)$
   - Maximum safe absences: $x = \max\left(0, \left\lfloor \frac{A - r \cdot C}{r} \right\rfloor\right)$
   - If attendance is currently below minimum, safe absences must strictly be `0` (never advise missing classes).
   - If attendance is at or above target, state must be `"Already at target"`.
4. **Semester Isolation**:
   - Switching semesters switches subjects, timetable, class sessions, holidays, attendance, and analytics completely. No cross-semester leakage.
5. **User Isolation**:
   - Every database query and endpoint must enforce object-level ownership by `user_id`. No cross-user ID manipulation.
6. **Time-Aware Intelligence**:
   - When start/end times exist: past $\to$ `Done`, active $\to$ `Current`, future $\to$ `Upcoming`.
   - When timings do not exist, do not fabricate or invent a time state.
7. **Import Pipeline**:
   - Review-before-save pattern: Upload $\to$ Validate $\to$ Parse $\to$ Draft $\to$ User Review/Edit $\to$ Explicit Save.
   - Uncertain OCR/AI extraction must never silently write to production tables.
8. **Subject Lifecycle**:
   - Deleting a subject soft-archives it (`is_active = False`) to preserve historical attendance.

---

## 2. Mandatory Pre-Edit Preflight Protocol
Before ANY code modification:
1. Understand the user's intended outcome.
2. Inspect the relevant current code.
3. Inspect current architecture and dependencies.
4. Identify the affected domain and data contracts.
5. Identify all relevant product invariants.
6. Load relevant specialist skills (`flutter`, `dart`, `superpowers`, `owasp-security-audit`, `fastapi-sqlalchemy-postgres`).
7. Consult current authoritative guidance when version-sensitive or uncertain.
8. Check security implications (ASVS V2-V5, object ownership, input boundaries).
9. Check UX/accessibility implications (semantics, contrast, touch targets, state handling).
10. Check performance implications (rebuilds, async queries, N+1 loading).
11. Check reliability and data-integrity implications (transactions, soft deletes).
12. Determine whether the change is strictly necessary.
13. Form a concise implementation plan.
14. Implement with minimal safe changes.

---

## 3. Mandatory Bug-Fixing Protocol
For any bug or issue:
1. **Observe**: Note exact error, symptoms, and conditions.
2. **Reproduce**: Run or write a failing test.
3. **Isolate**: Trace the execution path and identify root cause.
4. **Patch**: Apply the minimal safe, correct fix preserving existing invariants.
5. **Regression Test**: Add or update an automated test covering the root cause.
6. **Verify**: Run focused tests, run the full test suite, inspect the diff.
7. Never claim a bug is "fixed" without passing verification evidence.

---

## 4. Mandatory Optimization Protocol
When asked to optimize, make faster, clean up, or refactor:
1. Identify the exact bottleneck with measurable evidence.
2. Establish baseline metrics before touching code.
3. Verify that changes preserve correctness, security, accessibility, and invariants.
4. Provide post-change verification.
5. Never call a refactor an optimization without measured evidence.

---

## 5. Mandatory UI / UX Standards
- **Design Language**: Warm off-white `#F7F1EC`, warm surface `#FFFDFC`, terracotta `#C96E5B`, sage `#72A68A`, amber `#D9A35B`, coral `#D86A62`.
- **Liquid Glass**: Translucent `BackdropFilter` cards with low opacity borders and soft shadows; fallback gracefully when needed.
- **State Coverage**: Every view must handle Loading, Empty, Error, and Success states.
- **Accessibility**: Minimum touch targets 44x44, readable contrast, semantic labels, `MediaQuery` text scaling support.
- Do not add random redesigns or excess visual clutter.

---

## 6. Mandatory Security Standards
- Baseline: OWASP ASVS 5.0.0 and OWASP API Security Top 10.
- Argon2id password hashing.
- Token expiration and validation on all protected endpoints.
- Object ownership checks on every database entity query (`user_id`).
- Input validation via Pydantic v2.
- Secure upload processing: MIME checks, size limits, server UUID file keys.

---

## 7. Mandatory Anti-Architecture-Churn Rule
Do NOT introduce external infrastructure (Redis, Kafka, Celery, microservices) unless a concrete, demonstrated requirement demands it.
Maintain clean separation:
`Presentation -> Application/State -> Domain/Calculation -> Data/ORM`.
All attendance mathematics must remain pure and deterministic in `app/calculations/`.
