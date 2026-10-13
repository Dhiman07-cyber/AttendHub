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


@pytest.mark.asyncio
async def test_google_auth_flow(monkeypatch):
    from unittest.mock import AsyncMock
    import app.services.auth_service as auth_service_mod
    
    # Mock verify_google_token so it doesn't need external network to Google servers during CI
    mock_email = f"google_student_{uuid.uuid4().hex[:6]}@gmail.com"
    mock_verify = AsyncMock(return_value={
        "email": mock_email,
        "name": "Google Test Student",
        "sub": "google-user-12345",
        "email_verified": "true",
        "aud": "1234567890-mockclientid.apps.googleusercontent.com"
    })
    monkeypatch.setattr(auth_service_mod, "verify_google_token", mock_verify)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. First sign-in: New student registration via Google
        auth_resp = await client.post("/api/v1/auth/google", json={"id_token": "valid_mock_token"})
        assert auth_resp.status_code == 200
        token_data = auth_resp.json()
        assert token_data["email"] == mock_email
        assert token_data["full_name"] == "Google Test Student"
        assert "access_token" in token_data

        headers = {"Authorization": f"Bearer {token_data['access_token']}"}
        me_resp = await client.get("/api/v1/auth/me", headers=headers)
        assert me_resp.status_code == 200
        assert me_resp.json()["email"] == mock_email

        # Verify profile has invariant 75% defaults
        prof_resp = await client.get("/api/v1/profile", headers=headers)
        assert prof_resp.status_code == 200
        assert prof_resp.json()["minimum_attendance"] == 75.0
        assert prof_resp.json()["personal_target"] == 75.0

        # 2. Second sign-in: Existing student login via Google
        auth_resp_2 = await client.post("/api/v1/auth/google", json={"id_token": "valid_mock_token"})
        assert auth_resp_2.status_code == 200
        token_data_2 = auth_resp_2.json()
        assert token_data_2["user_id"] == token_data["user_id"]
        assert token_data_2["email"] == mock_email

        # 3. Third sign-in: Robustness test where client sends empty string email or whitespace
        auth_resp_3 = await client.post("/api/v1/auth/google", json={
            "id_token": "valid_mock_token",
            "email": "",
            "full_name": ""
        })
        assert auth_resp_3.status_code == 200
        assert auth_resp_3.json()["email"] == mock_email

@pytest.mark.asyncio
async def test_google_verification_and_branding_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Search Console verification HTML file
        v_resp = await client.get("/google1ca5ec019afa568b.html")
        assert v_resp.status_code == 200
        assert "google-site-verification: google1ca5ec019afa568b.html" in v_resp.text

        # 2. Homepage HTML with meta tag and privacy link
        root_resp = await client.get("/")
        assert root_resp.status_code == 200
        assert 'content="google1ca5ec019afa568b"' in root_resp.text
        assert 'href="/privacy"' in root_resp.text

        # 3. Privacy Policy with verification meta tag
        privacy_resp = await client.get("/privacy")
        assert privacy_resp.status_code == 200
        assert 'content="google1ca5ec019afa568b"' in privacy_resp.text

        # 4. Terms with verification meta tag
        terms_resp = await client.get("/terms")
        assert terms_resp.status_code == 200
        assert 'content="google1ca5ec019afa568b"' in terms_resp.text


