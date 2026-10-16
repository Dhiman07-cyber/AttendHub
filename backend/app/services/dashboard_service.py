from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User
from app.models.profile import AcademicProfile
from app.schemas.dashboard import DashboardOverviewOut, DashboardSubjectAttention
from app.services.academic_service import get_active_semester, _compute_semester_stats
from app.services.analytics_service import get_analytics_overview
from app.services.attendance_service import get_today_sessions
from app.services.holiday_service import get_next_upcoming_holiday

async def get_dashboard_overview(db: AsyncSession, user_id: str) -> DashboardOverviewOut:
    # 1. User & profile
    u_stmt = select(User).where(User.id == user_id)
    u_res = await db.execute(u_stmt)
    user = u_res.scalar_one()

    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    prof_res = await db.execute(prof_stmt)
    prof = prof_res.scalar_one_or_none()

    active_sem = await get_active_semester(db, user_id)
    sem_stats = _compute_semester_stats(active_sem)

    if not prof:
        prof = AcademicProfile(
            user_id=user_id,
            university_name="",
            course_name="",
            student_id_number=None,
            academic_duration_years=4,
            academic_session_start=2024,
            academic_session_end=2028,
            current_semester_id=active_sem.id,
            minimum_attendance=75.0,
            personal_target=75.0,
            low_attendance_alert=70.0
        )
        db.add(prof)
        await db.commit()
        await db.refresh(prof)

    # 2. Analytics overview (reuse already-fetched active_sem and prof)
    analytics = await get_analytics_overview(
        db,
        user_id,
        active_sem.id,
        active_sem=active_sem,
        profile=prof,
        include_profile_Lookup=False,
    )

    # 3. Today's classes (reuse active_sem and analytics.overall_percentage)
    today_dt = date.today()
    today_data = await get_today_sessions(
        db,
        user_id,
        today_dt,
        active_sem=active_sem,
        precomputed_overall_pct=analytics.overall_percentage,
        has_precomputed_overall=True,
    )

    # 4. Subjects needing attention (sort by lowest percentage first)
    needing_attention = []
    critical_or_caution = [
        s for s in analytics.subjects 
        if s.has_data and s.percentage is not None and s.percentage < (prof.minimum_attendance if prof else 75.0)
    ]
    # If not enough critical, add caution
    if len(critical_or_caution) < 2:
        caution = [
            s for s in analytics.subjects 
            if s.has_data and s.percentage is not None and (prof.minimum_attendance if prof else 75.0) <= s.percentage < 75.0 + 3.0
        ]
        critical_or_caution.extend(caution)

    critical_or_caution.sort(key=lambda x: (x.percentage or 0))

    for s in critical_or_caution[:2]:
        msg = f"Need {s.classes_needed_for_min} more classes to reach {int(s.minimum_requirement)}%." if s.classes_needed_for_min else "Monitor closely"
        needing_attention.append(DashboardSubjectAttention(
            subject_id=s.subject_id,
            name=s.name,
            percentage=s.percentage,
            color=s.color,
            icon=s.icon,
            status=s.status,
            needed_classes_message=msg
        ))

    # 5. Upcoming holiday
    upcoming_hol = await get_next_upcoming_holiday(db, user_id)

    # 6. Quick insight (pick best insight)
    quick_ins = None
    if analytics.insights:
        # Prefer SAFE_ABSENCE_BUFFER or CRITICAL_RECOVERY
        preferred = next((i for i in analytics.insights if i.type == "SAFE_ABSENCE_BUFFER"), None)
        quick_ins = preferred or analytics.insights[0]

    enrollment_id = prof.student_id_number if (prof and prof.student_id_number) else None
    course_name = prof.course_name if (prof and prof.course_name) else "Academic"
    first_name = user.full_name.split()[0] if user.full_name else "Student"

    return DashboardOverviewOut(
        user_name=first_name,
        current_semester_label=active_sem.label,
        course_name=course_name,
        enrollment_id=enrollment_id,

        overall_percentage=analytics.overall_percentage,
        total_attended=analytics.total_attended,
        total_conducted=analytics.total_conducted,
        target_percentage=prof.personal_target if prof else 75.0,
        minimum_percentage=prof.minimum_attendance if prof else 75.0,
        trend_from_last_month=analytics.month_over_month_change,
        current_week=sem_stats.current_week,
        total_weeks=sem_stats.total_weeks,
        weeks_remaining=sem_stats.weeks_remaining,
        semester_progress_pct=sem_stats.progress_percentage,
        today_date_str=today_dt.strftime("%a, %d %b %Y"),
        today_sessions=today_data.sessions,
        subjects_needing_attention=needing_attention,
        upcoming_holiday=upcoming_hol,
        quick_insight=quick_ins,
        trend_points=analytics.trends
    )
