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

class SubjectAnalyticsOut(BaseModel):
    subject_id: str
    name: str
    code: Optional[str]
    faculty_name: Optional[str]
    color: str
    icon: str
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
