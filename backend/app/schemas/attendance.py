from typing import Optional, List
import datetime as dt
from pydantic import BaseModel, Field, ConfigDict

class AttendanceMarkItem(BaseModel):
    session_id: Optional[str] = None
    timetable_entry_id: Optional[str] = None
    subject_id: Optional[str] = None
    date: Optional[dt.date] = None
    status: str = Field(..., pattern="^(ATTENDED|ABSENT|NOT_HELD)$")

class AttendanceBulkMarkRequest(BaseModel):
    date: Optional[dt.date] = None
    items: List[AttendanceMarkItem]

class AttendanceCorrectionRequest(BaseModel):
    new_status: str = Field(..., pattern="^(ATTENDED|ABSENT|NOT_HELD)$")
    reason: Optional[str] = "Student correction"

class AttendanceRecordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    class_session_id: str
    user_id: str
    status: str
    marked_at: dt.datetime
    updated_at: dt.datetime
    source: str

class AttendanceSaveResult(BaseModel):
    updated_count: int
    message: str
    overall_percentage: Optional[float]
    projected_change: Optional[float] = 0.0
