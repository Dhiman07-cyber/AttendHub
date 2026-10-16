"""
Forecast Engine — Future Schedule Enumeration and Semester-End Projections

This module calculates remaining classes, projected final attendance, and
semester-end safe-absence budget using actual timetable entries, holidays,
working days, and semester date boundaries.

Key principles:
- Future occurrences are enumerated from routine/timetable definitions
- Holidays exclude dates that would otherwise have classes
- Semester start/end dates bound all forecasts
- Past unmarked sessions are NOT counted as future classes
- No database writes — this is a read-only calculation
"""

from datetime import date, timedelta
from typing import List, Dict, Any, Optional, Set, Tuple
import math


def enumerate_future_class_dates(
    timetable_entries: List[Dict[str, Any]],
    semester_start: date,
    semester_end: date,
    holidays: List[Tuple[date, date]],
    forecast_from_date: date
) -> List[Dict[str, Any]]:
    """
    Enumerate eligible future class occurrences from timetable entries.
    
    The forecast derives future classes from actual scheduled timetable entries.
    If a class is scheduled on a particular weekday, it appears in forecasts.
    No manual "working days" configuration should filter scheduled classes.
    
    Args:
        timetable_entries: List of recurring timetable slots with day_of_week, start_time, subject_id, class_type
        semester_start: Inclusive semester start date
        semester_end: Inclusive semester end date
        holidays: List of (start_date, end_date) tuples for holidays (both inclusive)
        forecast_from_date: Calculate future classes from this date forward (exclusive)
    
    Returns:
        List of future class occurrence dicts with date, subject_id, timetable_entry_id, class_type
    """
    
    # Build holiday exclusion set
    excluded_dates: Set[date] = set()
    for hol_start, hol_end in holidays:
        current = hol_start
        while current <= hol_end:
            excluded_dates.add(current)
            current += timedelta(days=1)
    
    future_occurrences: List[Dict[str, Any]] = []
    
    # For each timetable entry, enumerate its occurrences between forecast_from_date and semester_end
    for entry in timetable_entries:
        day_of_week = entry.get("day_of_week")
        if day_of_week is None:
            continue
        
        subject_id = entry.get("subject_id")
        timetable_entry_id = entry.get("id")
        class_type = entry.get("class_type") or "UNSPECIFIED"
        effective_from = entry.get("effective_from")
        effective_to = entry.get("effective_to")
        
        # Find the first occurrence date >= forecast_from_date + 1 day
        # (forecast_from_date is the cutoff; we want strictly future dates)
        search_start = forecast_from_date + timedelta(days=1)
        
        # Advance to the next matching weekday
        current_date = search_start
        while current_date.weekday() != day_of_week:
            current_date += timedelta(days=1)
        
        # Now enumerate all matching weekdays until semester_end
        while current_date <= semester_end:
            # Check semester bounds
            if current_date < semester_start:
                current_date += timedelta(days=7)
                continue
            
            # Check effective date range for this timetable entry
            if effective_from and current_date < effective_from:
                current_date += timedelta(days=7)
                continue
            if effective_to and current_date > effective_to:
                break
            
            # Check holiday exclusion
            if current_date in excluded_dates:
                current_date += timedelta(days=7)
                continue
            
            # Valid future occurrence
            future_occurrences.append({
                "date": current_date,
                "subject_id": subject_id,
                "timetable_entry_id": timetable_entry_id,
                "class_type": class_type,
                "day_of_week": day_of_week
            })
            
            current_date += timedelta(days=7)
    
    # Sort by date
    future_occurrences.sort(key=lambda x: x["date"])
    return future_occurrences


def calculate_future_classes_count(
    timetable_entries: List[Dict[str, Any]],
    semester_start: date,
    semester_end: date,
    holidays: List[Tuple[date, date]],
    forecast_from_date: date,
    subject_id: Optional[str] = None,
    class_type_filter: Optional[str] = None
) -> int:
    """
    Count future eligible class sessions until semester end.
    
    Args:
        timetable_entries: Recurring timetable slots
        semester_start: Semester start date (inclusive)
        semester_end: Semester end date (inclusive)
        holidays: List of (start, end) date tuples
        forecast_from_date: Count classes after this date
        subject_id: If provided, count only this subject's classes
        class_type_filter: If provided, count only THEORY or LAB (or UNSPECIFIED)
    
    Returns:
        Integer count of future class sessions
    """
    occurrences = enumerate_future_class_dates(
        timetable_entries, semester_start, semester_end, holidays,
        forecast_from_date
    )
    
    # Filter by subject_id if requested
    if subject_id:
        occurrences = [o for o in occurrences if o["subject_id"] == subject_id]
    
    # Filter by class_type if requested
    if class_type_filter:
        occurrences = [o for o in occurrences if o["class_type"] == class_type_filter]
    
    return len(occurrences)


