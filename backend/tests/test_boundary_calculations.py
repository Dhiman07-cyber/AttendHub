import pytest
from datetime import time, date
from app.calculations.attendance_engine import (
    calculate_subject_metrics,
    calculate_overall_metrics
)
from app.services.attendance_service import compute_time_status

def test_below_minimum_safe_absences_is_always_zero():
    # 70% attendance with 75% minimum requirement
    # Attended = 14, Conducted = 20 -> 70.0%
    m = calculate_subject_metrics(attended=14, absent=6, minimum_requirement=75.0, personal_target=75.0)
    assert m["percentage"] == 70.0
    assert m["max_safe_absences"] == 0
    assert "Currently below" in m["can_miss_message"]

def test_exact_target_and_recovery_equations():
    # Case 1: Attended = 15, Absent = 7 -> Conducted = 22, % = 68.2%
    # Target r = 0.75:
    # needed = ceil((0.75 * 22 - 15) / (1 - 0.75)) = ceil((16.5 - 15) / 0.25) = ceil(1.5 / 0.25) = 6
    m = calculate_subject_metrics(attended=15, absent=7, minimum_requirement=75.0, personal_target=75.0)
    assert m["classes_needed_for_min"] == 6
    assert m["classes_needed_for_target"] == 6

    # Case 2: At target (e.g. 75.0%)
    # Attended = 15, Absent = 5 -> Conducted = 20, % = 75.0%
    m_target = calculate_subject_metrics(attended=15, absent=5, minimum_requirement=75.0, personal_target=75.0)
    assert m_target["percentage"] == 75.0
    assert m_target["classes_needed_for_target"] == 0
    assert m_target["recovery_message"] == "Already at target."

def test_safe_absences_margin_equation():
    # Attended = 24, Conducted = 30 -> 80.0%
    # Minimum requirement r = 0.75
    # safe = floor((24 - 0.75 * 30) / 0.75) = floor((24 - 22.5) / 0.75) = floor(1.5 / 0.75) = 2
    m = calculate_subject_metrics(attended=24, absent=6, minimum_requirement=75.0, personal_target=75.0)
    assert m["max_safe_absences"] == 2
    assert "You can miss up to 2 classes" in m["can_miss_message"]

def test_zero_conducted_safe_behavior():
    m = calculate_subject_metrics(attended=0, absent=0, minimum_requirement=75.0, personal_target=75.0)
    assert m["percentage"] is None
    assert m["conducted"] == 0
    assert m["status"] == "NO_DATA"
    assert m["status_label"] == "No attendance data yet"
    assert m["max_safe_absences"] == 0
    assert m["classes_needed_for_min"] == 0
    assert m["classes_needed_for_target"] == 0

def test_time_status_chronology_and_untimed_stability():
    # Timed session: 09:00 - 10:00 with reference time 11:30 -> Done
    assert compute_time_status("09:00", "10:00", reference_time=time(11, 30)) == "Done"

    # Active session: 11:00 - 12:00 with reference time 11:30 -> Now
    assert compute_time_status("11:00", "12:00", reference_time=time(11, 30)) == "Now"

    # Future session: 14:00 - 15:00 with reference time 11:30 -> Upcoming
    assert compute_time_status("14:00", "15:00", reference_time=time(11, 30)) == "Upcoming"

    # Untimed session: start or end is None -> Must return None (never invent a time state)
    assert compute_time_status(None, None) is None
    assert compute_time_status("10:00", None) is None
    assert compute_time_status(None, "11:00") is None
