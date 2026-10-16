from typing import Dict, Any, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, case
from fastapi import HTTPException, status
from collections import defaultdict
from datetime import date

from app.models.semester import Semester
from app.models.subject import Subject
from app.models.session import ClassSession
from app.models.attendance import AttendanceRecord
from app.models.profile import AcademicProfile
from app.models.timetable import TimetableEntry
from app.models.holiday import Holiday
from app.schemas.analytics import (
    SubjectAnalyticsOut, AttendanceTrendPoint, AnalyticsOverviewOut, InsightOut,
    TypeBreakdownMetrics
)
from app.calculations.attendance_engine import (
    calculate_subject_metrics, calculate_overall_metrics, calculate_subject_with_type_breakdown
)
from app.calculations.forecast_engine import (
    calculate_future_classes_count, calculate_projected_final_attendance,
    calculate_max_future_absences_by_semester_end, calculate_forecast_status,
    enumerate_future_class_dates
)
from app.calculations.insight_engine import generate_insights_for_semester
from app.services.academic_service import get_active_semester


async def _fetch_subject_attendance_counts(
    db: AsyncSession,
    user_id: str,
    semester_id: str
) -> Dict[str, Dict[str, int]]:
    """
    Single grouped query replacing N+1 per-subject count queries.
    Returns overall + Theory + Lab breakdown counts.
    Groups by raw columns (subject_id, class_type) to ensure strict PostgreSQL
    compatibility without parameter expression mismatch in GROUP BY.
    """
    stmt = (
        select(
            ClassSession.subject_id,
            ClassSession.class_type,
            func.count(case((AttendanceRecord.status == "ATTENDED", 1))).label("attended"),
            func.count(case((AttendanceRecord.status == "ABSENT", 1))).label("absent")
        )
        .join(AttendanceRecord, AttendanceRecord.class_session_id == ClassSession.id)
        .where(
            AttendanceRecord.user_id == user_id,
            ClassSession.semester_id == semester_id
        )
        .group_by(ClassSession.subject_id, ClassSession.class_type)
    )
    result = await db.execute(stmt)
    
    # Build nested structure: subject_id -> {overall, THEORY, LAB, UNSPECIFIED}
    counts = defaultdict(lambda: {
        "attended": 0, "absent": 0,
        "theory_attended": 0, "theory_absent": 0,
        "lab_attended": 0, "lab_absent": 0,
        "unspecified_attended": 0, "unspecified_absent": 0
    })
    
    for row in result.all():
        sid = row.subject_id
        ctype = row.class_type or "UNSPECIFIED"
        att = row.attended or 0
        ab = row.absent or 0
        
        counts[sid]["attended"] += att
        counts[sid]["absent"] += ab
        
        if ctype == "THEORY":
            counts[sid]["theory_attended"] += att
            counts[sid]["theory_absent"] += ab
        elif ctype == "LAB":
            counts[sid]["lab_attended"] += att
            counts[sid]["lab_absent"] += ab
        else:  # UNSPECIFIED
            counts[sid]["unspecified_attended"] += att
            counts[sid]["unspecified_absent"] += ab
    
    return dict(counts)

async def get_semester_overall_metrics(
    db: AsyncSession,
    user_id: str,
    semester_id: str
) -> Dict[str, Any]:
    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    prof_res = await db.execute(prof_stmt)
    prof = prof_res.scalar_one_or_none()
    min_req = prof.minimum_attendance if prof else 75.0
    target_req = prof.personal_target if prof else 75.0

    # Get subjects in semester
    sub_stmt = select(Subject).where(Subject.semester_id == semester_id, Subject.is_active == True)
    sub_res = await db.execute(sub_stmt)
    subjects = sub_res.scalars().all()

    counts_map = await _fetch_subject_attendance_counts(db, user_id, semester_id)

    records = []
    for s in subjects:
        c = counts_map.get(s.id, {"attended": 0, "absent": 0})
        records.append({
            "subject_id": s.id,
            "name": s.name,
            "attended": c["attended"],
            "absent": c["absent"]
        })

    return calculate_overall_metrics(records, min_req, target_req)

