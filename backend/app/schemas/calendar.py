from typing import List, Optional
from datetime import date
from pydantic import BaseModel
from app.schemas.session import ClassSessionOut
from app.schemas.holiday import HolidayOut

class CalendarDayMarker(BaseModel):
    date: date
    day: int
    is_current_month: bool
    is_today: bool
    has_classes: bool
    has_holiday: bool
    has_exam: bool
    has_other: bool
    dominant_status: Optional[str] = None # "attended", "absent", "mixed", "holiday"
    class_count: int = 0
    holiday_count: int = 0

class CalendarMonthOut(BaseModel):
    year: int
    month: int
    month_name: str
    days: List[CalendarDayMarker]
    selected_date_sessions: List[ClassSessionOut]
    selected_date_holidays: List[HolidayOut]