def calculate_future_class_days_count(
    timetable_entries: List[Dict[str, Any]],
    semester_start: date,
    semester_end: date,
    holidays: List[Tuple[date, date]],
    forecast_from_date: date,
    subject_id: Optional[str] = None
) -> int:
    """
    Count unique future calendar dates that have at least one class session.
    
    Returns:
        Integer count of future class days (unique dates with >= 1 session)
    """
    occurrences = enumerate_future_class_dates(
        timetable_entries, semester_start, semester_end, holidays,
        forecast_from_date
    )
    
    if subject_id:
        occurrences = [o for o in occurrences if o["subject_id"] == subject_id]
    
    unique_dates = {o["date"] for o in occurrences}
    return len(unique_dates)


def calculate_projected_final_attendance(
    current_attended: int,
    current_conducted: int,
    future_classes_count: int
) -> Optional[float]:
    """
    Calculate projected final attendance percentage if all future classes are attended.
    
    Args:
        current_attended: Current attended count
        current_conducted: Current conducted count (attended + absent)
        future_classes_count: Number of future scheduled classes until semester end
    
    Returns:
        Projected percentage (0-100) or None if no future data available
    """
    projected_conducted = current_conducted + future_classes_count
    if projected_conducted == 0:
        return None
    
    projected_attended = current_attended + future_classes_count
    return round((projected_attended / projected_conducted) * 100.0, 1)


def calculate_max_future_absences_by_semester_end(
    current_attended: int,
    current_conducted: int,
    future_classes_count: int,
    target_percentage: float
) -> Optional[int]:
    """
    Calculate maximum number of future classes that can be missed while
    still ending the semester at or above target percentage.
    
    Assumes all other future classes (not in the missed count) are attended.
    
    Args:
        current_attended: Current attended count
        current_conducted: Current conducted count
        future_classes_count: Total future scheduled classes
        target_percentage: Target % (e.g. 75.0)
    
    Returns:
        Integer count of maximum allowable future absences, or None if unreachable
    """
    if future_classes_count == 0:
        # No future classes to miss
        return 0
    
    r = target_percentage / 100.0
    
    # Let M = missed future sessions
    # final_attended = current_attended + (future_classes_count - M)
    # final_conducted = current_conducted + future_classes_count
    # Require: (current_attended + future_classes_count - M) / (current_conducted + future_classes_count) >= r
    # => current_attended + future_classes_count - M >= r * (current_conducted + future_classes_count)
    # => M <= current_attended + future_classes_count - r * (current_conducted + future_classes_count)
    
    numerator = current_attended + future_classes_count - r * (current_conducted + future_classes_count)
    max_absences = math.floor(numerator)
    
    # Clamp between 0 and future_classes_count
    max_absences = max(0, min(max_absences, future_classes_count))
    
    # Check if target is even reachable with perfect attendance
    projected_with_perfect = calculate_projected_final_attendance(
        current_attended, current_conducted, future_classes_count
    )
    if projected_with_perfect is not None and projected_with_perfect < target_percentage:
        # Target unreachable even with perfect attendance
        return None
    
    return max_absences


def calculate_forecast_status(
    semester_start: Optional[date],
    semester_end: Optional[date],
    timetable_entries: List[Dict[str, Any]]
) -> str:
    """
    Determine forecast completeness/readiness status.
    
    Returns:
        - "COMPLETE" if all prerequisites are met
        - "INCOMPLETE_SEMESTER_DATES" if start/end dates missing
        - "INCOMPLETE_TIMETABLE" if no timetable entries
    """
    if not semester_start or not semester_end:
        return "INCOMPLETE_SEMESTER_DATES"
    
    if not timetable_entries or len(timetable_entries) == 0:
        return "INCOMPLETE_TIMETABLE"
    
    return "COMPLETE"
