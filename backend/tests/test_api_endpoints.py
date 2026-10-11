import pytest
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_full_api_flow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Health check
        resp = await client.get("/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "healthy"

        # 2. Register user
        user_email = f"dhiman_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        reg_payload = {
            "email": user_email,
            "password": "Password123!",
            "full_name": "Dhiman Saikia",
            "university_name": "Assam down town University",
            "course_name": "B.Tech Computer Science & Engineering",
            "current_semester_number": 5
        }
        reg_resp = await client.post("/api/v1/auth/register", json=reg_payload)
        assert reg_resp.status_code == 201
        token_data = reg_resp.json()
        assert "access_token" in token_data
        access_token = token_data["access_token"]
        headers = {"Authorization": f"Bearer {access_token}"}

        # 3. Read profile
        prof_resp = await client.get("/api/v1/profile", headers=headers)
        assert prof_resp.status_code == 200
        prof = prof_resp.json()
        assert prof["full_name"] == "Dhiman Saikia"
        assert prof["minimum_attendance"] == 75.0
        assert prof["current_semester_label"] == "5th Semester"

        # 4. List Semesters
        sem_resp = await client.get("/api/v1/semesters", headers=headers)
        assert sem_resp.status_code == 200
        semesters = sem_resp.json()
        assert len(semesters) >= 1
        active_sem = next(s for s in semesters if s["is_active"])
        assert active_sem["semester_number"] == 5

        # 5. List Subjects
        sub_resp = await client.get("/api/v1/subjects", headers=headers)
        assert sub_resp.status_code == 200
        subjects = sub_resp.json()
        assert len(subjects) == 6
        sub_names = [s["name"] for s in subjects]
        assert "Software Engineering" in sub_names
        assert "Mathematics" in sub_names

        # 6. Get Dashboard
        dash_resp = await client.get("/api/v1/dashboard", headers=headers)
        assert dash_resp.status_code == 200
        dash = dash_resp.json()
        assert dash["user_name"] == "Dhiman"
        assert dash["overall_percentage"] is not None
        assert len(dash["today_sessions"]) >= 1

        # 7. Get Today's classes
        today_resp = await client.get("/api/v1/attendance/today", headers=headers)
        assert today_resp.status_code == 200
        today_data = today_resp.json()
        assert len(today_data["sessions"]) >= 1
        first_session = today_data["sessions"][0]

        # 8. Mark attendance for today's classes
        bulk_payload = {
            "items": [
                {"session_id": first_session["id"], "status": "ATTENDED"}
            ]
        }
        mark_resp = await client.post("/api/v1/attendance/bulk", json=bulk_payload, headers=headers)
        assert mark_resp.status_code == 200

        # 9. Get Analytics overview
        analytics_resp = await client.get("/api/v1/analytics/overview", headers=headers)
        assert analytics_resp.status_code == 200
        analytics = analytics_resp.json()
        assert analytics["overall_percentage"] is not None
        assert len(analytics["subjects"]) == 6
        assert len(analytics["insights"]) >= 1

        # 10. Get Calendar
        cal_resp = await client.get("/api/v1/calendar?year=2026&month=10", headers=headers)
        assert cal_resp.status_code == 200
        cal = cal_resp.json()
        assert cal["month_name"] == "October"
        assert len(cal["days"]) == 31

        # 11. Get Holidays
        hol_resp = await client.get("/api/v1/holidays", headers=headers)
        assert hol_resp.status_code == 200
        holidays = hol_resp.json()
        assert len(holidays) >= 5
