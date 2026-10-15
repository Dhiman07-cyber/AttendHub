# AttendHub Attendance Mathematics & Forecasting Implementation Report

**Date:** October 14, 2026  
**Implementation Scope:** Complete attendance calculation layer, Theory/Lab tracking, holiday-aware forecasting, semester-bound projections, and data integrity fixes.

---

## Executive Summary

This implementation delivers a complete, mathematically correct, and database-backed attendance calculation and forecasting system for AttendHub. All calculations are centralized in domain services, removing hardcoded formulas from UI components. The system now supports:

✅ **Theory and Lab breakdown tracking** with separate metrics  
✅ **Holiday-aware future class enumeration** through semester end  
✅ **Projected final attendance** if all remaining classes are attended  
✅ **Semester-end absence budget** calculations  
✅ **No-data edge case handling** (None instead of 0 for unavailable metrics)  
✅ **Semester date boundary enforcement** in attendance submission  
✅ **33/33 backend tests passing** including new forecast engine tests  

---

## 1. Schema Changes — Database Migrations

### 1.1 New Fields Added

**`timetable_entries` table:**
- Added `class_type VARCHAR(20)` — Values: `THEORY`, `LAB`, `UNSPECIFIED`, or `NULL` (treated as `UNSPECIFIED`)
- Purpose: Classify recurring weekly slots by class type
- Nullable: Yes (legacy rows default to `NULL`/`UNSPECIFIED`)

**`class_sessions` table:**
- Added `class_type VARCHAR(20)` — Snapshotted from `timetable_entries.class_type` at session creation
- Purpose: Preserve class type on materialized session records
- Nullable: Yes (legacy rows default to `NULL`/`UNSPECIFIED`)

### 1.2 Migration Files Created

**Alembic Migration:**
- File: `backend/migrations/versions/a1b2c3d4e5f6_add_class_type_to_timetable_and_sessions.py`
- Revision ID: `a1b2c3d4e5f6`
- Parent: `5d88f7da594e`
- Operations:
  - `ALTER TABLE timetable_entries ADD COLUMN class_type VARCHAR(20)`
  - `ALTER TABLE class_sessions ADD COLUMN class_type VARCHAR(20)`

**SQLite Test Database Migration:**
- Script: `backend/apply_class_type_migration.py`
- Applied to: `attendhub.db`, `test_attendhub.db`, `../test_attendhub.db`
- Status: ✅ Successfully applied

**Supabase Production Schema:**
- Updated: `supabase/schema.sql`
- Status: Schema definition updated, deployment required

### 1.3 Data Model Integrity

**Existing tables reused (no new tables added):**
- `users` — User authentication and profile ownership
- `academic_profiles` — Minimum attendance (75.0%), personal target (75.0%)
- `semesters` — Semester date bounds (`start_date`, `end_date`)
- `subjects` — Subject definitions and metadata
- `timetable_entries` — Recurring weekly slots (now with `class_type`)
- `class_sessions` — Concrete dated occurrences (now with `class_type`)
- `attendance_records` — Actual attendance outcomes (`ATTENDED`, `ABSENT`, `NOT_HELD`)
- `holidays` — Holiday date ranges for forecast exclusion

**Aggregate counts are computed, not stored:**
- Subject `attended` / `absent` / `conducted` totals = `COUNT()` from attendance records
- Theory/Lab breakdown = `COUNT()` with `class_type` filter
- No redundant summary tables created

---

## 2. Calculation Engine Fixes

### 2.1 Fixed No-Data Edge Cases

**Problem:** `calculate_subject_metrics` returned `classes_needed_for_min=0` when `conducted=0`, incorrectly implying "already at target."

**Solution:**
```python
# Before (incorrect):
classes_needed_for_min = 0  # Wrong for zero-data case

# After (correct):
classes_needed_for_min = None  # Cannot calculate recovery for zero conducted classes
classes_needed_for_target = None  # Cannot calculate target path for zero conducted classes
```

**Affected functions:**
- `calculate_subject_metrics` in `backend/app/calculations/attendance_engine.py`
- `calculate_overall_metrics` in `backend/app/calculations/attendance_engine.py`

**Test coverage:**
- `tests/test_calculations.py::test_subject_zero_conducted_classes` ✅ Passes
- `tests/test_boundary_calculations.py::test_zero_conducted_safe_behavior` ✅ Passes

### 2.2 Theory/Lab Breakdown Calculation

**New function added:** `calculate_subject_with_type_breakdown`

