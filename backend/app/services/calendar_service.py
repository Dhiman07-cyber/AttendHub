import calendar
from datetime import date, timedelta
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from app.models.session import ClassSession
from app.models.subject import Subject
from app.models.holiday import Holiday
from app.models.attendance import AttendanceRecord
from app.schemas.calendar import CalendarDayMarker, CalendarMonthOut
from app.services.academic_service import get_active_semester
from app.services.attendance_service import get_today_sessions
from app.services.holiday_service import list_holidays

MONTH_NAMES = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
]

async def get_calendar_month(
    db: AsyncSession,
    user_id: str,
    year: Optional[int] = None,
    month: Optional[int] = None,
    selected_date: Optional[date] = None
) -> CalendarMonthOut:
    today_now = date.today()
    if year is None:
        year = today_now.year
    if month is None:
        month = today_now.month
    if not selected_date:
        selected_date = today_now

    active_sem = await get_active_semester(db, user_id)
    first_day = date(year, month, 1)
    _, num_days = calendar.monthrange(year, month)
    last_day = date(year, month, num_days)

    # 1. Fetch holidays in this month
    hol_stmt = select(Holiday).where(
        Holiday.user_id == user_id,
        Holiday.start_date <= last_day,
        Holiday.end_date >= first_day
    )
    hol_res = await db.execute(hol_stmt)
    holidays = hol_res.scalars().all()

    # 2. Fetch all sessions in this month
    sess_stmt = (
        select(ClassSession, AttendanceRecord)
        .outerjoin(AttendanceRecord, and_(
            AttendanceRecord.class_session_id == ClassSession.id,
            AttendanceRecord.user_id == user_id
        ))
        .where(
            ClassSession.semester_id == active_sem.id,
            ClassSession.date >= first_day,
            ClassSession.date <= last_day
        )
    )
    sess_res = await db.execute(sess_stmt)
    sessions = sess_res.all()

    # Index sessions by date
    sessions_by_date = {}
    for cs, att in sessions:
        if cs.date not in sessions_by_date:
            sessions_by_date[cs.date] = []
        sessions_by_date[cs.date].append((cs, att))

    # Index holidays by date
    holidays_by_date = {}
    for h in holidays:
        cur = max(first_day, h.start_date)
        end = min(last_day, h.end_date)
        while cur <= end:
            if cur not in holidays_by_date:
                holidays_by_date[cur] = []
            holidays_by_date[cur].append(h)
            cur += timedelta(days=1)

    today_ref = date.today()
    day_markers: List[CalendarDayMarker] = []

    for d in range(1, num_days + 1):
        cur_d = date(year, month, d)
        d_sessions = sessions_by_date.get(cur_d, [])
        d_holidays = holidays_by_date.get(cur_d, [])

        has_classes = len(d_sessions) > 0
        has_holiday = len(d_holidays) > 0
        has_exam = any("exam" in h.category.lower() or "assessment" in h.title.lower() for h in d_holidays)
        has_other = any(h.category.lower() == "other" for h in d_holidays)

        # Dominant status
        dominant = None
        if has_holiday:
            dominant = "holiday"
        elif has_classes:
            statuses = [att.status for _, att in d_sessions if att]
            if statuses:
                if all(s == "ATTENDED" for s in statuses):
                    dominant = "attended"
                elif all(s == "ABSENT" for s in statuses):
                    dominant = "absent"
                else:
                    dominant = "mixed"

        day_markers.append(CalendarDayMarker(
            date=cur_d,
            day=d,
            is_current_month=True,
            is_today=(cur_d == today_ref),
            has_classes=has_classes,
            has_holiday=has_holiday,
            has_exam=has_exam,
            has_other=has_other,
            dominant_status=dominant,
            class_count=len(d_sessions),
            holiday_count=len(d_holidays)
        ))

    # Fetch sessions for selected date
    selected_day_overview = await get_today_sessions(db, user_id, selected_date)
    
    # Fetch holidays for selected date
    selected_hols = [
        h for h in await list_holidays(db, user_id, active_sem.id)
        if h.start_date <= selected_date <= h.end_date
    ]

    return CalendarMonthOut(
        year=year,
        month=month,
        month_name=MONTH_NAMES[month],
        days=day_markers,
        selected_date_sessions=selected_day_overview.sessions,
        selected_date_holidays=selected_hols
    )
