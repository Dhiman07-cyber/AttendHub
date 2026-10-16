import uuid
from datetime import datetime, date, timedelta, timezone
from typing import Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
import logging

from app.models.user import User
from app.models.profile import AcademicProfile
from app.models.semester import Semester
from app.models.subject import Subject
from app.models.timetable import TimetableEntry
from app.models.session import ClassSession
from app.models.attendance import AttendanceRecord
from app.models.holiday import Holiday
import httpx
from app.core.config import settings
from app.core.security import (
    get_password_hash, verify_password,
    create_access_token, create_refresh_token,
    decode_refresh_token
)
from app.schemas.auth import UserRegister, UserLogin, Token, GoogleAuthRequest

async def register_user(db: AsyncSession, data: UserRegister) -> Tuple[User, Token]:
    # Check existing user
    stmt = select(User).where(User.email == data.email.lower().strip())
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email address already exists."
        )

    # 1. Create User
    initials = "".join([part[0].upper() for part in data.full_name.split()[:2]]) or "A"
    user = User(
        email=data.email.lower().strip(),
        hashed_password=get_password_hash(data.password),
        full_name=data.full_name.strip(),
        avatar_initial=initials,
        is_active=True
    )
    db.add(user)
    await db.flush()

    # 2. Create Active Semester (e.g. 5th Semester Aug 2026 - Dec 2026)
    today = date(2026, 10, 8) # Reference semester date
    target_today = today
    sem_start = date(2026, 8, 1)
    sem_end = date(2026, 12, 20)
    sem_num = data.current_semester_number or 5
    semester = Semester(
        user_id=user.id,
        semester_number=sem_num,
        label=f"{sem_num}th Semester" if sem_num in [4, 5, 6, 7, 8] else f"{sem_num}st Semester" if sem_num == 1 else f"{sem_num}nd Semester" if sem_num == 2 else f"{sem_num}rd Semester",
        start_date=sem_start,
        end_date=sem_end,
        status="ACTIVE",
        is_active=True,
        total_weeks=16
    )
    db.add(semester)
    await db.flush()

    min_att = data.minimum_attendance if data.minimum_attendance is not None else 75.0
    pers_target = data.personal_target if data.personal_target is not None else 75.0
    profile = AcademicProfile(
        user_id=user.id,
        university_name=data.university_name or ("Assam down town University" if data.seed_demo_data else ""),
        course_name=data.course_name or ("B.Tech Computer Science & Engineering" if data.seed_demo_data else ""),
        student_id_number=(f"ADTU/0/2024-28/BCSM/{str(uuid.uuid4().int)[:3]}" if data.seed_demo_data else None),
        academic_duration_years=4,
        academic_session_start=2024,
        academic_session_end=2028,
        current_semester_id=semester.id,
        minimum_attendance=min_att,
        personal_target=pers_target,
        low_attendance_alert=70.0
    )
    db.add(profile)
    await db.flush()

    if data.seed_demo_data:
        # 4. Seed Standard Curriculum Subjects matching the reference mockups
        subjects_data = [
            {"name": "Software Engineering", "code": "CS-501", "faculty": "Prof. A. Sharma", "color": "#E06D53", "icon": "code", "att": 33, "abs": 7},
            {"name": "Operating Systems", "code": "CS-502", "faculty": "Prof. R. Das", "color": "#D98786", "icon": "settings", "att": 20, "abs": 7},
            {"name": "Mathematics", "code": "MA-501", "faculty": "Prof. K. Deka", "color": "#8F7BAE", "icon": "functions", "att": 15, "abs": 7},
            {"name": "Database Management", "code": "CS-503", "faculty": "Prof. M. Ali", "color": "#72A68A", "icon": "database", "att": 20, "abs": 7},
            {"name": "Computer Networks", "code": "CS-504", "faculty": "Prof. S. Ahmed", "color": "#5A93B5", "icon": "wifi", "att": 24, "abs": 6},
            {"name": "Technical Communication", "code": "HS-501", "faculty": "Prof. N. Barman", "color": "#D9A35B", "icon": "chat", "att": 18, "abs": 3},
        ]

        subject_objects = []
        for s_info in subjects_data:
            subj = Subject(
                semester_id=semester.id,
                name=s_info["name"],
                code=s_info["code"],
                faculty_name=s_info["faculty"],
                color=s_info["color"],
                icon=s_info["icon"],
                is_active=True
            )
            db.add(subj)
            subject_objects.append((subj, s_info))
        await db.flush()

        # 5. Seed Routine / Timetable Entries
        timetable_plan = [
            (subject_objects[0][0], 0, "09:00", "10:00", "Room 101"), # Soft Eng Mon
            (subject_objects[0][0], 2, "09:00", "10:00", "Room 101"), # Soft Eng Wed
            (subject_objects[0][0], 4, "09:00", "10:00", "Room 101"), # Soft Eng Fri
            
            (subject_objects[1][0], 0, "11:00", "12:00", "Room 203"), # OS Mon
            (subject_objects[1][0], 1, "11:00", "12:00", "Room 203"), # OS Tue
            (subject_objects[1][0], 2, "11:00", "12:00", "Room 203"), # OS Wed
            (subject_objects[1][0], 3, "11:00", "12:00", "Room 203"), # OS Thu
            
            (subject_objects[2][0], 1, "14:00", "15:00", "Room 305"), # Math Tue
            (subject_objects[2][0], 2, "14:00", "15:00", "Room 305"), # Math Wed
            (subject_objects[2][0], 3, "14:00", "15:00", "Room 305"), # Math Thu
            
            (subject_objects[3][0], 0, "16:00", "17:00", "Room 104"), # DBMS Mon
            (subject_objects[3][0], 2, "16:00", "17:00", "Room 104"), # DBMS Wed
            
            (subject_objects[4][0], 1, "10:00", "11:00", "Room 205"), # CN Tue
            (subject_objects[4][0], 4, "10:00", "11:00", "Room 205"), # CN Fri
            
            (subject_objects[5][0], 2, "13:00", "14:00", "Room 401"), # Tech Comm Wed
            (subject_objects[5][0], 4, "13:00", "14:00", "Room 401"), # Tech Comm Fri
            (subject_objects[0][0], 5, "10:00", "11:00", "Lab 1"), # Soft Eng Sat
            (subject_objects[1][0], 6, "10:00", "11:00", "Room 203"), # OS Sun
        ]

        for subj, day, start, end, rm in timetable_plan:
            tt = TimetableEntry(
                semester_id=semester.id,
                subject_id=subj.id,
                day_of_week=day,
                start_time=start,
                end_time=end,
                faculty_name=subj.faculty_name,
                room=rm,
                effective_from=sem_start,
                effective_to=sem_end
            )
            db.add(tt)

        # 6. Seed Historical Attendance Records
        for subj, s_info in subject_objects:
            att_needed = s_info["att"]
            abs_needed = s_info["abs"]
            for i in range(att_needed):
                hist_date = sem_start + timedelta(days=(i * 2) % 65)
                sess = ClassSession(
                    semester_id=semester.id,
                    subject_id=subj.id,
                    date=hist_date,
                    start_time="09:00",
                    end_time="10:00",
                    faculty_name=subj.faculty_name,
                    room="Room 101",
                    session_status="HELD"
                )
                db.add(sess)
                await db.flush()
                rec = AttendanceRecord(
                    class_session_id=sess.id,
                    user_id=user.id,
                    status="ATTENDED",
                    source="system_seed"
                )
                db.add(rec)
                
            for j in range(abs_needed):
                hist_date = sem_start + timedelta(days=(j * 3 + 1) % 65)
                sess = ClassSession(
                    semester_id=semester.id,
                    subject_id=subj.id,
                    date=hist_date,
                    start_time="09:00",
                    end_time="10:00",
                    faculty_name=subj.faculty_name,
                    room="Room 101",
                    session_status="HELD"
                )
                db.add(sess)
                await db.flush()
                rec = AttendanceRecord(
                    class_session_id=sess.id,
                    user_id=user.id,
                    status="ABSENT",
                    source="system_seed"
                )
                db.add(rec)

        # 7. Seed Today's Classes for 2026-10-08
        today_schedule = [
            (subject_objects[0][0], "09:00", "10:00", "Prof. A. Sharma", "Room 101", "ATTENDED"),
            (subject_objects[1][0], "11:00", "12:00", "Prof. R. Das", "Room 203", None), # Current / Pending
            (subject_objects[2][0], "14:00", "15:00", "Prof. K. Deka", "Room 305", None), # Upcoming
            (subject_objects[3][0], "16:00", "17:00", "Prof. M. Ali", "Room 104", None), # Upcoming
        ]
        for subj, start, end, faculty, rm, init_status in today_schedule:
            sess = ClassSession(
                semester_id=semester.id,
                subject_id=subj.id,
                date=target_today,
                start_time=start,
                end_time=end,
                faculty_name=faculty,
                room=rm,
                session_status="SCHEDULED"
            )
            db.add(sess)
            await db.flush()
            if init_status:
                rec = AttendanceRecord(
                    class_session_id=sess.id,
                    user_id=user.id,
                    status=init_status,
                    source="system_seed"
                )
                db.add(rec)

        # 8. Seed Holidays
        holidays_data = [
            ("Internal Assessment 2", date(2026, 10, 17), date(2026, 10, 17), "Academic", "Unit tests for semester mid-term"),
            ("Durga Puja", date(2026, 10, 21), date(2026, 10, 25), "Festival", "Autumn festival break"),
            ("Diwali", date(2026, 11, 4), date(2026, 11, 6), "Festival", "Festival of lights"),
            ("Children's Day", date(2026, 11, 14), date(2026, 11, 14), "Other", "Institutional observance"),
            ("Christmas", date(2026, 12, 25), date(2026, 12, 25), "Festival", "Winter holiday"),
            ("Independence Day", date(2026, 8, 15), date(2026, 8, 15), "University Holiday", "National holiday"),
            ("Teachers' Day", date(2026, 9, 5), date(2026, 9, 5), "Other", "Institutional celebration"),
        ]
        for title, s_dt, e_dt, cat, notes in holidays_data:
            hol = Holiday(
                user_id=user.id,
                semester_id=semester.id,
                start_date=s_dt,
                end_date=e_dt,
                title=title,
                category=cat,
                notes=notes,
                source="system_seed"
            )
            db.add(hol)

    await db.commit()
    await db.refresh(user)

    # Generate tokens
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    token = Token(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name
    )
    return user, token

