from typing import Optional
from datetime import date
from pydantic import BaseModel, Field, ConfigDict

class TimetableEntryCreate(BaseModel):
    subject_id: str
    day_of_week: Optional[int] = Field(None, ge=0, le=6) # 0=Mon, 6=Sun
    start_time: Optional[str] = None # "09:00"
    end_time: Optional[str] = None # "10:00"
    faculty_name: Optional[str] = None
    room: Optional[str] = None
    effective_from: Optional[date] = None
    effective_to: Optional[date] = None
    # THEORY, LAB, or UNSPECIFIED — defaults to None (treated as UNSPECIFIED)
    class_type: Optional[str] = None

class TimetableEntryUpdate(BaseModel):
    day_of_week: Optional[int] = Field(None, ge=0, le=6)
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    faculty_name: Optional[str] = None
    room: Optional[str] = None
    effective_from: Optional[date] = None
    effective_to: Optional[date] = None
    class_type: Optional[str] = None

class TimetableEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    semester_id: str
    subject_id: str
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    subject_icon: Optional[str] = None
    day_of_week: Optional[int]
    day_name: Optional[str] = None
    start_time: Optional[str]
    end_time: Optional[str]
    faculty_name: Optional[str]
    room: Optional[str]
    effective_from: Optional[date]
    effective_to: Optional[date]
    class_type: Optional[str] = None  # THEORY, LAB, or UNSPECIFIED/None for legacy

class WeeklySlotStatusOut(BaseModel):
    timetable_entry_id: str
    subject_id: str
    subject_name: str
    subject_code: Optional[str] = None
    subject_color: str = "#C96E5B"
    subject_icon: str = "book"
    day_of_week: int
    date: date
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    room: Optional[str] = None
    faculty_name: Optional[str] = None
    class_type: Optional[str] = None  # THEORY, LAB, UNSPECIFIED, or None
    session_id: Optional[str] = None
    attendance_status: Optional[str] = None
    is_attended: bool = False
    is_absent: bool = False
    is_not_held: bool = False
    is_unmarked: bool = True

class WeeklyDayStatusOut(BaseModel):
    day_of_week: int
    day_name: str
    date: date
    is_holiday: bool = False
    holiday_title: Optional[str] = None
    is_today: bool = False
    is_past: bool = False
    is_future: bool = False
    slots: list[WeeklySlotStatusOut] = []

class WeeklyRoutineStatusOut(BaseModel):
    week_offset: int
    start_date: date
    end_date: date
    week_label: str = "This week"
    date_range_label: str = ""
    semester_id: str
    semester_label: str
    days: list[WeeklyDayStatusOut] = []