async def get_analytics_overview(
    db: AsyncSession,
    user_id: str,
    semester_id: Optional[str] = None,
    *,
    active_sem: Optional[Semester] = None,
    profile: Optional[AcademicProfile] = None,
    include_profile_Lookup: bool = True,
) -> AnalyticsOverviewOut:
    if active_sem is not None:
        sem = active_sem
        semester_id = sem.id
    elif not semester_id:
        sem = await get_active_semester(db, user_id)
        semester_id = sem.id
    else:
        sem_stmt = select(Semester).where(Semester.id == semester_id, Semester.user_id == user_id)
        sem_res = await db.execute(sem_stmt)
        sem = sem_res.scalar_one_or_none()
        if not sem:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Semester not found.")

    if profile is not None or not include_profile_Lookup:
        prof = profile
    else:
        prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
        prof_res = await db.execute(prof_stmt)
        prof = prof_res.scalar_one_or_none()
    min_req = prof.minimum_attendance if prof else 75.0
    target_req = prof.personal_target if prof else 75.0

    # Get subjects in semester
    sub_stmt = select(Subject).where(Subject.semester_id == semester_id, Subject.is_active == True).order_by(Subject.name.asc())
    sub_res = await db.execute(sub_stmt)
    subjects = sub_res.scalars().all()

    counts_map = await _fetch_subject_attendance_counts(db, user_id, semester_id)

    # Fetch timetable entries for forecast
    tt_stmt = select(TimetableEntry).where(TimetableEntry.semester_id == semester_id)
    tt_res = await db.execute(tt_stmt)
    timetable_entries = tt_res.scalars().all()
    tt_dicts = [
        {
            "id": e.id,
            "subject_id": e.subject_id,
            "day_of_week": e.day_of_week,
            "start_time": e.start_time,
            "end_time": e.end_time,
            "class_type": e.class_type or "UNSPECIFIED",
            "effective_from": e.effective_from,
            "effective_to": e.effective_to
        } for e in timetable_entries
    ]

    # Fetch holidays
    hol_stmt = select(Holiday).where(Holiday.semester_id == semester_id, Holiday.user_id == user_id)
    hol_res = await db.execute(hol_stmt)
    holidays = hol_res.scalars().all()
    holiday_ranges = [(h.start_date, h.end_date) for h in holidays]

    # Forecast parameters
    today = date.today()
    forecast_from = today
    semester_start = sem.start_date
    semester_end = sem.end_date
    
    forecast_status = calculate_forecast_status(
        semester_start, semester_end, tt_dicts
    )

    subjects_out: List[SubjectAnalyticsOut] = []
    subject_metric_dicts: List[Dict[str, Any]] = []

    total_recovery = 0
    total_safe_margin = 0

    for s in subjects:
        c = counts_map.get(s.id, {
            "attended": 0, "absent": 0,
            "theory_attended": 0, "theory_absent": 0,
            "lab_attended": 0, "lab_absent": 0,
            "unspecified_attended": 0, "unspecified_absent": 0
        })
        
        att = c["attended"]
        ab = c["absent"]
        theory_att = c["theory_attended"]
        theory_ab = c["theory_absent"]
        lab_att = c["lab_attended"]
        lab_ab = c["lab_absent"]

        # Calculate with breakdown
        breakdown = calculate_subject_with_type_breakdown(
            att, ab, theory_att, theory_ab, lab_att, lab_ab, min_req, target_req
        )

        # Future classes forecast for this subject
        if forecast_status == "COMPLETE":
            remaining = calculate_future_classes_count(
                tt_dicts, semester_start, semester_end, holiday_ranges,
                forecast_from, subject_id=s.id
            )
            remaining_theory = calculate_future_classes_count(
                tt_dicts, semester_start, semester_end, holiday_ranges,
                forecast_from, subject_id=s.id, class_type_filter="THEORY"
            )
            remaining_lab = calculate_future_classes_count(
                tt_dicts, semester_start, semester_end, holiday_ranges,
                forecast_from, subject_id=s.id, class_type_filter="LAB"
            )
            projected_final = calculate_projected_final_attendance(att, att + ab, remaining)
            max_abs_min = calculate_max_future_absences_by_semester_end(att, att + ab, remaining, min_req)
            max_abs_target = calculate_max_future_absences_by_semester_end(att, att + ab, remaining, target_req)
        else:
            remaining = None
            remaining_theory = None
            remaining_lab = None
            projected_final = None
            max_abs_min = None
            max_abs_target = None

        m = {
            "subject_id": s.id,
            "name": s.name,
            "attended": breakdown["attended"],
            "absent": breakdown["absent"],
            "conducted": breakdown["conducted"],
            "percentage": breakdown["percentage"],
            "has_data": breakdown["has_data"],
            "status": breakdown["status"],
            "status_label": breakdown["status_label"],
            "minimum_requirement": breakdown["minimum_requirement"],
            "personal_target": breakdown["personal_target"],
            "classes_needed_for_min": breakdown["classes_needed_for_min"],
            "classes_needed_for_target": breakdown["classes_needed_for_target"],
            "max_safe_absences": breakdown["max_safe_absences"],
            "can_miss_message": breakdown["can_miss_message"],
            "recovery_message": breakdown["recovery_message"]
        }
        subject_metric_dicts.append(m)

        if m["classes_needed_for_min"]:
            total_recovery += m["classes_needed_for_min"]
        total_safe_margin += m["max_safe_absences"]

        # Build Theory/Lab metrics
        theory_m = breakdown.get("theory_metrics")
        lab_m = breakdown.get("lab_metrics")

        subjects_out.append(SubjectAnalyticsOut(
            subject_id=s.id,
            name=s.name,
            code=s.code,
            faculty_name=s.faculty_name,
            color=s.color,
            icon=s.icon,
            attended=m["attended"],
            absent=m["absent"],
            conducted=m["conducted"],
            percentage=m["percentage"],
            has_data=m["has_data"],
            status=m["status"],
            status_label=m["status_label"],
            minimum_requirement=m["minimum_requirement"],
            personal_target=m["personal_target"],
            classes_needed_for_min=m["classes_needed_for_min"],
            classes_needed_for_target=m["classes_needed_for_target"],
            max_safe_absences=m["max_safe_absences"],
            can_miss_message=m["can_miss_message"],
            recovery_message=m["recovery_message"],
            theory_metrics=TypeBreakdownMetrics(**theory_m) if theory_m else None,
            lab_metrics=TypeBreakdownMetrics(**lab_m) if lab_m else None,
            unclassified_attended=breakdown.get("unclassified_attended", 0),
            unclassified_conducted=breakdown.get("unclassified_conducted", 0),
            remaining_classes=remaining,
            remaining_theory_classes=remaining_theory,
            remaining_lab_classes=remaining_lab,
            projected_final_percentage=projected_final,
            max_future_absences_for_min=max_abs_min,
            max_future_absences_for_target=max_abs_target,
            forecast_status=forecast_status
        ))

    overall = calculate_overall_metrics(subject_metric_dicts, min_req, target_req)
    raw_insights = generate_insights_for_semester(subject_metric_dicts, overall)
    insights_out = [InsightOut(**ins) for ins in raw_insights]

    # Compute genuine trends from actual session dates
    trend_stmt = (
        select(
            ClassSession.date,
            AttendanceRecord.status
        )
        .join(AttendanceRecord, AttendanceRecord.class_session_id == ClassSession.id)
        .where(
            AttendanceRecord.user_id == user_id,
            ClassSession.semester_id == semester_id
        )
        .order_by(ClassSession.date.asc())
    )
    trend_res = await db.execute(trend_stmt)
    trend_rows = trend_res.all()

    # Group by (Year, Month)
    month_data = defaultdict(lambda: {"attended": 0, "conducted": 0})
    for sess_date, att_status in trend_rows:
        if att_status in ("ATTENDED", "ABSENT"):
            key = (sess_date.year, sess_date.month)
            month_data[key]["conducted"] += 1
            if att_status == "ATTENDED":
                month_data[key]["attended"] += 1

    trends: List[AttendanceTrendPoint] = []
    month_names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    sorted_months = sorted(month_data.keys())

    for yr, mo in sorted_months:
        d = month_data[(yr, mo)]
        pct = round((d["attended"] / d["conducted"]) * 100.0, 1) if d["conducted"] > 0 else 0.0
        trends.append(AttendanceTrendPoint(
            label=f"{month_names[mo]}",
            percentage=pct,
            attended=d["attended"],
            conducted=d["conducted"]
        ))

    month_over_month_change = 0.0
    if len(trends) >= 2:
        month_over_month_change = round(trends[-1].percentage - trends[-2].percentage, 1)

    # Overall semester forecast
    if forecast_status == "COMPLETE":
        total_remaining = calculate_future_classes_count(
            tt_dicts, semester_start, semester_end, holiday_ranges,
            forecast_from
        )
        projected_overall_final = calculate_projected_final_attendance(
            overall["total_attended"], overall["total_conducted"], total_remaining
        )
    else:
        total_remaining = None
        projected_overall_final = None

    return AnalyticsOverviewOut(
        semester_id=sem.id,
        semester_label=sem.label,
        total_attended=overall["total_attended"],
        total_absent=overall["total_absent"],
        total_conducted=overall["total_conducted"],
        overall_percentage=overall["overall_percentage"],
        has_data=overall["has_data"],
        status=overall["status"],
        status_label=overall["status_label"],
        minimum_requirement=overall["minimum_requirement"],
        personal_target=overall["personal_target"],
        classes_needed_for_min=overall["classes_needed_for_min"],
        classes_needed_for_target=overall["classes_needed_for_target"],
        max_safe_absences=overall["max_safe_absences"],
        total_recovery_classes_needed=total_recovery,
        total_safe_absences_margin=total_safe_margin,
        subjects=subjects_out,
        insights=insights_out,
        trends=trends,
        month_over_month_change=month_over_month_change,
        total_remaining_classes=total_remaining,
        projected_overall_final_percentage=projected_overall_final,
        forecast_status=forecast_status
    )
