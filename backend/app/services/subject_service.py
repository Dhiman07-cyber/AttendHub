from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, delete
from fastapi import HTTPException, status

from app.models.subject import Subject
from app.models.semester import Semester
from app.models.session import ClassSession
from app.models.attendance import AttendanceRecord
from app.models.profile import AcademicProfile
from app.models.timetable import TimetableEntry
from app.schemas.subject import SubjectCreate, SubjectUpdate, SubjectOut, SubjectDetailOut, SubjectAttendanceAdjustRequest
from app.calculations.attendance_engine import calculate_subject_metrics
from app.services.academic_service import get_active_semester

async def _get_subject_counts(db: AsyncSession, user_id: str, subject_id: str) -> tuple[int, int]:
    """Return (attended_count, absent_count) for a subject."""
    # Attended count
    att_stmt = (
        select(func.count(AttendanceRecord.id))
        .join(ClassSession, AttendanceRecord.class_session_id == ClassSession.id)
        .where(
            AttendanceRecord.user_id == user_id,
            ClassSession.subject_id == subject_id,
            AttendanceRecord.status == "ATTENDED"
        )
    )
    att_res = await db.execute(att_stmt)
    attended = att_res.scalar_one() or 0

    # Absent count
    abs_stmt = (
        select(func.count(AttendanceRecord.id))
        .join(ClassSession, AttendanceRecord.class_session_id == ClassSession.id)
        .where(
            AttendanceRecord.user_id == user_id,
            ClassSession.subject_id == subject_id,
            AttendanceRecord.status == "ABSENT"
        )
    )
    abs_res = await db.execute(abs_stmt)
    absent = abs_res.scalar_one() or 0

    return attended, absent

def _format_schedule_entries(entries: List[TimetableEntry]) -> Optional[str]:
    if not entries:
        return None
    days_map = {0: "Mon", 1: "Tue", 2: "Wed", 3: "Thu", 4: "Fri", 5: "Sat", 6: "Sun"}
    days = sorted(list(set(e.day_of_week for e in entries if e.day_of_week is not None)))
    day_str = ", ".join(days_map.get(d, "") for d in days)

    first_time = next((f"{e.start_time} – {e.end_time}" for e in entries if e.start_time and e.end_time), None)
    if day_str and first_time:
        return f"{day_str} | {first_time}"
    elif day_str:
        return day_str
    return first_time

async def _get_schedule_summary(db: AsyncSession, subject_id: str) -> Optional[str]:
    stmt = select(TimetableEntry).where(TimetableEntry.subject_id == subject_id)
    res = await db.execute(stmt)
    entries = res.scalars().all()
    return _format_schedule_entries(list(entries))

async def list_subjects(
    db: AsyncSession,
    user_id: str,
    semester_id: Optional[str] = None,
    include_inactive: bool = False
) -> List[SubjectOut]:
    if not semester_id:
        sem = await get_active_semester(db, user_id)
        semester_id = sem.id
    else:
        # Verify semester ownership
        sem_check = await db.execute(select(Semester).where(Semester.id == semester_id, Semester.user_id == user_id))
        if not sem_check.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Semester not found.")

    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    prof_res = await db.execute(prof_stmt)
    prof = prof_res.scalar_one_or_none()
    min_req = prof.minimum_attendance if prof else 75.0
    target_req = prof.personal_target if prof else 75.0

    query = select(Subject).where(Subject.semester_id == semester_id)
    if not include_inactive:
        query = query.where(Subject.is_active == True)
    query = query.order_by(Subject.name.asc())
    
    result = await db.execute(query)
    subjects = result.scalars().all()
    if not subjects:
        return []

    from app.services.analytics_service import _fetch_subject_attendance_counts
    counts_map = await _fetch_subject_attendance_counts(db, user_id, semester_id)

    tt_res = await db.execute(
        select(TimetableEntry).where(TimetableEntry.semester_id == semester_id)
    )
    tt_by_subject: dict[str, List[TimetableEntry]] = {}
    for entry in tt_res.scalars().all():
        tt_by_subject.setdefault(entry.subject_id, []).append(entry)
    
    out: List[SubjectOut] = []
    for s in subjects:
        c = counts_map.get(s.id, {"attended": 0, "absent": 0})
        metrics = calculate_subject_metrics(c["attended"], c["absent"], min_req, target_req)
        schedule = _format_schedule_entries(tt_by_subject.get(s.id, []))
        
        out.append(SubjectOut(
            id=s.id,
            semester_id=s.semester_id,
            name=s.name,
            code=s.code,
            faculty_name=s.faculty_name,
            color=s.color,
            icon=s.icon,
            is_active=s.is_active,
            attended=metrics["attended"],
            conducted=metrics["conducted"],
            percentage=metrics["percentage"],
            status=metrics["status"],
            status_label=metrics["status_label"],
            schedule_summary=schedule
        ))
    return out

