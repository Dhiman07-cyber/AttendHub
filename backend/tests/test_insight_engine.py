from app.calculations.insight_engine import generate_insights_for_semester
from app.calculations.attendance_engine import calculate_subject_metrics, calculate_overall_metrics

def test_generate_insights_triggers_recovery():
    # Mathematics below minimum
    math_m = calculate_subject_metrics(attended=15, absent=7, minimum_requirement=75.0, personal_target=80.0)
    math_m["subject_id"] = "sub-1"
    math_m["name"] = "Mathematics"

    # Computer Networks safe
    cn_m = calculate_subject_metrics(attended=24, absent=6, minimum_requirement=75.0, personal_target=80.0)
    cn_m["subject_id"] = "sub-2"
    cn_m["name"] = "Computer Networks"

    subjects = [math_m, cn_m]
    overall = calculate_overall_metrics(subjects, minimum_requirement=75.0, personal_target=80.0)

    insights = generate_insights_for_semester(subjects, overall)
    assert len(insights) > 0

    types = [i["type"] for i in insights]
    assert "CRITICAL_RECOVERY" in types
    crit_ins = next(i for i in insights if i["type"] == "CRITICAL_RECOVERY")
    assert "Attend the next 6 Mathematics classes to reach 75%" in crit_ins["message"]
