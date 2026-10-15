import pytest
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_fresh_user_all_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Register fresh user
        email = f"fresh_{uuid.uuid4().hex[:6]}@example.com"
        reg_resp = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "Password123!",
            "full_name": "Fresh Student",
            "current_semester_number": 1,
            "seed_demo_data": False
        })
        assert reg_resp.status_code == 201, reg_resp.text
        token_data = reg_resp.json()
        token = token_data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Profile
        p_resp = await client.get("/api/v1/profile", headers=headers)
        assert p_resp.status_code == 200, f"Profile failed: {p_resp.status_code} {p_resp.text}"

        # Semesters
        sem_resp = await client.get("/api/v1/semesters", headers=headers)
        assert sem_resp.status_code == 200, f"Semesters failed: {sem_resp.status_code} {sem_resp.text}"

        # Setup status
        setup_resp = await client.get("/api/v1/profile/setup-status", headers=headers)
        assert setup_resp.status_code == 200, f"Setup status failed: {setup_resp.status_code} {setup_resp.text}"

        # Dashboard
        dash_resp = await client.get("/api/v1/dashboard", headers=headers)
        assert dash_resp.status_code == 200, f"Dashboard failed: {dash_resp.status_code} {dash_resp.text}"

        # Day attendance
        day_resp = await client.get("/api/v1/attendance/day?date=2026-10-15", headers=headers)
        assert day_resp.status_code == 200, f"Day attendance failed: {day_resp.status_code} {day_resp.text}"

        # Timetable weekly status
        tt_resp = await client.get("/api/v1/timetable/weekly-status", headers=headers)
        assert tt_resp.status_code == 200, f"Timetable weekly status failed: {tt_resp.status_code} {tt_resp.text}"

        # Analytics overview
        an_resp = await client.get("/api/v1/analytics/overview", headers=headers)
        assert an_resp.status_code == 200, f"Analytics overview failed: {an_resp.status_code} {an_resp.text}"

        # Holidays
        hol_resp = await client.get("/api/v1/holidays", headers=headers)
        assert hol_resp.status_code == 200, f"Holidays failed: {hol_resp.status_code} {hol_resp.text}"

        # Subjects
        sub_resp = await client.get("/api/v1/subjects", headers=headers)
        assert sub_resp.status_code == 200, f"Subjects failed: {sub_resp.status_code} {sub_resp.text}"
