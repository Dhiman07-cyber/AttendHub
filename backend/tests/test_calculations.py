import pytest
from app.calculations.attendance_engine import (
    calculate_subject_metrics,
    calculate_overall_metrics
)

def test_subject_zero_conducted_classes():
    """Verify zero conducted classes returns has_data=False and None percentage."""
    m = calculate_subject_metrics(attended=0, absent=0)
    assert m["conducted"] == 0
    assert m["percentage"] is None
    assert m["has_data"] is False
    assert m["status"] == "NO_DATA"
    assert m["personal_target"] == 75.0
    assert m["minimum_requirement"] == 75.0
    assert m["max_safe_absences"] == 0

def test_subject_below_minimum_recovery_forecast():
    """Verify classes needed to reach 75% for 15 attended, 7 absent (Mathematics case)."""
    # Conducted = 22, Attended = 15 => 15/22 = 68.18% ~ 68.2%
    # Formula: (15 + x) / (22 + x) >= 0.75
    # 15 + x >= 16.5 + 0.75x => 0.25x >= 1.5 => x >= 6
    m = calculate_subject_metrics(attended=15, absent=7, minimum_requirement=75.0, personal_target=80.0)
    assert m["conducted"] == 22
    assert m["percentage"] == 68.2
    assert m["status"] == "CRITICAL"
    assert m["classes_needed_for_min"] == 6
    assert m["max_safe_absences"] == 0 # Cannot miss any classes when below minimum!
    assert "Need 6 more classes to reach 75%" in m["recovery_message"]

def test_subject_safe_absence_forecast():
    """Verify max safe absences for Computer Networks (24 attended, 6 absent)."""
    # 24 / 30 = 80.0%
    # Formula: 24 / (30 + x) >= 0.75
    # 24 >= 22.5 + 0.75x => 0.75x <= 1.5 => x <= 2
    m = calculate_subject_metrics(attended=24, absent=6, minimum_requirement=75.0, personal_target=80.0)
    assert m["conducted"] == 30
    assert m["percentage"] == 80.0
    assert m["status"] == "ON_TARGET"
    assert m["classes_needed_for_min"] == 0
    assert m["classes_needed_for_target"] == 0
    assert m["max_safe_absences"] == 2
    assert "You can miss up to 2 classes and still stay above 75%" in m["can_miss_message"]

def test_subject_large_safe_absence_buffer():
    """Verify Software Engineering safe absences (33 attended, 7 absent = 82.5%)."""
    # 33 / (40 + x) >= 0.75 => 33 >= 30 + 0.75x => 0.75x <= 3 => x <= 4
    m = calculate_subject_metrics(attended=33, absent=7, minimum_requirement=75.0, personal_target=80.0)
    assert m["percentage"] == 82.5
    assert m["max_safe_absences"] == 4
    assert m["classes_needed_for_min"] == 0

def test_overall_metrics_aggregation_vs_averaging():
    """Verify overall attendance aggregates total counts and never averages subject percentages."""
    # Subject A: 90 attended, 10 absent (conducted=100, 90.0%)
    # Subject B: 1 attended, 1 absent (conducted=2, 50.0%)
    # Average of percentages would be (90 + 50) / 2 = 70.0% (WRONG)
    # Aggregated is total attended 91 / total conducted 102 = 89.2% (CORRECT)
    records = [
        {"attended": 90, "absent": 10},
        {"attended": 1, "absent": 1}
    ]
    res = calculate_overall_metrics(records, minimum_requirement=75.0, personal_target=80.0)
    assert res["total_attended"] == 91
    assert res["total_conducted"] == 102
    assert res["overall_percentage"] == 89.2
    assert res["status"] == "ON_TARGET"

def test_target_already_reached():
    """When percentage is above target, classes needed is 0."""
    m = calculate_subject_metrics(attended=9, absent=1, minimum_requirement=75.0, personal_target=80.0) # 90%
    assert m["classes_needed_for_min"] == 0
    assert m["classes_needed_for_target"] == 0
    assert m["status"] == "ON_TARGET"
