from datetime import date, timedelta
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from fastapi import HTTPException, status

from app.models.user import User
from app.models.profile import AcademicProfile
from app.models.semester import Semester
from app.schemas.profile import (
    AcademicProfileOut, AcademicProfileUpdate,
    SetupSemesterInfo, FullAcademicSetupDataOut,
    SetupSubjectDraft, SetupTimetableDraft,
    SetupHolidayDraft, SetupStartingAttendanceDraft
)
from app.schemas.semester import SemesterCreate, SemesterUpdate, SemesterOut

async def get_user_profile(db: AsyncSession, user_id: str) -> AcademicProfileOut:
    stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()
    
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")
        
    user_stmt = select(User).where(User.id == user_id)
    user_res = await db.execute(user_stmt)
    user = user_res.scalar_one()

    # Get active semester label
    sem_label = None
    if profile.current_semester_id:
        sem_stmt = select(Semester).where(Semester.id == profile.current_semester_id)
        sem_res = await db.execute(sem_stmt)
        sem = sem_res.scalar_one_or_none()
        if sem:
            sem_label = sem.label

    return AcademicProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        full_name=user.full_name,
        email=user.email,
        university_name=profile.university_name,
        course_name=profile.course_name,
        student_id_number=profile.student_id_number,
        academic_duration_years=profile.academic_duration_years,
        academic_session_start=profile.academic_session_start,
        academic_session_end=profile.academic_session_end,
        current_semester_id=profile.current_semester_id,
        current_semester_label=sem_label,
        minimum_attendance=profile.minimum_attendance,
        personal_target=profile.personal_target,
        low_attendance_alert=profile.low_attendance_alert
    )

async def update_user_profile(db: AsyncSession, user_id: str, data: AcademicProfileUpdate) -> AcademicProfileOut:
    stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")

    if data.full_name is not None:
        user_stmt = select(User).where(User.id == user_id)
        u_res = await db.execute(user_stmt)
        user = u_res.scalar_one()
        user.full_name = data.full_name.strip()
        user.avatar_initial = "".join([p[0].upper() for p in user.full_name.split()[:2]]) or "A"

    for field, val in data.model_dump(exclude_unset=True).items():
        if field != "full_name" and hasattr(profile, field):
            setattr(profile, field, val)

    await db.commit()
    await db.refresh(profile)
    return await get_user_profile(db, user_id)

