import math
from typing import Optional, Dict, Any, List

def calculate_subject_metrics(
    attended: int,
    absent: int,
    minimum_requirement: float = 75.0,
    personal_target: float = 75.0
) -> Dict[str, Any]:
    """
    Calculate deterministic attendance metrics for a single subject.
    Conducted = attended + absent. Not-held and cancelled sessions are not counted.
    """
    conducted = attended + absent
    has_data = conducted > 0
    
    if not has_data:
        percentage = None
        status = "NO_DATA"
        status_label = "No attendance data yet"
        classes_needed_for_min = 0
        classes_needed_for_target = 0
        max_safe_absences = 0
        can_miss_message = "No classes recorded yet"
        recovery_message = "No attendance data yet"
    else:
        percentage = round((attended / conducted) * 100.0, 1)
        r_min = minimum_requirement / 100.0
        r_target = personal_target / 100.0
        
        # Calculate status
        if percentage >= personal_target:
            status = "ON_TARGET"
            status_label = "On Target"
        elif percentage >= minimum_requirement:
            status = "SAFE"
            status_label = "Safe"
        elif percentage >= (minimum_requirement - 5.0):
            status = "CAUTION"
            status_label = "Needs Attention"
        else:
            status = "CRITICAL"
            status_label = "Below Minimum"

        # 1. Classes needed to reach minimum requirement
        if percentage >= minimum_requirement:
            classes_needed_for_min = 0
        else:
            if r_min >= 1.0:
                classes_needed_for_min = None if absent > 0 else 0
            else:
                needed = math.ceil((r_min * conducted - attended) / (1.0 - r_min))
                classes_needed_for_min = max(0, needed)

        # 2. Classes needed to reach personal target
        if percentage >= personal_target:
            classes_needed_for_target = 0
        else:
            if r_target >= 1.0:
                classes_needed_for_target = None if absent > 0 else 0
            else:
                needed = math.ceil((r_target * conducted - attended) / (1.0 - r_target))
                classes_needed_for_target = max(0, needed)
                
        # 3. Maximum safe absences while staying >= minimum_requirement
        if percentage < minimum_requirement:
            max_safe_absences = 0
            can_miss_message = f"Currently below {minimum_requirement:.0f}%. Attend upcoming classes to recover."
        else:
            if r_min <= 0:
                max_safe_absences = 999
            else:
                margin = math.floor((attended - r_min * conducted) / r_min)
                max_safe_absences = max(0, margin)
                
            if max_safe_absences == 0:
                can_miss_message = f"Cannot miss any class without dropping below {minimum_requirement:.0f}%."
            elif max_safe_absences == 1:
                can_miss_message = f"You can miss 1 class and still stay above {minimum_requirement:.0f}%."
            else:
                can_miss_message = f"You can miss up to {max_safe_absences} classes and still stay above {minimum_requirement:.0f}%."
                
        # Recovery / recommendation phrasing
        if classes_needed_for_min is not None and classes_needed_for_min > 0:
            recovery_message = f"Need {classes_needed_for_min} more classes to reach {minimum_requirement:.0f}%."
        elif classes_needed_for_target is not None and classes_needed_for_target > 0:
            recovery_message = f"Need {classes_needed_for_target} more classes to reach target of {personal_target:.0f}%."
        else:
            recovery_message = "Already at target."


    return {
        "attended": attended,
        "absent": absent,
        "conducted": conducted,
        "percentage": percentage,
        "has_data": has_data,
        "status": status,
        "status_label": status_label,
        "minimum_requirement": minimum_requirement,
        "personal_target": personal_target,
        "classes_needed_for_min": classes_needed_for_min,
        "classes_needed_for_target": classes_needed_for_target,
        "max_safe_absences": max_safe_absences,
        "can_miss_message": can_miss_message,
        "recovery_message": recovery_message,
    }

def calculate_overall_metrics(
    subject_records: List[Dict[str, int]],
    minimum_requirement: float = 75.0,
    personal_target: float = 75.0
) -> Dict[str, Any]:
    """
    Calculate aggregate attendance for the whole semester.
    Per rule: Aggregate total_attended / total_conducted. Never average percentages!
    """
    total_attended = sum(s.get("attended", 0) for s in subject_records)
    total_absent = sum(s.get("absent", 0) for s in subject_records)
    total_conducted = total_attended + total_absent
    
    if total_conducted == 0:
        return {
            "total_attended": 0,
            "total_absent": 0,
            "total_conducted": 0,
            "overall_percentage": None,
            "has_data": False,
            "status": "NO_DATA",
            "status_label": "No attendance data yet",
            "minimum_requirement": minimum_requirement,
            "personal_target": personal_target,
            "classes_needed_for_min": 0,
            "classes_needed_for_target": 0,
            "max_safe_absences": 0,
            "message": "Start marking attendance to track your academic standing."
        }
        
    overall_percentage = round((total_attended / total_conducted) * 100.0, 1)
    r_min = minimum_requirement / 100.0
    r_target = personal_target / 100.0
    
    if overall_percentage >= personal_target:
        status = "ON_TARGET"
        status_label = "On Target"
        message = "You are above your personal target. Excellent consistency!"
    elif overall_percentage >= minimum_requirement:
        status = "SAFE"
        status_label = "Safe"
        message = f"You are safely above the minimum requirement of {minimum_requirement:.0f}%."
    elif overall_percentage >= (minimum_requirement - 5.0):
        status = "CAUTION"
        status_label = "Needs Attention"
        message = f"Approaching minimum requirement of {minimum_requirement:.0f}%. Avoid unneeded leaves."
    else:
        status = "CRITICAL"
        status_label = "Below Minimum"
        message = f"Overall attendance is below {minimum_requirement:.0f}%. Urgent recovery required."

    if overall_percentage >= minimum_requirement:
        classes_needed_for_min = 0
    else:
        if r_min >= 1.0:
            classes_needed_for_min = None if total_absent > 0 else 0
        else:
            needed = math.ceil((r_min * total_conducted - total_attended) / (1.0 - r_min))
            classes_needed_for_min = max(0, needed)

    if overall_percentage >= personal_target:
        classes_needed_for_target = 0
    else:
        if r_target >= 1.0:
            classes_needed_for_target = None if total_absent > 0 else 0
        else:
            needed = math.ceil((r_target * total_conducted - total_attended) / (1.0 - r_target))
            classes_needed_for_target = max(0, needed)

    if overall_percentage < minimum_requirement:
        max_safe_absences = 0
    else:
        margin = math.floor((total_attended - r_min * total_conducted) / r_min)
        max_safe_absences = max(0, margin)
        
    return {
        "total_attended": total_attended,
        "total_absent": total_absent,
        "total_conducted": total_conducted,
        "overall_percentage": overall_percentage,
        "has_data": True,
        "status": status,
        "status_label": status_label,
        "minimum_requirement": minimum_requirement,
        "personal_target": personal_target,
        "classes_needed_for_min": classes_needed_for_min,
        "classes_needed_for_target": classes_needed_for_target,
        "max_safe_absences": max_safe_absences,
        "message": message
    }
