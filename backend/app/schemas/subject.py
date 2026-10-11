from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict

class SubjectCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    code: Optional[str] = None
    faculty_name: Optional[str] = None
    color: Optional[str] = "#C96E5B"
    icon: Optional[str] = "book"

class SubjectUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    faculty_name: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None
    is_active: Optional[bool] = None

class SubjectOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    semester_id: str
    name: str
    code: Optional[str]
    faculty_name: Optional[str]
    color: str
    icon: str
    is_active: bool
    
    # Quick attendance glimpse
    attended: int = 0
    conducted: int = 0
    percentage: Optional[float] = None
    status: str = "NO_DATA"
    status_label: str = "No attendance data yet"
    schedule_summary: Optional[str] = None

class SubjectDetailOut(SubjectOut):
    absent: int = 0
    classes_needed_for_min: Optional[int] = 0
    classes_needed_for_target: Optional[int] = 0
    max_safe_absences: int = 0
    can_miss_message: str = ""
    recovery_message: str = ""
