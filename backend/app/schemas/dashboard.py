from typing import Optional, List
from pydantic import BaseModel
from app.schemas.analytics import InsightOut, AttendanceTrendPoint
from app.schemas.session import ClassSessionOut
from app.schemas.holiday import HolidayOut

class DashboardSubjectAttention(BaseModel):
    subject_id: str
    name: str
    percentage: Optional[float]
    color: str
    icon: str
    status: str
    needed_classes_message: str

class DashboardOverviewOut(BaseModel):
    user_name: str
    current_semester_label: str
    course_name: str
    enrollment_id: Optional[str] = None
    
    # Overall attendance ring metrics
    overall_percentage: Optional[float]
    total_attended: int
    total_conducted: int
    target_percentage: float
    minimum_percentage: float
    trend_from_last_month: float
    
    # Semester progress dial
    current_week: int
    total_weeks: int
    weeks_remaining: int
    semester_progress_pct: float
    
    # Today's classes
    today_date_str: str
    today_sessions: List[ClassSessionOut]
    
    # Subjects needing attention
    subjects_needing_attention: List[DashboardSubjectAttention]
    
    # Upcoming event / holiday
    upcoming_holiday: Optional[HolidayOut]
    
    # Quick insight
    quick_insight: Optional[InsightOut]
    
    # Small attendance trend
    trend_points: List[AttendanceTrendPoint]
