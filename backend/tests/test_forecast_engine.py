"""
Test suite for forecast_engine.py — Future Schedule Enumeration & Projections

Verifies:
- Future class enumeration respects semester bounds, holidays, working days
- Projected final attendance calculations
- Maximum future absences by semester end
- Forecast completeness status
"""

import pytest
from datetime import date, timedelta
from app.calculations.forecast_engine import (
    enumerate_future_class_dates,
    calculate_future_classes_count,
    calculate_projected_final_attendance,
    calculate_max_future_absences_by_semester_end,
    calculate_forecast_status
)


def test_enumerate_future_classes_simple():
    """Verify basic weekly recurrence without holidays or exclusions."""
    # Monday class from 2026-10-19 to 2026-11-09 (4 Mondays: 19, 26, Nov 2, Nov 9)
    timetable = [{
        "id": "tt1",
        "subject_id": "subj1",
        "day_of_week": 0,  # Monday
        "start_time": "09:00",
        "class_type": "THEORY",
        "effective_from": None,
        "effective_to": None
    }]
    
    semester_start = date(2026, 10, 1)
    semester_end = date(2026, 11, 10)
    forecast_from = date(2026, 10, 14)  # Wednesday Oct 14
    holidays = []
    
    occurrences = enumerate_future_class_dates(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    
    # Expect Mondays: Oct 19, 26, Nov 2, 9 (4 total)
    assert len(occurrences) == 4
    assert occurrences[0]["date"] == date(2026, 10, 19)
    assert occurrences[1]["date"] == date(2026, 10, 26)
    assert occurrences[2]["date"] == date(2026, 11, 2)
    assert occurrences[3]["date"] == date(2026, 11, 9)
    assert all(o["class_type"] == "THEORY" for o in occurrences)


def test_enumerate_excludes_holidays():
    """Verify holiday dates are properly excluded."""
    # Monday class, but Oct 26 is a holiday
    timetable = [{
        "id": "tt1",
        "subject_id": "subj1",
        "day_of_week": 0,
        "start_time": "09:00",
        "class_type": "THEORY",
        "effective_from": None,
        "effective_to": None
    }]
    
    semester_start = date(2026, 10, 1)
    semester_end = date(2026, 11, 10)
    forecast_from = date(2026, 10, 14)
    holidays = [(date(2026, 10, 26), date(2026, 10, 26))]  # Oct 26 is a holiday
    
    occurrences = enumerate_future_class_dates(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    
    # Should have 3 Mondays (Oct 19, Nov 2, Nov 9) — Oct 26 excluded
    assert len(occurrences) == 3
    dates = [o["date"] for o in occurrences]
    assert date(2026, 10, 26) not in dates
    assert date(2026, 10, 19) in dates
    assert date(2026, 11, 2) in dates


def test_enumerate_respects_semester_bounds():
    """Verify dates outside semester start/end are excluded."""
    timetable = [{
        "id": "tt1",
        "subject_id": "subj1",
        "day_of_week": 0,
        "start_time": "09:00",
        "class_type": "THEORY",
        "effective_from": None,
        "effective_to": None
    }]
    
    # Semester Oct 15 - Nov 5
    semester_start = date(2026, 10, 15)
    semester_end = date(2026, 11, 5)
    forecast_from = date(2026, 10, 10)
    holidays = []
    
    occurrences = enumerate_future_class_dates(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    
    # Oct 12 before semester start -> excluded
    # Oct 19, 26, Nov 2 -> included
    # Nov 9 after semester end -> excluded
    assert len(occurrences) == 3
    assert all(semester_start <= o["date"] <= semester_end for o in occurrences)


def test_enumerate_respects_working_days_mask():
    """
    DEPRECATED TEST: working_days_mask is no longer used.
    
    The forecast engine now enumerates all scheduled timetable entries.
    This test is updated to reflect the new behavior.
    """
    # Monday and Wednesday classes
    timetable = [
        {"id": "tt1", "subject_id": "subj1", "day_of_week": 0, "start_time": "09:00", 
         "class_type": "THEORY", "effective_from": None, "effective_to": None},
        {"id": "tt2", "subject_id": "subj1", "day_of_week": 2, "start_time": "11:00", 
         "class_type": "LAB", "effective_from": None, "effective_to": None}
    ]
    
    semester_start = date(2026, 10, 1)
    semester_end = date(2026, 10, 31)
    forecast_from = date(2026, 10, 1)
    holidays = []
    
    occurrences = enumerate_future_class_dates(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    
    # Both Mondays and Wednesdays should appear
    # Mondays: Oct 5, 12, 19, 26 (4 days)
    # Wednesdays: Oct 7, 14, 21, 28 (4 days)
    assert len(occurrences) == 8
    mondays = [o for o in occurrences if o["date"].weekday() == 0]
    wednesdays = [o for o in occurrences if o["date"].weekday() == 2]
    assert len(mondays) == 4
    assert len(wednesdays) == 4


def test_enumerate_respects_effective_date_range():
    """Verify timetable entry effective_from and effective_to constraints."""
    timetable = [{
        "id": "tt1",
        "subject_id": "subj1",
        "day_of_week": 1,  # Tuesday
        "start_time": "10:00",
        "class_type": "THEORY",
        "effective_from": date(2026, 10, 20),
        "effective_to": date(2026, 11, 5)
    }]
    
    semester_start = date(2026, 10, 1)
    semester_end = date(2026, 11, 30)
    forecast_from = date(2026, 10, 1)
    holidays = []
    
    occurrences = enumerate_future_class_dates(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    
    # Only Tuesdays between Oct 20 and Nov 5: Oct 20, 27, Nov 3
    assert len(occurrences) == 3
    assert all(date(2026, 10, 20) <= o["date"] <= date(2026, 11, 5) for o in occurrences)
    assert occurrences[0]["date"] == date(2026, 10, 20)
    assert occurrences[-1]["date"] == date(2026, 11, 3)


def test_calculate_future_classes_count_with_filters():
    """Verify count calculations with subject and class_type filters."""
    timetable = [
        {"id": "tt1", "subject_id": "math", "day_of_week": 0, "start_time": "09:00", 
         "class_type": "THEORY", "effective_from": None, "effective_to": None},
        {"id": "tt2", "subject_id": "math", "day_of_week": 2, "start_time": "11:00", 
         "class_type": "LAB", "effective_from": None, "effective_to": None},
        {"id": "tt3", "subject_id": "physics", "day_of_week": 3, "start_time": "14:00", 
         "class_type": "THEORY", "effective_from": None, "effective_to": None}
    ]
    
    semester_start = date(2026, 10, 1)
    semester_end = date(2026, 10, 31)
    forecast_from = date(2026, 10, 1)
    holidays = []
    
    # Total count
    total = calculate_future_classes_count(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    # Oct has 5 Mondays, 5 Wednesdays, 5 Thursdays = 5 + 5 + 5 = 15
    # But forecast_from is Oct 1, so we count from Oct 2 onwards
    # Mondays: 5, 12, 19, 26 (4 after Oct 1)
    # Wednesdays: 7, 14, 21, 28 (4 after Oct 1)
    # Thursdays: 1, 8, 15, 22, 29 (4 after Oct 1, but Oct 1 is Thursday so all 5 are >= Oct 2)
    # Actually: Oct 1 is a Thursday, forecast_from = Oct 1, so future means Oct 2+
    # Let me recalculate: Mon 5,12,19,26 (4), Wed 7,14,21,28 (4), Thu 8,15,22,29 (4 after Oct 1)
    assert total == 12
    
    # Math only: 4 Mondays + 4 Wednesdays = 8
    math_count = calculate_future_classes_count(
        timetable, semester_start, semester_end, holidays, forecast_from, subject_id="math"
    )
    assert math_count == 8
    
    # THEORY only: 4 Mondays + 4 Thursdays = 8
    theory_count = calculate_future_classes_count(
        timetable, semester_start, semester_end, holidays, forecast_from, class_type_filter="THEORY"
    )
    assert theory_count == 8
    
    # Math LAB only: 4 Wednesdays
    math_lab = calculate_future_classes_count(
        timetable, semester_start, semester_end, holidays, forecast_from,
        subject_id="math", class_type_filter="LAB"
    )
    assert math_lab == 4


def test_projected_final_attendance():
    """Verify projected final % if all future classes are attended."""
    # Currently 15/22 = 68.2%
    # Future 8 classes -> projected 23/30 = 76.7%
    projected = calculate_projected_final_attendance(
        current_attended=15, current_conducted=22, future_classes_count=8
    )
    assert projected == 76.7
    
    # Zero future classes -> return current %
    projected_zero = calculate_projected_final_attendance(
        current_attended=15, current_conducted=22, future_classes_count=0
    )
    assert projected_zero == 68.2


def test_max_future_absences_by_semester_end():
    """Verify maximum absences calculation while maintaining target."""
    # Current: 24/30 = 80.0%
    # Future: 10 classes
    # Target: 75%
    # Formula: M <= 24 + 10 - 0.75*(30+10) = 34 - 30 = 4
    max_abs = calculate_max_future_absences_by_semester_end(
        current_attended=24, current_conducted=30, future_classes_count=10, target_percentage=75.0
    )
    assert max_abs == 4
    
    # Already below target: 14/20 = 70% < 75%
    # Future: 10 classes
    # Even with perfect attendance: 24/30 = 80% >= 75% ✓
    # M <= 14 + 10 - 0.75*30 = 24 - 22.5 = 1.5 -> floor = 1
    max_abs_recovery = calculate_max_future_absences_by_semester_end(
        current_attended=14, current_conducted=20, future_classes_count=10, target_percentage=75.0
    )
    assert max_abs_recovery == 1
    
    # Target unreachable even with perfect attendance
    # Current: 10/20 = 50%, Future: 5, Target: 75%
    # Perfect: 15/25 = 60% < 75% -> unreachable
    max_abs_unreachable = calculate_max_future_absences_by_semester_end(
        current_attended=10, current_conducted=20, future_classes_count=5, target_percentage=75.0
    )
    assert max_abs_unreachable is None


def test_calculate_forecast_status():
    """Verify forecast completeness status detection."""
    # Complete scenario
    status = calculate_forecast_status(
        semester_start=date(2026, 10, 1),
        semester_end=date(2027, 5, 31),
        timetable_entries=[{"id": "tt1", "subject_id": "s1"}]
    )
    assert status == "COMPLETE"
    
    # Missing semester dates
    status_no_dates = calculate_forecast_status(
        semester_start=None,
        semester_end=None,
        timetable_entries=[{"id": "tt1"}]
    )
    assert status_no_dates == "INCOMPLETE_SEMESTER_DATES"
    
    # No timetable entries
    status_no_tt = calculate_forecast_status(
        semester_start=date(2026, 10, 1),
        semester_end=date(2027, 5, 31),
        timetable_entries=[]
    )
    assert status_no_tt == "INCOMPLETE_TIMETABLE"


def test_multi_day_holiday_range():
    """Verify multi-day holiday ranges exclude all covered dates."""
    timetable = [{
        "id": "tt1",
        "subject_id": "subj1",
        "day_of_week": 1,  # Tuesday
        "start_time": "10:00",
        "class_type": "THEORY",
        "effective_from": None,
        "effective_to": None
    }]
    
    semester_start = date(2026, 11, 1)
    semester_end = date(2026, 11, 30)
    forecast_from = date(2026, 11, 1)
    # Holiday Nov 10-17 (8 days, covers 2 Tuesdays: Nov 10 and Nov 17)
    holidays = [(date(2026, 11, 10), date(2026, 11, 17))]
    
    occurrences = enumerate_future_class_dates(
        timetable, semester_start, semester_end, holidays, forecast_from
    )
    
    # November Tuesdays: 3, 10, 17, 24
    # Holiday excludes 10 and 17 -> only 3 and 24 remain
    assert len(occurrences) == 2
    dates = [o["date"] for o in occurrences]
    assert date(2026, 11, 3) in dates
    assert date(2026, 11, 24) in dates
    assert date(2026, 11, 10) not in dates
    assert date(2026, 11, 17) not in dates