**Input parameters:**
- Overall: `attended`, `absent`
- Theory: `theory_attended`, `theory_absent`
- Lab: `lab_attended`, `lab_absent`
- Targets: `minimum_requirement`, `personal_target`

**Returns:**
```python
{
    **overall_metrics,  # Overall subject percentage and forecast
    "theory_metrics": {...},  # Theory-only breakdown
    "lab_metrics": {...},  # Lab-only breakdown
    "unclassified_attended": int,  # Legacy rows without class_type
    "unclassified_conducted": int
}
```

**Key rule:** Overall conducted = Theory conducted + Lab conducted + Unclassified conducted (count-based aggregation, not percentage averaging)

---

## 3. Forecast Engine Implementation

### 3.1 New Module: `backend/app/calculations/forecast_engine.py`

**Purpose:** Enumerate future scheduled classes from timetable definitions without database writes.

**Core functions:**

1. **`enumerate_future_class_dates`**
   - Enumerates future occurrences from recurring timetable entries
   - Respects semester start/end dates (inclusive)
   - Excludes holiday date ranges
   - Filters by working days mask (default Mon-Sat: `{0,1,2,3,4,5}`)
   - Honors `effective_from` / `effective_to` on timetable entries
   - Returns: List of `{date, subject_id, timetable_entry_id, class_type, day_of_week}`

2. **`calculate_future_classes_count`**
   - Counts future sessions with optional filters:
     - `subject_id`: Count only one subject's classes
     - `class_type_filter`: Count only `THEORY`, `LAB`, or `UNSPECIFIED`
   - Returns: Integer count

3. **`calculate_projected_final_attendance`**
   - Formula: `(current_attended + future_classes) / (current_conducted + future_classes) * 100`
   - Assumes all future classes are attended
   - Returns: Percentage (0-100) or `None` if no future data

4. **`calculate_max_future_absences_by_semester_end`**
   - Formula: `floor(current_attended + future_classes - target_ratio * (current_conducted + future_classes))`
   - Clamps between 0 and `future_classes`
   - Returns: Integer or `None` if target unreachable even with perfect attendance

5. **`calculate_forecast_status`**
   - Validates prerequisites for forecasting
   - Returns:
     - `COMPLETE` — All prerequisites met
     - `INCOMPLETE_SEMESTER_DATES` — Missing start/end dates
     - `INCOMPLETE_TIMETABLE` — No timetable entries
     - `INCOMPLETE_WORKING_DAYS` — Working days not configured

### 3.2 Forecast Test Suite

**File:** `backend/tests/test_forecast_engine.py`

**Test coverage (10 tests, all passing):**
- ✅ Basic weekly recurrence enumeration
- ✅ Holiday exclusion (single day and multi-day ranges)
- ✅ Semester start/end boundary enforcement
- ✅ Working days mask filtering
- ✅ Effective date range constraints on timetable entries
- ✅ Subject and class_type filtering in counts
- ✅ Projected final attendance calculations
- ✅ Maximum future absences by semester end
- ✅ Forecast completeness status detection
- ✅ Multi-day holiday range exclusion

---

## 4. API Schema Updates

### 4.1 New Response Fields Added

**`SubjectAnalyticsOut` (in `backend/app/schemas/analytics.py`):**
```python
# Theory/Lab breakdown
theory_metrics: Optional[TypeBreakdownMetrics] = None
lab_metrics: Optional[TypeBreakdownMetrics] = None
unclassified_attended: int = 0
unclassified_conducted: int = 0

# Forecast fields
remaining_classes: Optional[int] = None
remaining_theory_classes: Optional[int] = None
remaining_lab_classes: Optional[int] = None
projected_final_percentage: Optional[float] = None
max_future_absences_for_min: Optional[int] = None
max_future_absences_for_target: Optional[int] = None
forecast_status: Optional[str] = None
```

**`TypeBreakdownMetrics` schema (new):**
```python
class TypeBreakdownMetrics(BaseModel):
    attended: int = 0
    absent: int = 0
    conducted: int = 0
    percentage: Optional[float] = None
    has_data: bool = False
    status: str = "NO_DATA"
    status_label: str = "No data yet"
    classes_needed_for_min: Optional[int] = None
    classes_needed_for_target: Optional[int] = None
    max_safe_absences: int = 0
    can_miss_message: Optional[str] = None
    recovery_message: Optional[str] = None
```

**`AnalyticsOverviewOut` (semester-wide forecast):**
```python
total_remaining_classes: Optional[int] = None
projected_overall_final_percentage: Optional[float] = None
forecast_status: Optional[str] = None
```

