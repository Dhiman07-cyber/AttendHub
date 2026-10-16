import pytest
import uuid
from datetime import date, timedelta
from httpx import AsyncClient, ASGITransport
from app.main import app
from tests.conftest import TestAsyncSessionLocal as async_session_factory
from app.models.user import User
from app.models.semester import Semester
from app.models.subject import Subject
from app.models.session import ClassSession
from app.models.attendance import AttendanceRecord
from app.services.analytics_service import _fetch_subject_attendance_counts, get_analytics_overview
from app.services.dashboard_service import get_dashboard_overview
from app.services.calendar_service import get_calendar_month

@pytest.mark.asyncio
async def test_postgres_grouping_with_null_and_explicit_class_types():
    """
    Regression test for PostgreSQL asyncpg error:
    column "class_sessions.class_type" must appear in the GROUP BY clause or be used in an aggregate function.
    Verifies that grouping by raw ClassSession.class_type handles both None and explicit types cleanly.
    """
    async with async_session_factory() as db:
        user_id = f"test_grp_{uuid.uuid4().hex[:8]}"
        user = User(
            id=user_id,
            email=f"{user_id}@example.com",
            hashed_password="fakehash",
            full_name="Grouping Test User"
        )
        db.add(user)

        sem = Semester(
            id=f"sem_{uuid.uuid4().hex[:8]}",
            user_id=user_id,
            semester_number=1,
            label="1st Semester",
            start_date=date(2026, 8, 1),
            end_date=date(2026, 12, 20),
            status="ACTIVE",
            is_active=True,
            total_weeks=16
        )
        db.add(sem)

        subj = Subject(
            id=f"sub_{uuid.uuid4().hex[:8]}",
            semester_id=sem.id,
            name="Computer Networks",
            code="CS301",
            color="#FF5722",
            icon="network",
            is_active=True
        )
        db.add(subj)
        await db.flush()

        # Session 1: class_type = None (legacy / default)
        s1 = ClassSession(
            semester_id=sem.id,
            subject_id=subj.id,
            date=date(2026, 10, 1),
            class_type=None,
            session_status="HELD"
        )
        db.add(s1)
        await db.flush()
        db.add(AttendanceRecord(class_session_id=s1.id, user_id=user_id, status="ATTENDED"))

        # Session 2: class_type = 'UNSPECIFIED'
        s2 = ClassSession(
            semester_id=sem.id,
            subject_id=subj.id,
            date=date(2026, 10, 2),
            class_type="UNSPECIFIED",
            session_status="HELD"
        )
        db.add(s2)
        await db.flush()
        db.add(AttendanceRecord(class_session_id=s2.id, user_id=user_id, status="ATTENDED"))

        # Session 3: class_type = 'THEORY'
        s3 = ClassSession(
            semester_id=sem.id,
            subject_id=subj.id,
            date=date(2026, 10, 3),
            class_type="THEORY",
            session_status="HELD"
        )
        db.add(s3)
        await db.flush()
        db.add(AttendanceRecord(class_session_id=s3.id, user_id=user_id, status="ABSENT"))

        # Session 4: class_type = 'LAB'
        s4 = ClassSession(
            semester_id=sem.id,
            subject_id=subj.id,
            date=date(2026, 10, 4),
            class_type="LAB",
            session_status="HELD"
        )
        db.add(s4)
        await db.flush()
        db.add(AttendanceRecord(class_session_id=s4.id, user_id=user_id, status="ATTENDED"))

        await db.commit()

        # Test _fetch_subject_attendance_counts directly
        counts = await _fetch_subject_attendance_counts(db, user_id, sem.id)
        assert subj.id in counts
        c = counts[subj.id]

        assert c["attended"] == 3  # 1 from None + 1 from UNSPECIFIED + 1 from LAB
        assert c["absent"] == 1    # 1 from THEORY
        assert c["unspecified_attended"] == 2  # None and UNSPECIFIED merged!
        assert c["theory_absent"] == 1
        assert c["lab_attended"] == 1

        # Test analytics overview service
        analytics = await get_analytics_overview(db, user_id, sem.id)
        assert analytics.total_attended == 3
        assert analytics.total_absent == 1
        assert analytics.total_conducted == 4

        # Test dashboard overview service
        dashboard = await get_dashboard_overview(db, user_id)
        assert dashboard.total_attended == 3
        assert dashboard.total_conducted == 4

        # Test calendar month service
        cal = await get_calendar_month(db, user_id, 2026, 10, date(2026, 10, 15))
        assert cal.year == 2026
        assert cal.month == 10
        assert len(cal.days) == 31
