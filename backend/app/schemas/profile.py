from typing import Optional
from pydantic import BaseModel, Field, ConfigDict, field_validator

class AcademicProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    user_id: str
    full_name: str
    email: str
    university_name: str
    course_name: str
    student_id_number: Optional[str]
    academic_duration_years: int
    academic_session_start: Optional[int]
    academic_session_end: Optional[int]
    current_semester_id: Optional[str]
    current_semester_label: Optional[str]
    minimum_attendance: float
    personal_target: float
    low_attendance_alert: float

class AcademicProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    university_name: Optional[str] = None
    course_name: Optional[str] = None
    student_id_number: Optional[str] = None
    academic_duration_years: Optional[int] = None
    academic_session_start: Optional[int] = None
    academic_session_end: Optional[int] = None
    minimum_attendance: Optional[float] = Field(None, ge=0.0, le=100.0)
    personal_target: Optional[float] = Field(None, ge=0.0, le=100.0)
    low_attendance_alert: Optional[float] = Field(None, ge=0.0, le=100.0)

class SetupStatusOut(BaseModel):
    is_profile_complete: bool
    has_active_semester: bool
    is_semester_configured: bool
    setup_complete: bool
    current_semester_id: Optional[str] = None
    current_semester_label: Optional[str] = None
    subject_count: int = 0

from datetime import date
from typing import List

class SetupSubjectDraft(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    code: Optional[str] = Field(None, max_length=50)
    faculty_name: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = "#C96E5B"

class SetupTimetableDraft(BaseModel):
    subject_name: str
    day_of_week: int = Field(..., ge=0, le=6)
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    room: Optional[str] = None
    faculty_name: Optional[str] = None

class SetupHolidayDraft(BaseModel):
    title: str = Field(..., min_length=1, max_length=150)
    start_date: date
    end_date: date
    category: str = "University Holiday"
    notes: Optional[str] = None

    @field_validator("category", mode="before")
    def normalize_category(cls, v: Optional[str]) -> str:
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

class SetupStartingAttendanceDraft(BaseModel):
    subject_name: str
    attended_count: int = Field(0, ge=0)
    conducted_count: int = Field(0, ge=0)

class FullAcademicSetupRequest(BaseModel):
    # Step 1: Global Profile
    university_name: str = Field(..., min_length=1, max_length=200)
    course_name: str = Field(..., min_length=1, max_length=200)
    full_name: Optional[str] = None
    student_id_number: Optional[str] = None
    academic_duration_years: int = Field(4, ge=1, le=10)
    academic_session_start: Optional[int] = Field(2024, ge=1990, le=2100)
    academic_session_end: Optional[int] = Field(2028, ge=1990, le=2100)
    
    # Step 2: Semester
    semester_id: Optional[str] = None
    semester_number: int = Field(1, ge=1, le=12)
    semester_label: str = Field("1st Semester", min_length=1, max_length=100)
    start_date: date
    end_date: date
    minimum_attendance: float = Field(75.0, ge=0.0, le=100.0)
    personal_target: float = Field(75.0, ge=0.0, le=100.0)
    low_attendance_alert: float = Field(70.0, ge=0.0, le=100.0)
    
    # Step 3: Subjects
    subjects: List[SetupSubjectDraft] = []
    
    # Step 4: Timetable
    timetable_entries: List[SetupTimetableDraft] = []
    
    # Step 5: Holidays
    holidays: List[SetupHolidayDraft] = []
    
    # Step 6: Starting Attendance
    starting_attendance: List[SetupStartingAttendanceDraft] = []

class SetupSemesterInfo(BaseModel):
    semester_id: Optional[str] = None
    semester_number: int
    semester_label: str
    start_date: date
    end_date: date
    is_existing: bool
    is_active: bool = False

class FullAcademicSetupDataOut(BaseModel):
    full_name: Optional[str] = None
    university_name: str
    course_name: str
    student_id_number: Optional[str] = None
    academic_duration_years: int
    academic_session_start: Optional[int] = None
    academic_session_end: Optional[int] = None
    minimum_attendance: float
    personal_target: float
    low_attendance_alert: float
    
    semester: SetupSemesterInfo
    subjects: List[SetupSubjectDraft] = []
    timetable_entries: List[SetupTimetableDraft] = []
    holidays: List[SetupHolidayDraft] = []
    starting_attendance: List[SetupStartingAttendanceDraft] = []
    available_semester_numbers: List[int] = []