### 4.2 Timetable and Session Schemas

**`TimetableEntryOut`, `TimetableEntryCreate`, `TimetableEntryUpdate`:**
- Added `class_type: Optional[str] = None`

**`ClassSessionOut`:**
- Added `class_type: Optional[str] = None`

**`WeeklySlotStatusOut`:**
- Changed from hardcoded `class_type: str = "Theory"` to `class_type: Optional[str] = None`

---

## 5. Service Layer Updates

### 5.1 Analytics Service (`backend/app/services/analytics_service.py`)

**Major refactor:**

1. **`_fetch_subject_attendance_counts` now returns Theory/Lab breakdown:**
```python
{
    "subject_id": {
        "attended": total_att,
        "absent": total_ab,
        "theory_attended": theory_att,
        "theory_absent": theory_ab,
        "lab_attended": lab_att,
        "lab_absent": lab_ab,
        "unspecified_attended": unc_att,
        "unspecified_absent": unc_ab
    }
}
```

2. **`get_analytics_overview` now includes:**
   - Theory/Lab breakdown using `calculate_subject_with_type_breakdown`
   - Future classes enumeration via forecast engine
   - Projected final percentage calculations
   - Maximum future absences by semester end
   - Forecast completeness status

3. **Holiday and timetable integration:**
   - Fetches `TimetableEntry` records
   - Fetches `Holiday` records for date exclusion
   - Passes to forecast engine for future class enumeration

### 5.2 Attendance Service (`backend/app/services/attendance_service.py`)

**Snapshots `class_type` when materializing sessions:**
```python
new_sess = ClassSession(
    # ... other fields ...
    class_type=tt_obj.class_type  # Snapshot from timetable entry
)
```

**All `ClassSessionOut` responses now include `class_type`:**
- Virtual sessions: `class_type=tt.class_type or "UNSPECIFIED"`
- Concrete sessions: `class_type=cs.class_type or "UNSPECIFIED"`

### 5.3 Timetable Service (`backend/app/services/timetable_service.py`)

**`list_weekly_status` now uses actual `class_type`:**
```python
WeeklySlotStatusOut(
    # ... other fields ...
    class_type=sess_obj.class_type if sess_obj else (e.class_type or "UNSPECIFIED")
)
```

### 5.4 Holiday Service (`backend/app/services/holiday_service.py`)

**Fixed:** Removed hardcoded `date(2026, 10, 8)` in `update_holiday`, replaced with `date.today()`

---

## 6. Test Results

### 6.1 All Tests Passing ✅

```
33 passed in 2.57s
```

**Test breakdown:**
- `test_calculations.py`: 6 tests ✅
- `test_boundary_calculations.py`: 5 tests ✅
- `test_forecast_engine.py`: 10 tests ✅ (NEW)
- `test_insight_engine.py`: 3 tests ✅
- `test_invariants_and_security.py`: 5 tests ✅
- `test_api_endpoints.py`: 4 tests ✅

### 6.2 Key Test Validations

**Calculation correctness:**
- Zero-data returns `None` for recovery metrics ✅
- Below-minimum safe absences = 0 ✅
- Recovery formula: `ceil((r*C - A)/(1-r))` ✅
- Safe absence formula: `floor((A - r*C)/r)` ✅
- Overall aggregates counts (never averages percentages) ✅

**Forecast accuracy:**
- Future classes respect semester bounds ✅
- Holidays exclude dates correctly ✅
- Working days filter applied ✅
- Effective date ranges honored ✅
- Subject and class_type filters work ✅
- Projected final % calculated correctly ✅
- Max future absences clamped properly ✅

**Data integrity:**
- Cross-user isolation enforced ✅
- Semester switching context isolation ✅
- Attendance edit window (3-day) enforced ✅
- GET requests never write data ✅

---

## 7. Outstanding Work — Flutter Mobile Integration

### 7.1 Model Updates Required

**File:** `mobile/lib/shared/models/subject_model.dart`

**Add fields to `SubjectModel`:**
```dart
// Theory/Lab metrics
final TypeBreakdownMetrics? theoryMetrics;
final TypeBreakdownMetrics? labMetrics;
final int unclassifiedAttended;
final int unclassifiedConducted;

// Forecast fields
final int? remainingClasses;
final int? remainingTheoryClasses;
final int? remainingLabClasses;
final double? projectedFinalPercentage;
final int? maxFutureAbsencesForMin;
final int? maxFutureAbsencesForTarget;
final String? forecastStatus;
```

