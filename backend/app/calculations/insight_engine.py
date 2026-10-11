from typing import List, Dict, Any, Optional

def generate_insights_for_semester(
    subject_metrics_list: List[Dict[str, Any]],
    overall_metrics: Dict[str, Any]
) -> List[Dict[str, Any]]:
    """
    Generate deterministic, student-friendly insights based on attendance numbers.
    Never relies on unpredictable LLM output for arithmetic judgments.
    """
    insights: List[Dict[str, Any]] = []

    # 1. Critical subjects check (below minimum)
    critical_subjects = [
        s for s in subject_metrics_list 
        if s.get("has_data") and s.get("percentage") is not None and s.get("percentage") < s.get("minimum_requirement", 75.0)
    ]
    
    for s in critical_subjects:
        needed = s.get("classes_needed_for_min")
        name = s.get("name", "Subject")
        min_req = int(s.get("minimum_requirement", 75.0))
        pct = s.get("percentage", 0.0)
        
        if needed is not None and needed > 0:
            msg = f"Attend the next {needed} {name} classes to reach {min_req}%."
        else:
            msg = f"{name} is currently at {pct}%, below the required {min_req}%."
            
        insights.append({
            "type": "CRITICAL_RECOVERY",
            "severity": "critical",
            "subject_id": s.get("subject_id"),
            "subject_name": name,
            "headline": f"{name} Needs Recovery",
            "message": msg,
            "action": f"Attend next {needed} classes" if needed else "Attend regularly"
        })

    # 2. Caution subjects check (near minimum: between min-5% and min%)
    caution_subjects = [
        s for s in subject_metrics_list
        if s.get("has_data") and s.get("percentage") is not None 
        and s.get("minimum_requirement", 75.0) <= s.get("percentage") < (s.get("minimum_requirement", 75.0) + 4.0)
    ]
    
    for s in caution_subjects:
        name = s.get("name", "Subject")
        margin = s.get("max_safe_absences", 0)
        min_req = int(s.get("minimum_requirement", 75.0))
        if margin <= 1:
            insights.append({
                "type": "LOW_BUFFER_WARNING",
                "severity": "caution",
                "subject_id": s.get("subject_id"),
                "subject_name": name,
                "headline": f"Low Buffer in {name}",
                "message": f"{name} is at {s.get('percentage')}%. You can only miss {margin} class before dropping below {min_req}%.",
                "action": "Avoid missing upcoming classes"
            })

    # 3. Safe absence highlights (can miss classes and stay above threshold)
    safe_subjects = [
        s for s in subject_metrics_list
        if s.get("has_data") and s.get("max_safe_absences", 0) >= 2
    ]
    # Pick the most flexible subject
    safe_subjects.sort(key=lambda x: x.get("max_safe_absences", 0), reverse=True)
    if safe_subjects:
        top_safe = safe_subjects[0]
        name = top_safe.get("name", "Subject")
        margin = top_safe.get("max_safe_absences", 0)
        min_req = int(top_safe.get("minimum_requirement", 75.0))
        insights.append({
            "type": "SAFE_ABSENCE_BUFFER",
            "severity": "positive",
            "subject_id": top_safe.get("subject_id"),
            "subject_name": name,
            "headline": "Safe Absence Margin",
            "message": f"You can miss up to {margin} classes in {name} and still stay above {min_req}%.",
            "action": f"Up to {margin} safe absences"
        })

    # 4. Target milestone opportunities
    target_gap_subjects = [
        s for s in subject_metrics_list
        if s.get("has_data") and s.get("classes_needed_for_target", 0) and 0 < s.get("classes_needed_for_target", 0) <= 5
        and s not in critical_subjects
    ]
    for s in target_gap_subjects[:2]:
        name = s.get("name", "Subject")
        needed = s.get("classes_needed_for_target")
        target = int(s.get("personal_target", 75.0))
        insights.append({
            "type": "TARGET_PROXIMITY",
            "severity": "info",
            "subject_id": s.get("subject_id"),
            "subject_name": name,
            "headline": f"Close to Target in {name}",
            "message": f"Attend {needed} more classes in {name} to reach your {target}% target.",
            "action": f"Target goal: +{needed} classes"
        })

    # 5. Overall standing summary insight
    if overall_metrics.get("has_data"):
        overall_pct = overall_metrics.get("overall_percentage", 0.0)
        overall_min = int(overall_metrics.get("minimum_requirement", 75.0))
        if overall_pct >= overall_metrics.get("personal_target", 75.0):
            insights.append({
                "type": "OVERALL_STANDING",
                "severity": "positive",
                "subject_id": None,
                "subject_name": None,
                "headline": "You are on track",
                "message": f"Keep attending regularly to stay above {overall_min}% for all subjects.",
                "action": "Maintain routine"
            })
        elif overall_pct < overall_min:
            needed = overall_metrics.get("classes_needed_for_min", 0)
            insights.append({
                "type": "OVERALL_STANDING",
                "severity": "critical",
                "subject_id": None,
                "subject_name": None,
                "headline": "Overall Attendance Below Minimum",
                "message": f"Total attendance is {overall_pct}%. You need {needed} consecutive attendances overall to reach {overall_min}%.",
                "action": "Urgent recovery"
            })

    return insights