def _compute_semester_stats(sem: Semester) -> SemesterOut:
    today = date.today()
    total_days = max(1, (sem.end_date - sem.start_date).days)
    elapsed_days = max(0, min(total_days, (today - sem.start_date).days))
    
    current_week = min(sem.total_weeks, max(1, (elapsed_days // 7) + 1))
    weeks_remaining = max(0, sem.total_weeks - current_week)
    progress_pct = round(min(100.0, (elapsed_days / total_days) * 100.0), 1)

    return SemesterOut(
        id=sem.id,
        user_id=sem.user_id,
        semester_number=sem.semester_number,
        label=sem.label,
        start_date=sem.start_date,
        end_date=sem.end_date,
        status=sem.status,
        is_active=sem.is_active,
        total_weeks=sem.total_weeks,
        current_week=current_week,
        weeks_remaining=weeks_remaining,
        progress_percentage=progress_pct
    )

async def list_semesters(db: AsyncSession, user_id: str) -> List[SemesterOut]:
    stmt = select(Semester).where(Semester.user_id == user_id).order_by(Semester.semester_number.asc())
    result = await db.execute(stmt)
    semesters = result.scalars().all()
    return [_compute_semester_stats(s) for s in semesters]

async def get_active_semester(db: AsyncSession, user_id: str) -> Semester:
    stmt = select(Semester).where(Semester.user_id == user_id, Semester.is_active == True)
    result = await db.execute(stmt)
    semester = result.scalar_one_or_none()
    if not semester:
        # Fallback to the latest semester
        stmt2 = select(Semester).where(Semester.user_id == user_id).order_by(Semester.semester_number.desc())
        res2 = await db.execute(stmt2)
        semester = res2.scalar_one_or_none()
    if not semester:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No active semester configured.")
    return semester

async def switch_semester(db: AsyncSession, user_id: str, target_semester_id: str) -> SemesterOut:
    stmt = select(Semester).where(Semester.id == target_semester_id, Semester.user_id == user_id)
    result = await db.execute(stmt)
    target = result.scalar_one_or_none()
    if not target:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Target semester not found.")

    # Deactivate all other semesters for this user
    await db.execute(
        update(Semester).where(Semester.user_id == user_id).values(is_active=False)
    )
    # Activate target
    target.is_active = True
    
    # Update profile current_semester_id
    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    prof_res = await db.execute(prof_stmt)
    prof = prof_res.scalar_one_or_none()
    if prof:
        prof.current_semester_id = target.id

    await db.commit()
    await db.refresh(target)
    return _compute_semester_stats(target)

from app.models.subject import Subject
from app.models.timetable import TimetableEntry
from app.models.holiday import Holiday
from app.models.session import ClassSession
from app.models.attendance import AttendanceRecord
from app.schemas.profile import (
    AcademicProfileOut, AcademicProfileUpdate,
    SetupStatusOut, FullAcademicSetupRequest
)
from app.schemas.semester import SemesterCreate, SemesterUpdate, SemesterOut

async def create_semester(db: AsyncSession, user_id: str, data: SemesterCreate) -> SemesterOut:
    sem = Semester(
        user_id=user_id,
        semester_number=data.semester_number,
        label=data.label,
        start_date=data.start_date,
        end_date=data.end_date,
        status=data.status or "ACTIVE",
        is_active=False,
        total_weeks=data.total_weeks or 16
    )
    db.add(sem)
    await db.commit()
    await db.refresh(sem)
    return _compute_semester_stats(sem)

async def get_setup_status(db: AsyncSession, user_id: str) -> SetupStatusOut:
    stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    res = await db.execute(stmt)
    prof = res.scalar_one_or_none()
    if not prof:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")
        
    sem_stmt = select(Semester).where(Semester.user_id == user_id, Semester.is_active == True)
    sem_res = await db.execute(sem_stmt)
    active_sem = sem_res.scalar_one_or_none()
    
    subject_count = 0
    if active_sem:
        sub_stmt = select(Subject).where(Subject.semester_id == active_sem.id, Subject.is_active == True)
        sub_res = await db.execute(sub_stmt)
        subjects = sub_res.scalars().all()
        subject_count = len(subjects)
        
    is_profile_complete = bool(prof.university_name and prof.course_name and prof.university_name.strip() and prof.course_name.strip())
    has_active_semester = active_sem is not None
    is_sem_configured = subject_count > 0
    setup_complete = is_profile_complete and has_active_semester and is_sem_configured
    
    return SetupStatusOut(
        is_profile_complete=is_profile_complete,
        has_active_semester=has_active_semester,
        is_semester_configured=is_sem_configured,
        setup_complete=setup_complete,
        current_semester_id=active_sem.id if active_sem else None,
        current_semester_label=active_sem.label if active_sem else None,
        subject_count=subject_count
    )

async def execute_academic_setup(db: AsyncSession, user_id: str, request: FullAcademicSetupRequest) -> AcademicProfileOut:
    if request.full_name:
        user_stmt = select(User).where(User.id == user_id)
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one()
        user.full_name = request.full_name.strip()
        user.avatar_initial = "".join([p[0].upper() for p in user.full_name.split()[:2]]) or "A"
        
    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    prof_res = await db.execute(prof_stmt)
    profile = prof_res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")
        
    profile.university_name = request.university_name.strip()
    profile.course_name = request.course_name.strip()
    if request.student_id_number is not None:
        profile.student_id_number = request.student_id_number.strip()
    profile.academic_duration_years = request.academic_duration_years
    if request.academic_session_start is not None:
        profile.academic_session_start = request.academic_session_start
    if request.academic_session_end is not None:
        profile.academic_session_end = request.academic_session_end
    profile.minimum_attendance = request.minimum_attendance
    profile.personal_target = request.personal_target
    profile.low_attendance_alert = request.low_attendance_alert

    # Target Semester
    target_sem: Optional[Semester] = None
    if request.semester_id:
        sem_stmt = select(Semester).where(Semester.id == request.semester_id, Semester.user_id == user_id)
        s_res = await db.execute(sem_stmt)
        target_sem = s_res.scalar_one_or_none()
        if not target_sem:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Target semester not found.")
        target_sem.label = request.semester_label
        target_sem.semester_number = request.semester_number
        target_sem.start_date = request.start_date
        target_sem.end_date = request.end_date
    else:
        exist_stmt = select(Semester).where(Semester.user_id == user_id, Semester.semester_number == request.semester_number)
        exist_res = await db.execute(exist_stmt)
        target_sem = exist_res.scalar_one_or_none()
        if target_sem:
            target_sem.label = request.semester_label
            target_sem.start_date = request.start_date
            target_sem.end_date = request.end_date
        else:
            target_sem = Semester(
                user_id=user_id,
                semester_number=request.semester_number,
                label=request.semester_label,
                start_date=request.start_date,
                end_date=request.end_date,
                status="ACTIVE",
                is_active=True,
                total_weeks=16
            )
            db.add(target_sem)
            await db.flush()

    await db.execute(
        update(Semester).where(Semester.user_id == user_id).values(is_active=False)
    )
    target_sem.is_active = True
    profile.current_semester_id = target_sem.id

    # Subjects
    created_subjects_map = {}
    for sub_draft in request.subjects:
        subj_stmt = select(Subject).where(Subject.semester_id == target_sem.id, Subject.name == sub_draft.name.strip())
        subj_res = await db.execute(subj_stmt)
        existing_sub = subj_res.scalar_one_or_none()
        if existing_sub:
            existing_sub.code = sub_draft.code
            existing_sub.faculty_name = sub_draft.faculty_name
            existing_sub.color = sub_draft.color or existing_sub.color
            existing_sub.is_active = True
            created_subjects_map[existing_sub.name.lower()] = existing_sub
        else:
            new_sub = Subject(
                semester_id=target_sem.id,
                name=sub_draft.name.strip(),
                code=sub_draft.code,
                faculty_name=sub_draft.faculty_name,
                color=sub_draft.color or "#C96E5B",
                icon="book",
                is_active=True
            )
            db.add(new_sub)
            await db.flush()
            created_subjects_map[new_sub.name.lower()] = new_sub

    # Timetable entries (clean up prior entries for this semester to prevent duplication)
    await db.execute(
        delete(TimetableEntry).where(TimetableEntry.semester_id == target_sem.id)
    )
    for tt_draft in request.timetable_entries:
        sub_obj = created_subjects_map.get(tt_draft.subject_name.strip().lower())
        if sub_obj:
            tt_entry = TimetableEntry(
                semester_id=target_sem.id,
                subject_id=sub_obj.id,
                day_of_week=tt_draft.day_of_week,
                start_time=tt_draft.start_time,
                end_time=tt_draft.end_time,
                room=tt_draft.room,
                faculty_name=tt_draft.faculty_name or sub_obj.faculty_name
            )
            db.add(tt_entry)

    # Holidays (clean up prior manual holidays for this semester to prevent duplication)
    await db.execute(
        delete(Holiday).where(Holiday.semester_id == target_sem.id, Holiday.user_id == user_id)
    )
    allowed_categories = {"University Holiday", "Festival", "Semester Break", "Exam Break", "Academic", "Other"}
    for hol_draft in request.holidays:
        category = hol_draft.category.strip() if hol_draft.category else "University Holiday"
        if category not in allowed_categories:
            if "break" in category.lower():
                category = "Exam Break" if "exam" in category.lower() else "Semester Break"
            elif "fest" in category.lower():
                category = "Festival"
            elif "acad" in category.lower():
                category = "Academic"
            else:
                category = "University Holiday"

        hol = Holiday(
            user_id=user_id,
            semester_id=target_sem.id,
            title=hol_draft.title.strip(),
            start_date=hol_draft.start_date,
            end_date=hol_draft.end_date,
            category=category,
            notes=hol_draft.notes,
            source="manual"
        )
        db.add(hol)

    # Starting attendance
    for start_att in request.starting_attendance:
        sub_obj = created_subjects_map.get(start_att.subject_name.strip().lower())
        if sub_obj and start_att.conducted_count > 0:
            att_count = min(start_att.attended_count, start_att.conducted_count)
            abs_count = max(0, start_att.conducted_count - att_count)
            
            for _ in range(att_count):
                s_att = ClassSession(
                    semester_id=target_sem.id,
                    subject_id=sub_obj.id,
                    date=request.start_date,
                    session_status="HELD"
                )
                db.add(s_att)
                await db.flush()
                rec_att = AttendanceRecord(
                    class_session_id=s_att.id,
                    user_id=user_id,
                    status="ATTENDED",
                    source="initial_setup"
                )
                db.add(rec_att)
                
            for _ in range(abs_count):
                s_abs = ClassSession(
                    semester_id=target_sem.id,
                    subject_id=sub_obj.id,
                    date=request.start_date,
                    session_status="HELD"
                )
                db.add(s_abs)
                await db.flush()
                rec_abs = AttendanceRecord(
                    class_session_id=s_abs.id,
                    user_id=user_id,
                    status="ABSENT",
                    source="initial_setup"
                )
                db.add(rec_abs)

    await db.commit()
    await db.refresh(profile)
    return await get_user_profile(db, user_id)

async def get_academic_setup_data(
    db: AsyncSession,
    user_id: str,
    requested_semester_number: Optional[int] = None
) -> FullAcademicSetupDataOut:
    user_stmt = select(User).where(User.id == user_id)
    u_res = await db.execute(user_stmt)
    user = u_res.scalar_one_or_none()

    prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user_id)
    p_res = await db.execute(prof_stmt)
    profile = p_res.scalar_one_or_none()

    # Query all user semesters
    sem_stmt = select(Semester).where(Semester.user_id == user_id).order_by(Semester.semester_number.asc())
    s_res = await db.execute(sem_stmt)
    semesters = s_res.scalars().all()
    available_nums = [s.semester_number for s in semesters]

    target_sem: Optional[Semester] = None
    if requested_semester_number is not None:
        target_sem = next((s for s in semesters if s.semester_number == requested_semester_number), None)
    else:
        target_sem = next((s for s in semesters if s.is_active), None)
        if not target_sem and semesters:
            target_sem = semesters[-1]

    today = date.today()
    default_start = today - timedelta(days=60)
    default_end = today + timedelta(days=60)

    if target_sem:
        # Load subjects for target_sem
        sub_stmt = select(Subject).where(Subject.semester_id == target_sem.id, Subject.is_active == True)
        sub_res = await db.execute(sub_stmt)
        subjects = sub_res.scalars().all()
        subj_drafts = [
            SetupSubjectDraft(
                name=s.name,
                code=s.code,
                faculty_name=s.faculty_name,
                color=s.color or "#C96E5B"
            ) for s in subjects
        ]
        subj_id_map = {s.id: s.name for s in subjects}

        # Load timetable entries
        tt_stmt = select(TimetableEntry).where(TimetableEntry.semester_id == target_sem.id)
        tt_res = await db.execute(tt_stmt)
        tt_entries = tt_res.scalars().all()
        tt_drafts = [
            SetupTimetableDraft(
                subject_name=subj_id_map.get(t.subject_id, "Subject"),
                day_of_week=t.day_of_week,
                start_time=t.start_time,
                end_time=t.end_time,
                room=t.room,
                faculty_name=t.faculty_name
            ) for t in tt_entries if t.subject_id in subj_id_map
        ]

        # Load holidays
        hol_stmt = select(Holiday).where(Holiday.semester_id == target_sem.id, Holiday.user_id == user_id)
        hol_res = await db.execute(hol_stmt)
        hols = hol_res.scalars().all()
        hol_drafts = [
            SetupHolidayDraft(
                title=h.title,
                start_date=h.start_date,
                end_date=h.end_date,
                category=h.category,
                notes=h.notes
            ) for h in hols
        ]

        # Load starting attendance if any
        start_att_drafts = []
        for s in subjects:
            att_stmt = select(AttendanceRecord.status, func.count()).join(ClassSession).where(
                ClassSession.subject_id == s.id,
                AttendanceRecord.user_id == user_id,
                AttendanceRecord.source == "initial_setup"
            ).group_by(AttendanceRecord.status)
            att_res = await db.execute(att_stmt)
            counts = dict(att_res.all())
            att_c = counts.get("ATTENDED", 0)
            abs_c = counts.get("ABSENT", 0)
            cond_c = att_c + abs_c
            if cond_c > 0:
                start_att_drafts.append(
                    SetupStartingAttendanceDraft(
                        subject_name=s.name,
                        attended_count=att_c,
                        conducted_count=cond_c
                    )
                )

        sem_info = SetupSemesterInfo(
            semester_id=target_sem.id,
            semester_number=target_sem.semester_number,
            semester_label=target_sem.label,
            start_date=target_sem.start_date,
            end_date=target_sem.end_date,
            is_existing=True,
            is_active=target_sem.is_active
        )
    else:
        req_num = requested_semester_number or 1
        sem_info = SetupSemesterInfo(
            semester_id=None,
            semester_number=req_num,
            semester_label=f"{req_num}th Semester" if req_num not in [1, 2, 3] else (
                "1st Semester" if req_num == 1 else ("2nd Semester" if req_num == 2 else "3rd Semester")
            ),
            start_date=default_start,
            end_date=default_end,
            is_existing=False,
            is_active=False
        )
        subj_drafts = []
        tt_drafts = []
        hol_drafts = []
        start_att_drafts = []

    return FullAcademicSetupDataOut(
        full_name=user.full_name if user else None,
        university_name=profile.university_name if profile else "Apex Technical University",
        course_name=profile.course_name if profile else "B.Tech Computer Science",
        student_id_number=profile.student_id_number if profile else None,
        academic_duration_years=profile.academic_duration_years if profile else 4,
        academic_session_start=profile.academic_session_start if profile else 2024,
        academic_session_end=profile.academic_session_end if profile else 2028,
        minimum_attendance=profile.minimum_attendance if profile else 75.0,
        personal_target=profile.personal_target if profile else 75.0,
        low_attendance_alert=profile.low_attendance_alert if profile else 70.0,
        semester=sem_info,
        subjects=subj_drafts,
        timetable_entries=tt_drafts,
        holidays=hol_drafts,
        starting_attendance=start_att_drafts,
        available_semester_numbers=available_nums
    )


