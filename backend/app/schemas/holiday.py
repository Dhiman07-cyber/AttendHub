from typing import Optional
from datetime import date
from pydantic import BaseModel, Field, ConfigDict, field_validator

def _normalize_holiday_category(v: Optional[str]) -> str:
    if not v:
        return "University Holiday"
    v_str = str(v).strip()
    allowed = {"University Holiday", "Festival", "Semester Break", "Exam Break", "Academic", "Other"}
    if v_str in allowed:
        return v_str
    if "break" in v_str.lower():
        if "exam" in v_str.lower():
            return "Exam Break"
        return "Semester Break"
    if "fest" in v_str.lower():
        return "Festival"
    if "acad" in v_str.lower():
        return "Academic"
    return "University Holiday"

class HolidayCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=150)
    start_date: date
    end_date: date
    category: Optional[str] = "University Holiday"
    notes: Optional[str] = None
    semester_id: Optional[str] = None

    @field_validator("category", mode="before")
    def validate_category(cls, v: Optional[str]) -> str:
        return _normalize_holiday_category(v)

class HolidayUpdate(BaseModel):
    title: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    category: Optional[str] = None
    notes: Optional[str] = None

    @field_validator("category", mode="before")
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        return _normalize_holiday_category(v)

class HolidayOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    user_id: str
    semester_id: Optional[str]
    title: str
    start_date: date
    end_date: date
    category: str
    notes: Optional[str]
    source: str
    duration_days: int
    is_upcoming: bool
    relative_time_label: str
