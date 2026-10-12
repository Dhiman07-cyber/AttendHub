from typing import Optional, List, Any
import datetime as dt
from pydantic import BaseModel, Field, ConfigDict, model_validator

class AttendanceMarkItem(BaseModel):
    session_id: Optional[str] = None
    timetable_entry_id: Optional[str] = None
    subject_id: Optional[str] = None
    date: Optional[dt.date] = None
    status: str = Field(..., pattern="^(ATTENDED|ABSENT|NOT_HELD)$")

class AttendanceBulkMarkRequest(BaseModel):
    date: Optional[dt.date] = None
    items: Optional[List[AttendanceMarkItem]] = None
    records: Optional[List[AttendanceMarkItem]] = None

    @model_validator(mode="before")
    @classmethod
    def reconcile_items_and_records(cls, data: Any) -> Any:
        if isinstance(data, dict):
            # Support both 'records' (documented in docs/api.md & mobile payload) and 'items'
            if "records" in data and ("items" not in data or data.get("items") is None):
                data["items"] = data["records"]
            elif "items" in data and ("records" not in data or data.get("records") is None):
                data["records"] = data["items"]
        return data

    @model_validator(mode="after")
    def ensure_populated(self) -> "AttendanceBulkMarkRequest":
        if self.items is None and self.records is None:
            self.items = []
            self.records = []
        elif self.items is None and self.records is not None:
            self.items = self.records
        elif self.records is None and self.items is not None:
            self.records = self.items
        return self

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