**New model:** `TypeBreakdownMetrics`
```dart
class TypeBreakdownMetrics {
  final int attended;
  final int absent;
  final int conducted;
  final double? percentage;
  final bool hasData;
  final String status;
  final String statusLabel;
  final int? classesNeededForMin;
  final int? classesNeededForTarget;
  final int maxSafeAbsences;
  final String? canMissMessage;
  final String? recoveryMessage;
  
  factory TypeBreakdownMetrics.fromJson(Map<String, dynamic> json) { ... }
}
```

**File:** `mobile/lib/shared/models/analytics_model.dart`

**Add to `AnalyticsOverviewModel`:**
```dart
final int? totalRemainingClasses;
final double? projectedOverallFinalPercentage;
final String? forecastStatus;
```

### 7.2 UI Updates Required

**Subject Detail Screen** (`mobile/lib/features/subjects/subject_detail_screen.dart`)

**Current issue:** Hardcoded `"Target: 75.0%"` instead of reading from profile

**Required changes:**
1. Fetch `personal_target` from API/profile provider
2. Display Theory and Lab metrics separately:
   ```dart
   if (subject.theoryMetrics != null && subject.theoryMetrics!.hasData) {
     _buildTypeBreakdownCard('Theory', subject.theoryMetrics!);
   }
   if (subject.labMetrics != null && subject.labMetrics!.hasData) {
     _buildTypeBreakdownCard('Lab', subject.labMetrics!);
   }
   ```
3. Show remaining classes forecast:
   ```dart
   if (subject.remainingClasses != null) {
     Text('${subject.remainingClasses} classes remaining until semester end');
   }
   ```
4. Show projected final attendance:
   ```dart
   if (subject.projectedFinalPercentage != null) {
     Text('Projected final: ${subject.projectedFinalPercentage!.toStringAsFixed(1)}%');
   }
   ```
5. Show semester-end absence budget:
   ```dart
   if (subject.maxFutureAbsencesForMin != null) {
     Text('You can miss up to ${subject.maxFutureAbsencesForMin} classes and still finish at ${minimumReq}%');
   }
   ```

**Analytics Screen** (`mobile/lib/features/analytics/analytics_screen.dart`)

**Current issue:** Hardcoded `totalRecoveryClassesNeeded` uses old calculation

**Required changes:**
1. Handle `classes_needed_for_min` being `null` (no-data state)
2. Display forecast window and semester-end projections:
   ```dart
   if (data.totalRemainingClasses != null) {
     Text('${data.totalRemainingClasses} total classes remaining');
   }
   if (data.projectedOverallFinalPercentage != null) {
     Text('Projected final: ${data.projectedOverallFinalPercentage!.toStringAsFixed(1)}%');
   }
   ```
3. Show forecast status if incomplete:
   ```dart
   if (data.forecastStatus == 'INCOMPLETE_SEMESTER_DATES') {
     Text('Configure semester dates to see forecast');
   }
   ```

**Dashboard Screen** (`mobile/lib/features/dashboard/dashboard_screen.dart`)

**Required changes:**
1. Use actual `classes_needed_for_min` from API (handle `null`)
2. Display semester-end forecast if available
3. Show "No forecast available" state when prerequisites missing

### 7.3 Academic Setup Updates

**File:** `mobile/lib/features/setup/academic_setup_screen.dart`

**Add `class_type` selector for each timetable entry:**
```dart
DropdownButton<String>(
  value: entry.classType ?? 'UNSPECIFIED',
  items: ['THEORY', 'LAB', 'UNSPECIFIED'].map((type) =>
    DropdownMenuItem(value: type, child: Text(type))
  ).toList(),
  onChanged: (val) => setState(() => entry.classType = val),
)
```

### 7.4 Session/Attendance Display Updates

**Files:**
- `mobile/lib/features/today/today_screen.dart`
- `mobile/lib/shared/widgets/attendance_progress_ring.dart`

**Required changes:**
1. Display `class_type` badge on session cards (Theory/Lab/Unspecified)
2. Handle `null` `class_type` as "Unspecified" with muted styling
3. Update session detail sheets to show class type

---

## 8. Remaining Limitations & Future Enhancements

### 8.1 Known Limitations

1. **No configurable working days UI:**
   - Currently hardcoded as Mon-Sat `{0,1,2,3,4,5}`
   - Should be configurable per semester in academic setup
   - Database already supports via semester or profile extension

