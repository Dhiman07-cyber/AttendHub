from typing import Optional
from datetime import date
from pydantic import BaseModel, Field, ConfigDict

class SemesterCreate(BaseModel):
    semester_number: int = Field(..., ge=1, le=20)
    label: str = Field(..., min_length=1, max_length=100)
    start_date: date
    end_date: date
    status: Optional[str] = "ACTIVE"
    total_weeks: Optional[int] = 16

class SemesterUpdate(BaseModel):
    label: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: Optional[str] = None
    total_weeks: Optional[int] = None

class SemesterOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    user_id: str
    semester_number: int
    label: str
    start_date: date
    end_date: date
    status: str
    is_active: bool
    total_weeks: int
    current_week: int = 1
    weeks_remaining: int = 0
    progress_percentage: float = 0.0

class SemesterSwitchRequest(BaseModel):
    semester_id: str