async def authenticate_user(db: AsyncSession, data: UserLogin) -> Tuple[User, Token]:
    stmt = select(User).where(User.email == data.email.lower().strip())
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password."
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated."
        )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    token = Token(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name
    )
    return user, token

async def refresh_user_token(db: AsyncSession, refresh_token: str) -> Token:
    payload = decode_refresh_token(refresh_token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token."
        )
    user_id = payload.get("sub")
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive."
        )

    new_access_token = create_access_token(user.id)
    new_refresh_token = create_refresh_token(user.id)
    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name
    )

logger = logging.getLogger("attendhub.auth")

async def verify_google_token(id_token: Optional[str] = None, access_token: Optional[str] = None) -> dict:
    """Verify Google OAuth id_token or access_token using Google's public tokeninfo service."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            if id_token:
                try:
                    resp = await client.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}")
                    if resp.status_code == 200:
                        data = resp.json()
                        aud = data.get("aud", "")
                        if settings.GOOGLE_CLIENT_ID and aud:
                            project_prefix = settings.GOOGLE_CLIENT_ID.split("-")[0]
                            if aud != settings.GOOGLE_CLIENT_ID and not aud.startswith(project_prefix):
                                raise HTTPException(
                                    status_code=status.HTTP_401_UNAUTHORIZED,
                                    detail="Google token audience does not match configured application."
                                )
                        if not data.get("email"):
                            raise HTTPException(
                                status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Google account did not return an email address."
                            )
                        return data
                    else:
                        logger.warning(f"Google tokeninfo rejected id_token with status {resp.status_code}: {resp.text}")
                except HTTPException:
                    raise
                except httpx.HTTPError as he:
                    logger.warning(f"Network error querying Google tokeninfo: {he}")

            if access_token:
                try:
                    resp = await client.get(
                        "https://www.googleapis.com/oauth2/v3/userinfo",
                        headers={"Authorization": f"Bearer {access_token}"}
                    )
                    if resp.status_code == 200:
                        data = resp.json()
                        if not data.get("email"):
                            raise HTTPException(
                                status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Google account did not return an email address."
                            )
                        return data
                    else:
                        logger.warning(f"Google userinfo rejected access_token with status {resp.status_code}: {resp.text}")
                except HTTPException:
                    raise
                except httpx.HTTPError as he:
                    logger.warning(f"Network error querying Google userinfo: {he}")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in verify_google_token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to verify Google credentials. Please try again."
        )

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired Google authentication credentials."
    )

async def authenticate_google_user(db: AsyncSession, data: GoogleAuthRequest) -> Tuple[User, Token]:
    """Authenticate or register student using Google OAuth credentials."""
    google_data = await verify_google_token(id_token=data.id_token, access_token=data.access_token)
    email = (google_data.get("email") or data.email or "").lower().strip()
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A valid verified email is required from Google."
        )

    full_name = google_data.get("name") or data.full_name or email.split("@")[0].capitalize()

    # Look up existing user
    stmt = select(User).where(User.email == email)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if user:
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is deactivated."
            )
        # Self-heal profile or semester if missing
        prof_stmt = select(AcademicProfile).where(AcademicProfile.user_id == user.id)
        prof = (await db.execute(prof_stmt)).scalar_one_or_none()
        sem_stmt = select(Semester).where(Semester.user_id == user.id, Semester.is_active == True)
        sem = (await db.execute(sem_stmt)).scalar_one_or_none()
        needs_commit = False
        if not sem:
            sem = Semester(
                user_id=user.id,
                semester_number=1,
                label="1st Semester",
                start_date=date(2026, 8, 1),
                end_date=date(2026, 12, 20),
                status="ACTIVE",
                is_active=True,
                total_weeks=16
            )
            db.add(sem)
            await db.flush()
            needs_commit = True
        if not prof:
            prof = AcademicProfile(
                user_id=user.id,
                university_name="",
                course_name="",
                student_id_number=None,
                academic_duration_years=4,
                academic_session_start=2024,
                academic_session_end=2028,
                current_semester_id=sem.id,
                minimum_attendance=75.0,
                personal_target=75.0,
                low_attendance_alert=70.0
            )
            db.add(prof)
            needs_commit = True
        elif not prof.current_semester_id:
            prof.current_semester_id = sem.id
            needs_commit = True

        if needs_commit:
            await db.commit()
            await db.refresh(user)
    else:
        # Register new student user via Google
        initials = "".join([part[0].upper() for part in full_name.split()[:2]]) or "A"
        user = User(
            email=email,
            hashed_password=get_password_hash(uuid.uuid4().hex),
            full_name=full_name.strip()[:100],
            avatar_initial=initials,
            is_active=True
        )
        db.add(user)
        await db.flush()

        # Create active semester with standard 75% invariant
        sem_start = date(2026, 8, 1)
        sem_end = date(2026, 12, 20)
        semester = Semester(
            user_id=user.id,
            semester_number=1,
            label="1st Semester",
            start_date=sem_start,
            end_date=sem_end,
            status="ACTIVE",
            is_active=True,
            total_weeks=16
        )
        db.add(semester)
        await db.flush()

        profile = AcademicProfile(
            user_id=user.id,
            university_name="",
            course_name="",
            student_id_number=None,
            academic_duration_years=4,
            academic_session_start=2024,
            academic_session_end=2028,
            current_semester_id=semester.id,
            minimum_attendance=75.0,
            personal_target=75.0,
            low_attendance_alert=70.0
        )
        db.add(profile)
        await db.flush()

        await db.commit()
        await db.refresh(user)

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    token = Token(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name
    )
    return user, token
