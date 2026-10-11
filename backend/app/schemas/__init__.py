from app.schemas.auth import (
    UserRegister, UserLogin, Token, RefreshTokenRequest,
    PasswordResetRequest, PasswordResetConfirm, UserOut
)
from app.schemas.profile import AcademicProfileOut, AcademicProfileUpdate
from app.schemas.semester import SemesterCreate, SemesterUpdate, SemesterOut, SemesterSwitchRequest
from app.schemas.subject import SubjectCreate, SubjectUpdate, SubjectOut, SubjectDetailOut
from app.schemas.timetable import TimetableEntryCreate, TimetableEntryUpdate, TimetableEntryOut
from app.schemas.session import ClassSessionCreate, ExtraClassCreate, ClassSessionOut
from app.schemas.attendance import (
    AttendanceMarkItem, AttendanceBulkMarkRequest, AttendanceCorrectionRequest,
    AttendanceRecordOut, AttendanceSaveResult
)
from app.schemas.holiday import HolidayCreate, HolidayUpdate, HolidayOut
from app.schemas.analytics import (
    InsightOut, SubjectAnalyticsOut, AttendanceTrendPoint, AnalyticsOverviewOut
)
from app.schemas.dashboard import DashboardOverviewOut, DashboardSubjectAttention
from app.schemas.today import TodayOverviewOut
from app.schemas.calendar import CalendarDayMarker, CalendarMonthOut
from app.schemas.import_schema import (
    RoutineDraftEntry, RoutineReviewRequest, HolidayDraftEntry,
    HolidayReviewRequest, ImportParseResponse
)
