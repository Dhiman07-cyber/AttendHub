from typing import Optional, List, Dict, Any
from pydantic import BaseModel

class InsightOut(BaseModel):
    type: str # CRITICAL_RECOVERY, LOW_BUFFER_WARNING, SAFE_ABSENCE_BUFFER, TARGET_PROXIMITY, OVERALL_STANDING
    severity: str # critical, caution, positive, info
    subject_id: Optional[str] = None
    subject_name: Optional[str] = None
    headline: str
    message: str
    action: Optional[str] = None

class TypeBreakdownMetrics(BaseModel):
    """Theory or Lab breakdown metrics for a subject."""
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

class SubjectAnalyticsOut(BaseModel):
    subject_id: str
    name: str
    code: Optional[str]
    faculty_name: Optional[str]
    color: str
    icon: str
    # Overall subject metrics (Theory + Lab + Unclassified)
    attended: int
    absent: int
    conducted: int
    percentage: Optional[float]
    has_data: bool
    status: str
    status_label: str
    minimum_requirement: float
    personal_target: float
    classes_needed_for_min: Optional[int]
    classes_needed_for_target: Optional[int]
    max_safe_absences: int
    can_miss_message: str
    recovery_message: str
    # Theory/Lab breakdown
    theory_metrics: Optional[TypeBreakdownMetrics] = None
    lab_metrics: Optional[TypeBreakdownMetrics] = None
    unclassified_attended: int = 0
    unclassified_conducted: int = 0
    # Forecast fields (future classes until semester end)
    remaining_classes: Optional[int] = None
    remaining_theory_classes: Optional[int] = None
    remaining_lab_classes: Optional[int] = None
    projected_final_percentage: Optional[float] = None
    max_future_absences_for_min: Optional[int] = None
    max_future_absences_for_target: Optional[int] = None
    forecast_status: Optional[str] = None  # COMPLETE, INCOMPLETE_*

class AttendanceTrendPoint(BaseModel):
    label: str # Month or week label, e.g. "Aug", "Sep", "Oct", "Nov", "Dec"
    percentage: Optional[float]
    attended: int
    conducted: int

class AnalyticsOverviewOut(BaseModel):
    semester_id: str
    semester_label: str
    total_attended: int
    total_absent: int
    total_conducted: int
    overall_percentage: Optional[float]
    has_data: bool
    status: str
    status_label: str
    minimum_requirement: float
    personal_target: float
    classes_needed_for_min: Optional[int]
    classes_needed_for_target: Optional[int]
    max_safe_absences: int
    
    # Requirements summary
    total_recovery_classes_needed: int
    total_safe_absences_margin: int
    
    subjects: List[SubjectAnalyticsOut]
    insights: List[InsightOut]
    trends: List[AttendanceTrendPoint]
    month_over_month_change: float = 0.0
    
    # Semester-wide forecast
    total_remaining_classes: Optional[int] = None
    projected_overall_final_percentage: Optional[float] = None
    forecast_status: Optional[str] = None
