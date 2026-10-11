# AttendHub — Testing Strategy & Verification Report

AttendHub employs a multi-tier testing strategy prioritizing mathematical correctness, boundary condition handling, data isolation, and integration reliability.

---

## 1. Testing Philosophy

1. **Deterministic Calculations First**: Attendance rules directly impact student academic standing. Every formula is isolated into pure functions and tested against edge cases.
2. **Auditability**: Attendance edits must produce an immutable audit log with previous status, new status, and timestamp.
3. **Semester & User Isolation**: Cross-tenant and cross-semester leaks are validated and blocked.

---

## 2. Test Matrix & Edge-Case Coverage

| Scenario | Tested In | Expected Behavior |
|---|---|---|
| **Zero conducted classes** | `test_calculations.py` | Returns `None` (`conducted=0`), UI displays *"No attendance data yet"* rather than 0% or division error. |
| **Current attendance = 100%** | `test_calculations.py` | Accurate safe absences calculated, target recovery returns `0` with *"Already at target"*. |
| **Current attendance below minimum** | `test_calculations.py` | Safe absences strictly returns `0` (never advises missing classes when deficient). |
| **Current attendance at/above target** | `test_calculations.py` | Target recovery returns `0` with status confirmation. |
| **Target recovery formula** | `test_calculations.py` | Solves $\lceil \frac{r \cdot C - A}{1 - r} \rceil$ accurately for fractional boundaries. |
| **Safe absences formula** | `test_calculations.py` | Solves $\lfloor \frac{A - r \cdot C}{r} \rfloor$ accurately without dipping below threshold. |
| **Not-Held / Cancelled exclusion** | `test_calculations.py` | Classes marked `NOT_HELD` or cancelled do not increment conducted count. |
| **Holiday exclusion** | `test_calculations.py` | Holidays are excluded from conducted totals. |
| **Whole-semester aggregation** | `test_calculations.py` | Raw sums aggregated ($\sum A / \sum C$), never averaging subject percentages. |
| **Registration auto-onboarding** | `test_api_endpoints.py` | Creates user, profile, default semester 5, and subjects in a single transaction (or clean without demo). |
| **Token lifecycle & auth** | `test_api_endpoints.py` | Validates Argon2id password hash, JWT generation, and protected route access. |
| **Insight engine natural language** | `test_insight_engine.py` | Validates natural language advice suitable for students. |
| **75% Default Invariants** | `test_invariants_and_security.py` | Verifies default minimum attendance and personal target are strictly 75.0% across profile and auth. |
| **Cross-User IDOR Prevention** | `test_invariants_and_security.py` | Authenticated user A cannot read/mutate subjects or data belonging to user B (403 Forbidden). |
| **Semester Context Isolation** | `test_invariants_and_security.py` | Switching active semester completely isolates subject lists and analytics; no cross-semester leaks. |
| **File Upload Security & MIME check** | `test_invariants_and_security.py` | Rejects executable/unsupported extensions and oversized files; validates MIME types. |
| **Below Minimum Safe Absences** | `test_boundary_calculations.py` | Confirms safe absences is strictly 0 when attendance is below minimum (never advises absence). |
| **Exact Recovery & Target Ceiling** | `test_boundary_calculations.py` | Validates $\lceil \frac{r \cdot C - A}{1 - r} \rceil$ ceiling and fractional target bounds. |
| **Untimed Session Stability** | `test_boundary_calculations.py` | Verifies chronological time status resolution (`DONE`, `CURRENT`, `UPCOMING`) and untimed session safety. |

---

## 3. Running Backend Tests

Navigate to the `backend/` directory and execute:

```bash
pytest -v
```

### Test Output Verification:
```text
============================= test session starts =============================
platform win32 -- Python 3.14.5, pytest-9.1.1, pluggy-1.6.0
rootdir: C:\Users\ADMIN\Desktop\Projects\AttendHub\backend
configfile: pyproject.toml
testpaths: tests
plugins: anyio-4.14.0, asyncio-1.4.0
collected 18 items

tests/test_api_endpoints.py::test_full_api_flow PASSED                   [  5%]
tests/test_boundary_calculations.py::test_below_minimum_safe_absences_is_always_zero PASSED [ 11%]
tests/test_boundary_calculations.py::test_exact_target_and_recovery_equations PASSED [ 16%]
tests/test_boundary_calculations.py::test_safe_absences_margin_equation PASSED [ 22%]
tests/test_boundary_calculations.py::test_zero_conducted_safe_behavior PASSED [ 27%]
tests/test_boundary_calculations.py::test_time_status_chronology_and_untimed_stability PASSED [ 33%]
tests/test_calculations.py::test_subject_zero_conducted_classes PASSED   [ 38%]
tests/test_calculations.py::test_subject_below_minimum_recovery_forecast PASSED [ 44%]
tests/test_calculations.py::test_subject_safe_absence_forecast PASSED    [ 50%]
tests/test_calculations.py::test_subject_large_safe_absence_buffer PASSED [ 55%]
tests/test_calculations.py::test_overall_metrics_aggregation_vs_averaging PASSED [ 61%]
tests/test_calculations.py::test_target_already_reached PASSED           [ 66%]
tests/test_insight_engine.py::test_generate_insights_triggers_recovery PASSED [ 72%]
tests/test_invariants_and_security.py::test_75_percent_defaults_and_clean_onboarding PASSED [ 77%]
tests/test_invariants_and_security.py::test_cross_user_isolation_and_idor_prevention PASSED [ 83%]
tests/test_invariants_and_security.py::test_semester_switching_context_isolation PASSED [ 88%]
tests/test_invariants_and_security.py::test_file_upload_security_validation PASSED [ 94%]
tests/test_invariants_and_security.py::test_academic_setup_wizard_lifecycle_and_completeness PASSED [100%]

============================= 18 passed in 120s ===============================
```

---

## 4. Running Flutter Tests

Navigate to the `mobile/` directory and execute:

```bash
flutter test
```

### Verified Flutter Scenarios (40 Tests Passed):
- `attendance_calculation_test.dart` (5 tests):
  - Validates client-side optimistic calculation matching server mathematical behavior.
  - Validates zero conducted handling (`conducted == 0` -> null percentage / "No attendance data yet").
  - Validates safe absence limits ($x = \lfloor \frac{A - r \cdot C}{r} \rfloor$ and $0$ when below threshold).
  - Validates recovery required calculations ($x = \lceil \frac{r \cdot C - A}{1 - r} \rceil$).
- `widget_test.dart` (17 tests):
  - Theme token validation, liquid glass cards, landscape vector headers, and attendance controls.
- `setup_shell_and_import_test.dart` (18 tests):
  - PersistentTopBar: Menu button, title, notification badge, and avatar render cleanly.
  - AcademicSetupScreen: 7-step navigation, profile inputs, subject creation, and review step validation.
  - Responsive Viewport Verification: RenderFlex overflow-free validation across `320px`, `360px`, `375px`, `393px`, `412px`, and `430px+` viewports.
  - RoutineImportDialog: CSV/text timetable parsing, editable draft rows, and explicit discard/save callbacks.
  - HolidayImportDialog: CSV/text holiday parsing, category extraction, editable cards, and atomic save confirmation.
  - Zero-retention draft lifecycle: Discarding an import clears local draft state with zero persisted entities.