async def get_subject_detail(db: AsyncSession, user_id: str, subject_id: str) -> SubjectDetailOut:
    stmt = (
        select(Subject)
        .join(Semester, Subject.semester_id == Semester.id)
        .where(Subject.id == subject_id, Semester.user_id == user_id)
    )
    result = await db.execute(stmt)
    subj = result.scalar_one_or_none()
    if not subj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found.")

    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    prof_res = await db.execute(prof_stmt)
    prof = prof_res.scalar_one_or_none()
    min_req = prof.minimum_attendance if prof else 75.0
    target_req = prof.personal_target if prof else 75.0

    attended, absent = await _get_subject_counts(db, user_id, subj.id)
    metrics = calculate_subject_metrics(attended, absent, min_req, target_req)
    schedule = await _get_schedule_summary(db, subj.id)

    return SubjectDetailOut(
        id=subj.id,
        semester_id=subj.semester_id,
        name=subj.name,
        code=subj.code,
        faculty_name=subj.faculty_name,
        color=subj.color,
        icon=subj.icon,
        is_active=subj.is_active,
        attended=metrics["attended"],
        conducted=metrics["conducted"],
        absent=metrics["absent"],
        percentage=metrics["percentage"],
        status=metrics["status"],
        status_label=metrics["status_label"],
        schedule_summary=schedule,
        classes_needed_for_min=metrics["classes_needed_for_min"],
        classes_needed_for_target=metrics["classes_needed_for_target"],
        max_safe_absences=metrics["max_safe_absences"],
        can_miss_message=metrics["can_miss_message"],
        recovery_message=metrics["recovery_message"]
    )

async def create_subject(db: AsyncSession, user_id: str, data: SubjectCreate, semester_id: Optional[str] = None) -> SubjectOut:
    if not semester_id:
        sem = await get_active_semester(db, user_id)
        semester_id = sem.id
    else:
        sem_check = await db.execute(select(Semester).where(Semester.id == semester_id, Semester.user_id == user_id))
        if not sem_check.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Semester not found.")

    subj = Subject(
        semester_id=semester_id,
        name=data.name.strip(),
        code=data.code.strip() if data.code else None,
        faculty_name=data.faculty_name.strip() if data.faculty_name else None,
        color=data.color or "#C96E5B",
        icon=data.icon or "book",
        is_active=True
    )
    db.add(subj)
    await db.commit()
    await db.refresh(subj)
    return await get_subject_detail(db, user_id, subj.id)

async def update_subject(db: AsyncSession, user_id: str, subject_id: str, data: SubjectUpdate) -> SubjectDetailOut:
    stmt = (
        select(Subject)
        .join(Semester, Subject.semester_id == Semester.id)
        .where(Subject.id == subject_id, Semester.user_id == user_id)
    )
    result = await db.execute(stmt)
    subj = result.scalar_one_or_none()
    if not subj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found.")

    for field, val in data.model_dump(exclude_unset=True).items():
        if hasattr(subj, field) and val is not None:
            setattr(subj, field, val)

    await db.commit()
    await db.refresh(subj)
    return await get_subject_detail(db, user_id, subj.id)

