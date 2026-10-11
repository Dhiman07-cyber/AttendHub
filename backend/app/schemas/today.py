from typing import List, Optional
from datetime import date
from pydantic import BaseModel
from app.schemas.session import ClassSessionOut

class TodayOverviewOut(BaseModel):
    selected_date: date
    selected_date_str: str # e.g. "Wednesday, 8 October 2026"
    semester_label: str
    total_classes: int
    marked_classes: int
    pending_classes: int
    not_held_classes: int
    sessions: List[ClassSessionOut]
    
    # Impact simulation (if unsaved changes or current overall)
    current_overall_percentage: Optional[float]
    projected_overall_percentage: Optional[float]
    projected_delta: float = 0.0