2. **No whole-day forecast:**
   - Current forecast counts sessions, not unique calendar dates
   - Formula for "days you can miss" requires date bucketing
   - Implementation deferred to avoid incorrect session-to-day conversion

3. **No "make-up class" support:**
   - If projected final % cannot reach target, system says "unreachable"
   - Does not suggest required extra classes
   - Enhancement: Calculate `extra_classes_needed = ceil((target% * (current + future + X) - current_attended - future) / 1)`

4. **No per-class-type targets:**
   - Minimum and personal target apply to overall attendance only
   - Enhancement: Allow separate targets for Theory (e.g., 80%) vs Lab (e.g., 70%)

### 8.2 Production Deployment Checklist

**Database migrations:**
- [ ] Apply Alembic migration `a1b2c3d4e5f6` to Supabase production
- [ ] Verify `class_type` column exists on both tables
- [ ] Backfill `class_type` for existing timetable entries where known
- [ ] Set `class_type = 'UNSPECIFIED'` for legacy records

**Backend deployment:**
- [ ] Deploy updated services with forecast engine
- [ ] Verify API endpoints return new fields
- [ ] Monitor for `None` vs `0` edge case handling
- [ ] Check holiday service `date.today()` fix

**Frontend deployment:**
- [ ] Update Dart models to handle new fields
- [ ] Update UI to display Theory/Lab breakdowns
- [ ] Update UI to show forecast data
- [ ] Handle `null` recovery values gracefully
- [ ] Test Subject Detail screen responsiveness at 320px width

**Data validation:**
- [ ] Verify overall % = count-weighted, not average of subject %
- [ ] Verify Theory + Lab + Unclassified = Overall
- [ ] Verify future classes exclude holidays correctly
- [ ] Verify projected final % assumes perfect attendance
- [ ] Verify semester-end absence budget respects target

---

## 9. Mathematical Formulas Reference

### 9.1 Current Attendance
```
percentage = (attended / conducted) * 100
where conducted = attended + absent
```

### 9.2 Classes Needed to Reach Target
```
Given: A = attended, C = conducted, r = target ratio (e.g., 0.75)
Solve: (A + x) / (C + x) >= r
Result: x = ceil((r*C - A) / (1 - r))
```

### 9.3 Current Safe Absences
```
Given: A = attended, C = conducted, r = minimum ratio
Solve: A / (C + x) >= r
Result: x = floor((A - r*C) / r)
```

### 9.4 Projected Final Attendance
```
projected_attended = current_attended + future_classes
projected_conducted = current_conducted + future_classes
projected_percentage = (projected_attended / projected_conducted) * 100
```

### 9.5 Maximum Future Absences by Semester End
```
Let M = missed future sessions
final_attended = A + (N - M)
final_conducted = C + N
Require: (A + N - M) / (C + N) >= r
Result: M = floor(A + N - r*(C + N))
Clamp: 0 <= M <= N
```

### 9.6 Overall Semester Attendance
```
total_attended = sum(subject_i.attended)
total_conducted = sum(subject_i.conducted)
overall_percentage = (total_attended / total_conducted) * 100

NEVER: overall_percentage = mean(subject_percentages)  # WRONG
```

---

## 10. Conclusion

This implementation delivers a mathematically rigorous, database-backed, and holiday-aware attendance calculation and forecasting system. All 33 backend tests pass, including comprehensive forecast engine validation.

**Key achievements:**
✅ No aggregate denormalization — counts computed from attendance records  
✅ Theory/Lab breakdown tracked and reported separately  
✅ Future classes enumerated correctly with semester/holiday constraints  
✅ No-data edge cases handled with `None` instead of misleading `0`  
✅ Semester date boundaries enforced in submissions  
✅ All calculations centralized in domain services  
✅ Zero hardcoded formulas in UI components (after Flutter updates)  

**Critical Flutter integration remaining:**
- Model updates to handle new API fields
- UI updates to display Theory/Lab and forecast data
- Academic setup `class_type` selector
- Subject Detail screen responsiveness fixes

**Recommended next steps:**
1. Deploy database migration to production
2. Deploy updated backend services
3. Complete Flutter model and UI updates
4. Add working days configuration UI
5. Consider per-class-type target support
6. Add whole-day forecast feature

All code changes preserve existing data and provide safe defaults for legacy records. The system is production-ready pending Flutter integration and production deployment.

---

**Implementation completed by:** Kiro AI Assistant  
**Date:** October 14, 2026  
**Test status:** 33/33 passing ✅  
**Production readiness:** Backend complete, Flutter updates required
