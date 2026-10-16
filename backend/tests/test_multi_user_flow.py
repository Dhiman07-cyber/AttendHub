import pytest
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_user1_setup_then_user2_login():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Register User 1
        u1_email = f"user1_{uuid.uuid4().hex[:6]}@example.com"
        reg1 = await client.post("/api/v1/auth/register", json={
            "email": u1_email,
            "password": "Password123!",
            "full_name": "User One",
            "current_semester_number": 1,
            "seed_demo_data": False
        })
        assert reg1.status_code == 201
        token1 = reg1.json()["access_token"]
        h1 = {"Authorization": f"Bearer {token1}"}

        # User 1 completes academic setup
        setup_payload = {
            "full_name": "User One",
            "university_name": "Assam down town University",
            "course_name": "B.Tech CSE",
            "student_id_number": "ADTU/2026/001",
            "academic_duration_years": 4,
            "academic_session_start": 2024,
            "academic_session_end": 2028,
            "minimum_attendance": 75.0,
            "personal_target": 80.0,
            "low_attendance_alert": 70.0,
            "semester_number": 1,
            "semester_label": "1st Semester",
            "start_date": "2026-08-01",
            "end_date": "2026-12-20",
            "working_days": [0, 1, 2, 3, 4, 5],
            "subjects": [
                {
                    "name": "Mathematics",
                    "code": "MA101",
                    "faculty_name": "Dr. Euler",
                    "color": "#C96E5B",
                    "target_attendance": 80.0
                }
            ],
            "timetable_entries": [
                {
                    "subject_name": "Mathematics",
                    "day_of_week": 0,
                    "start_time": "09:00",
                    "end_time": "10:00",
                    "room": "101",
                    "faculty_name": "Dr. Euler",
                    "class_type": "THEORY"
                }
            ],
            "holidays": [
                {
                    "title": "Diwali",
                    "start_date": "2026-11-01",
                    "end_date": "2026-11-02",
                    "category": "Festival",
                    "notes": "Festival of lights"
                }
            ],
            "starting_attendance": [
                {
                    "subject_name": "Mathematics",
                    "attended": 10,
                    "conducted": 12
                }
            ]
        }
        setup_resp = await client.post("/api/v1/profile/setup", json=setup_payload, headers=h1)
        assert setup_resp.status_code == 200, f"Setup failed: {setup_resp.status_code} {setup_resp.text}"

        # User 1 logs out
        logout_resp = await client.post("/api/v1/auth/logout", headers=h1)
        assert logout_resp.status_code == 200

        # 2. Now User 2 registers
        u2_email = f"user2_{uuid.uuid4().hex[:6]}@example.com"
        reg2 = await client.post("/api/v1/auth/register", json={
            "email": u2_email,
            "password": "Password123!",
            "full_name": "User Two",
            "current_semester_number": 1,
            "seed_demo_data": False
        })
        assert reg2.status_code == 201, f"User 2 reg failed: {reg2.status_code} {reg2.text}"
        token2 = reg2.json()["access_token"]
        h2 = {"Authorization": f"Bearer {token2}"}

        # Check all endpoints for User 2
        endpoints_to_test = [
            ("GET", "/api/v1/auth/me"),
            ("GET", "/api/v1/profile"),
            ("GET", "/api/v1/profile/setup-status"),
            ("GET", "/api/v1/profile/setup-data"),
            ("GET", "/api/v1/semesters"),
            ("GET", "/api/v1/dashboard"),
            ("GET", "/api/v1/attendance/today"),
            ("GET", "/api/v1/attendance/day?date=2026-10-15"),
            ("GET", "/api/v1/timetable/weekly-status"),
            ("GET", "/api/v1/analytics/overview"),
            ("GET", "/api/v1/holidays"),
            ("GET", "/api/v1/subjects"),
        ]

        for method, url in endpoints_to_test:
            if method == "GET":
                resp = await client.get(url, headers=h2)
                assert resp.status_code == 200, f"Endpoint {url} failed for User 2: {resp.status_code} {resp.text}"
