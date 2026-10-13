# AttendHub — Testing Strategy & Verification Report

AttendHub employs a multi-tier automated testing strategy prioritizing mathematical determinism, boundary condition safety, multi-tenant data isolation, and responsive UI layout verification.

---

## 1. Testing Philosophy

1. **Deterministic Calculations First**: Attendance calculations directly guide student academic decisions. Every formula is isolated into pure functions and tested against boundary conditions.
2. **Auditability & Window Enforcement**: Attendance marks are restricted to the rolling 3-day window (`[today - 2 days, today]`), and corrections must produce immutable `AttendanceAuditLog` records.
3. **Semester & User Isolation**: Cross-tenant (`user_id`) and cross-semester (`semester_id`) leaks are explicitly tested and blocked.
4. **Overflow-Free Responsive UI**: Every screen and modal dialog is verified across narrow (`320px`) to large (`430px+`) mobile viewports.

---

## 2. Backend Test Suite (`pytest`)

Located in [`backend/tests/`](../backend/tests/), comprising **19 automated test cases** across 5 modules:

| Test Module | Test Cases | Scenarios Verified |
|---|---|---|
| `test_calculations.py` | 6 | Zero conducted classes (`None` / `"No attendance data yet"`), below-minimum recovery forecast ($\lceil \frac{rC - A}{1 - r} \rceil$), safe absence margin ($\lfloor \frac{A - rC}{r} \rfloor$), large buffers, raw semester aggregation vs. averaging, and `"Already at target"` state. |
| `test_boundary_calculations.py` | 5 | Safe absences strictly `0` when below minimum, exact ceiling/floor fractional boundaries, zero-conducted safety, and chronological time status resolution (`Done`, `Now`, `Upcoming`, untimed `None`). |
| `test_insight_engine.py` | 1 | Rule-based natural-language recovery and buffer insights generation. |
| `test_invariants_and_security.py` | 6 | `75.0%` defaults & clean onboarding, cross-user IDOR prevention (`403`/`404`), semester context switching isolation, file upload MIME/extension/size validation, 7-step Academic Setup Wizard transactional lifecycle, and rolling 3-day attendance edit window + read-only `GET /attendance/day`. |
| `test_api_endpoints.py` | 1 | End-to-end authenticated API workflow across registration, profile, subjects, timetable, sessions, attendance marking, corrections, dashboard, calendar, holidays, and analytics. |

### Running Backend Tests
```bash
cd backend
pytest -v
```

---

## 3. Flutter Mobile Test Suite (`flutter test`)

Located in [`mobile/test/`](../mobile/test/), comprising **58 automated unit, widget, and integration tests** across 10 test suites:

| Test File | Tests | Coverage Focus |
|---|---|---|
| `attendance_calculation_test.dart` | 10 | Client-side optimistic calculation parity with backend formulas, zero-conducted state, safe absence floor, and target recovery ceiling. |
| `setup_shell_and_import_test.dart` | 14 | `PersistentTopBar`, 7-step `AcademicSetupScreen` navigation, `RoutineImportDialog` & `HolidayImportDialog` draft parsing, editing, confirmation, and zero-retention discard. |
| `responsive_devices_and_navigation_test.dart` | 6 | Multi-device viewport verification (`320px`, `360px`, `375px`, `393px`, `412px`, `430px+`), bottom navigation tap & drag-pill interactions, and drawer routing. |
| `routine_weekly_grid_test.dart` | 6 | Weekly timetable grid rendering, real persisted attendance status badges (`ATTENDED`, `ABSENT`, `NOT_HELD`, unmarked), and week offset navigation. |
| `session_persistence_test.dart` | 6 | Token persistence in `LocalStorage`, session restoration on app launch, and clean logout state reset. |
| `remediation_phase_b_c_d_test.dart` | 5 | Rolling 3-day attendance window UI controls, semester switching provider invalidation, and setup completeness checks. |
| `landing_and_auth_screen_test.dart` | 4 | Onboarding flow, Login / Sign-Up mode switching, form validation, and Server URL configuration dialog. |
| `dashboard_analytics_settings_test.dart` | 3 | Dashboard summary cards, Analytics forecasting table, and Settings threshold configuration. |
| `subject_detail_overflow_test.dart` | 3 | Long subject titles, faculty names, and badge wrapping without `RenderFlex` overflow on narrow screens. |
| `widget_test.dart` | 1 | Core application smoke test and theme initialization. |

### Running Flutter Tests
```bash
cd mobile
flutter analyze
flutter test
```