async def delete_subject(db: AsyncSession, user_id: str, subject_id: str) -> dict:
    stmt = (
        select(Subject)
        .join(Semester, Subject.semester_id == Semester.id)
        .where(Subject.id == subject_id, Semester.user_id == user_id)
    )
    result = await db.execute(stmt)
    subj = result.scalar_one_or_none()
    if not subj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found.")

    # Check if sessions or attendance exist
    attended, absent = await _get_subject_counts(db, user_id, subject_id)
    if (attended + absent) > 0:
        # Soft-delete / Archive safely per spec
        subj.is_active = False
        await db.commit()
        return {"status": "archived", "message": "Subject has historical attendance and was safely archived."}
    else:
        # Hard delete safely
        await db.delete(subj)
        await db.commit()
        return {"status": "deleted", "message": "Subject removed successfully."}

async def adjust_subject_attendance(
    db: AsyncSession,
    user_id: str,
    subject_id: str,
    data: SubjectAttendanceAdjustRequest
) -> SubjectDetailOut:
    stmt = (
        select(Subject, Semester)
        .join(Semester, Subject.semester_id == Semester.id)
        .where(Subject.id == subject_id, Semester.user_id == user_id)
    )
    res = await db.execute(stmt)
    row = res.first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found.")
    subj, sem = row

    if data.attended > data.conducted:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attended classes cannot exceed conducted classes."
        )

    # 1. Clean up prior initial_setup and manual_adjustment records/sessions for this subject
    adj_records_stmt = select(AttendanceRecord).join(ClassSession).where(
        ClassSession.subject_id == subject_id,
        ClassSession.semester_id == sem.id,
        AttendanceRecord.user_id == user_id,
        AttendanceRecord.source.in_(["initial_setup", "manual_adjustment"])
    )
    adj_recs = (await db.execute(adj_records_stmt)).scalars().all()
    if adj_recs:
        sess_ids = [r.class_session_id for r in adj_recs]
        await db.execute(delete(AttendanceRecord).where(AttendanceRecord.id.in_([r.id for r in adj_recs])))
        await db.execute(delete(ClassSession).where(ClassSession.id.in_(sess_ids)))

    # 2. Count remaining concrete daily markings if any
    daily_stmt = select(AttendanceRecord.status, func.count()).join(ClassSession).where(
        ClassSession.subject_id == subject_id,
        ClassSession.semester_id == sem.id,
        AttendanceRecord.user_id == user_id,
    ).group_by(AttendanceRecord.status)
    daily_res = await db.execute(daily_stmt)
    daily_counts = dict(daily_res.all())
    daily_att = daily_counts.get("ATTENDED", 0)
    daily_abs = daily_counts.get("ABSENT", 0)
    daily_cond = daily_att + daily_abs

    if data.attended >= daily_att and data.conducted >= daily_cond and (data.conducted - data.attended) >= daily_abs:
        needed_att = data.attended - daily_att
        needed_abs = (data.conducted - data.attended) - daily_abs
    else:
        # If daily markings contradict the new total, clear all sessions for this subject and recreate exactly
        all_recs_stmt = select(AttendanceRecord).join(ClassSession).where(
            ClassSession.subject_id == subject_id,
            ClassSession.semester_id == sem.id,
            AttendanceRecord.user_id == user_id,
        )
        all_recs = (await db.execute(all_recs_stmt)).scalars().all()
        if all_recs:
            all_sess_ids = [r.class_session_id for r in all_recs]
            await db.execute(delete(AttendanceRecord).where(AttendanceRecord.id.in_([r.id for r in all_recs])))
            await db.execute(delete(ClassSession).where(ClassSession.id.in_(all_sess_ids)))
        needed_att = data.attended
        needed_abs = data.conducted - data.attended

    for _ in range(needed_att):
        s = ClassSession(
            semester_id=sem.id,
            subject_id=subj.id,
            date=sem.start_date,
            session_status="HELD"
        )
        db.add(s)
        await db.flush()
        db.add(AttendanceRecord(
            class_session_id=s.id,
            user_id=user_id,
            status="ATTENDED",
            source="manual_adjustment"
        ))

    for _ in range(needed_abs):
        s = ClassSession(
            semester_id=sem.id,
            subject_id=subj.id,
            date=sem.start_date,
            session_status="HELD"
        )
        db.add(s)
        await db.flush()
        db.add(AttendanceRecord(
            class_session_id=s.id,
            user_id=user_id,
            status="ABSENT",
            source="manual_adjustment"
        ))

    await db.commit()
    return await get_subject_detail(db, user_id, subject_id)
