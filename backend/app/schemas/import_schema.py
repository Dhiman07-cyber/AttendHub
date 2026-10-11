from typing import List, Optional
from datetime import date
from pydantic import BaseModel

class RoutineDraftEntry(BaseModel):
    subject_name: str
    subject_code: Optional[str] = None
    faculty_name: Optional[str] = None
    day_of_week: int # 0=Mon, 4=Fri
    start_time: str # "09:00"
    end_time: str # "10:00"
    room: Optional[str] = None
    confidence: float = 0.95

class RoutineReviewRequest(BaseModel):
    semester_id: str
    entries: List[RoutineDraftEntry]

class HolidayDraftEntry(BaseModel):
    title: str
    start_date: date
    end_date: date
    category: str = "University Holiday"
    notes: Optional[str] = None
    confidence: float = 0.95

class HolidayReviewRequest(BaseModel):
    semester_id: Optional[str] = None
    holidays: List[HolidayDraftEntry]

class ImportParseResponse(BaseModel):
    file_id: str
    file_name: str
    source_type: str # "routine" or "holiday"
    parser_used: str # "mock_ocr_extractor", "rule_based"
    draft_routine: Optional[List[RoutineDraftEntry]] = None
    draft_holidays: Optional[List[HolidayDraftEntry]] = None
    warning_notes: List[str] = []
