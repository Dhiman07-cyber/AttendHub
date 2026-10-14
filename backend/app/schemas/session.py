from typing import Optional
from datetime import date
from pydantic import BaseModel, ConfigDict

class ClassSessionCreate(BaseModel):
    subject_id: str
    date: date
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    faculty_name: Optional[str] = None
    room: Optional[str] = None
    session_status: Optional[str] = "SCHEDULED"
    is_extra: Optional[bool] = False

class ExtraClassCreate(BaseModel):
    subject_id: str
    date: Optional[date] = None # defaults to today
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    faculty_name: Optional[str] = None
    room: Optional[str] = None

class ClassSessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    semester_id: str
    subject_id: str
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    subject_icon: Optional[str] = None
    date: date
    start_time: Optional[str]
    end_time: Optional[str]
    faculty_name: Optional[str]
    room: Optional[str]
    session_status: str
    is_extra: bool
    
    timetable_entry_id: Optional[str] = None
    subject_code: Optional[str] = None
    
    # Timing status (Done, Now, Upcoming, or null if no timing)
    time_status: Optional[str] = None
    
    # Attendance status for this session
    attendance_status: Optional[str] = None # ATTENDED, ABSENT, NOT_HELD, or None (Pending)
    attendance_id: Optional[str] = None
    
    # Class type: THEORY, LAB, UNSPECIFIED (None = legacy/unclassified)
    class_type: Optional[str] = None
