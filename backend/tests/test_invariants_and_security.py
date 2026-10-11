import pytest
import uuid
import io
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_75_percent_defaults_and_clean_onboarding():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Register a new user with clean onboarding (seed_demo_data=False)
        email = f"clean_student_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        resp = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "SecurePassword123!",
            "full_name": "Clean Student",
            "seed_demo_data": False
        })
        assert resp.status_code == 201
        data = resp.json()
        token = data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Check profile defaults
        prof_resp = await client.get("/api/v1/profile", headers=headers)
        assert prof_resp.status_code == 200
        prof = prof_resp.json()
        assert prof["minimum_attendance"] == 75.0
        assert prof["personal_target"] == 75.0

        # Check subjects count is 0 (clean onboarding, no fabricated data)
        sub_resp = await client.get("/api/v1/subjects", headers=headers)
        assert sub_resp.status_code == 200
        assert len(sub_resp.json()) == 0

        # Check dashboard reports no attendance data yet
        dash_resp = await client.get("/api/v1/dashboard", headers=headers)
        assert dash_resp.status_code == 200
        dash = dash_resp.json()
        assert dash["overall_percentage"] is None
        assert dash["target_percentage"] == 75.0
        assert dash["minimum_percentage"] == 75.0

@pytest.mark.asyncio
async def test_cross_user_isolation_and_idor_prevention():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Register User A (with demo subjects)
        user_a_email = f"user_a_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        resp_a = await client.post("/api/v1/auth/register", json={
            "email": user_a_email,
            "password": "PasswordUserA123!",
            "full_name": "User Alpha",
            "seed_demo_data": True
        })
        token_a = resp_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # Get User A's subject
        subjects_a = (await client.get("/api/v1/subjects", headers=headers_a)).json()
        assert len(subjects_a) > 0
        target_subject_id = subjects_a[0]["id"]
        target_semester_id = subjects_a[0]["semester_id"]

        # 2. Register User B
        user_b_email = f"user_b_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        resp_b = await client.post("/api/v1/auth/register", json={
            "email": user_b_email,
            "password": "PasswordUserB123!",
            "full_name": "User Beta",
            "seed_demo_data": False
        })
        token_b = resp_b.json()["access_token"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # 3. User B attempts to view User A's subject -> Must be 404
        get_subj = await client.get(f"/api/v1/subjects/{target_subject_id}", headers=headers_b)
        assert get_subj.status_code == 404

        # 4. User B attempts to modify User A's subject -> Must be 404
        patch_subj = await client.patch(
            f"/api/v1/subjects/{target_subject_id}",
            json={"name": "Hacked Subject"},
            headers=headers_b
        )
        assert patch_subj.status_code == 404

        # 5. User B attempts to delete User A's subject -> Must be 404
        del_subj = await client.delete(f"/api/v1/subjects/{target_subject_id}", headers=headers_b)
        assert del_subj.status_code == 404

        # 6. User B attempts to access User A's semester analytics -> Must be 404
        sem_analytics = await client.get(f"/api/v1/analytics/overview?semester_id={target_semester_id}", headers=headers_b)
        assert sem_analytics.status_code == 404

@pytest.mark.asyncio
async def test_semester_switching_context_isolation():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Register user with clean data
        email = f"sem_switch_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        reg = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "Password123!",
            "full_name": "Semester Switcher",
            "current_semester_number": 5,
            "seed_demo_data": False
        })
        token = reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Create Semester 4
        new_sem_resp = await client.post("/api/v1/semesters", json={
            "semester_number": 4,
            "label": "4th Semester",
            "start_date": "2026-01-05",
            "end_date": "2026-05-30"
        }, headers=headers)
        assert new_sem_resp.status_code == 201
        sem_4_id = new_sem_resp.json()["id"]

        # Switch to Semester 4
        switch_resp = await client.post(f"/api/v1/semesters/{sem_4_id}/activate", headers=headers)
        assert switch_resp.status_code == 200

        # Verify active semester is now Semester 4
        prof = (await client.get("/api/v1/profile", headers=headers)).json()
        assert prof["current_semester_id"] == sem_4_id
        assert prof["current_semester_label"] == "4th Semester"

@pytest.mark.asyncio
async def test_file_upload_security_validation():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        email = f"upload_test_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        reg = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "Password123!",
            "full_name": "Upload Tester"
        })
        token = reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Attempt uploading invalid executable extension (.exe)
        bad_file = ("exploit.exe", b"MZ\x90\x00\x03\x00\x00\x00", "application/octet-stream")
        resp = await client.post(
            "/api/v1/imports/routine/parse",
            files={"file": bad_file},
            headers=headers
        )
        assert resp.status_code == 400
        assert "Unsupported file extension" in resp.json()["detail"]

        # 2. Upload valid CSV routine file
        csv_content = b"Mathematics,1,09:00,10:00,Room 101\nSoftware Engineering,2,11:00,12:00,Room 202\n"
        valid_csv = ("routine.csv", csv_content, "text/csv")
        resp_valid = await client.post(
            "/api/v1/imports/routine/parse",
            files={"file": valid_csv},
            headers=headers
        )
        assert resp_valid.status_code == 200
        data = resp_valid.json()
        assert "draft_routine" in data
        assert len(data["draft_routine"]) >= 2

        # 3. Honest PDF pipeline (no fabricated OCR data)
        valid_pdf = ("routine.pdf", b"%PDF-1.4 raw binary without OCR text", "application/pdf")
        resp_pdf = await client.post(
            "/api/v1/imports/routine/parse",
            files={"file": valid_pdf},
            headers=headers
        )
        assert resp_pdf.status_code == 200
        assert "draft_routine" in resp_pdf.json()

@pytest.mark.asyncio
async def test_academic_setup_wizard_lifecycle_and_completeness():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        email = f"wizard_student_{uuid.uuid4().hex[:6]}@univ.edu"
        reg = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "Password123!",
            "full_name": "Wizard Student",
            "seed_demo_data": False
        })
        assert reg.status_code == 201
        token = reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Check initial setup status: incomplete
        status_resp = await client.get("/api/v1/profile/setup-status", headers=headers)
        assert status_resp.status_code == 200
        st = status_resp.json()
        assert st["is_semester_configured"] is False
        assert st["setup_complete"] is False
        assert st["subject_count"] == 0

        # Execute full academic setup
        setup_payload = {
            "university_name": "Apex Technical University",
            "course_name": "B.Tech Computer Science",
            "full_name": "Wizard Student",
            "academic_duration_years": 4,
            "academic_session_start": 2024,
            "academic_session_end": 2028,
            "semester_number": 1,
            "semester_label": "1st Semester",
            "start_date": "2026-08-01",
            "end_date": "2026-12-15",
            "minimum_attendance": 75.0,
            "personal_target": 75.0,
            "subjects": [
                {"name": "Algorithms", "code": "CS-101", "faculty_name": "Dr. Smith"},
                {"name": "Discrete Mathematics", "code": "MA-101", "faculty_name": "Dr. Bose"}
            ],
            "timetable_entries": [
                {"subject_name": "Algorithms", "day_of_week": 0, "start_time": "09:00", "end_time": "10:00", "room": "LH-1"}
            ],
            "holidays": [
                {"title": "Diwali Break", "start_date": "2026-11-04", "end_date": "2026-11-06", "category": "Festival"}
            ],
            "starting_attendance": [
                {"subject_name": "Algorithms", "attended_count": 8, "conducted_count": 10}
            ]
        }
        setup_resp = await client.post("/api/v1/profile/setup", json=setup_payload, headers=headers)
        assert setup_resp.status_code == 200
        prof = setup_resp.json()
        assert prof["university_name"] == "Apex Technical University"
        assert prof["course_name"] == "B.Tech Computer Science"

        # Check updated setup status: now complete
        status_resp2 = await client.get("/api/v1/profile/setup-status", headers=headers)
        assert status_resp2.status_code == 200
        st2 = status_resp2.json()
        assert st2["setup_complete"] is True
        assert st2["is_semester_configured"] is True
        assert st2["subject_count"] == 2

        # Verify subjects
        subs_resp = await client.get("/api/v1/subjects", headers=headers)
        assert subs_resp.status_code == 200
        sub_list = subs_resp.json()
        assert len(sub_list) == 2
        names = [s["name"] for s in sub_list]
        assert "Algorithms" in names
        assert "Discrete Mathematics" in names

        # Verify attendance calculated from starting baseline
        dash_resp = await client.get("/api/v1/dashboard", headers=headers)
        assert dash_resp.status_code == 200
        dash = dash_resp.json()
        assert dash["overall_percentage"] == 80.0
        assert dash["total_attended"] == 8
        assert dash["total_conducted"] == 10

@pytest.mark.asyncio
async def test_attendance_edit_window_and_readonly_get():
    from datetime import date, timedelta
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Register user with clean onboarding
        email = f"window_test_{uuid.uuid4().hex[:6]}@adtu.edu.in"
        resp = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "SecurePassword123!",
            "full_name": "Window Student",
            "seed_demo_data": False
        })
        assert resp.status_code == 201
        headers = {"Authorization": f"Bearer {resp.json()['access_token']}"}

        # Setup 1 subject and 1 timetable entry for Monday
        sub_resp = await client.post("/api/v1/subjects", json={
            "name": "Network Security",
            "code": "CS-401"
        }, headers=headers)
        assert sub_resp.status_code == 201
        sub_id = sub_resp.json()["id"]

        tt_resp = await client.post("/api/v1/timetable", json={
            "subject_id": sub_id,
            "day_of_week": date.today().weekday(),
            "start_time": "10:00",
            "end_time": "11:00"
        }, headers=headers)
        assert tt_resp.status_code == 201
        tt_id = tt_resp.json()["id"]

        # 1. Verify GET /api/v1/attendance/day is read-only
        today_str = date.today().isoformat()
        day_resp = await client.get(f"/api/v1/attendance/day?date={today_str}", headers=headers)
        assert day_resp.status_code == 200
        day_data = day_resp.json()
        assert len(day_data["sessions"]) == 1
        assert day_data["sessions"][0]["id"].startswith("virtual:")

        # 2. Verify future date bulk save is rejected (400)
        future_date = (date.today() + timedelta(days=2)).isoformat()
        future_resp = await client.post("/api/v1/attendance/bulk", json={
            "date": future_date,
            "items": [{"timetable_entry_id": tt_id, "subject_id": sub_id, "status": "ATTENDED"}]
        }, headers=headers)
        assert future_resp.status_code == 400
        assert "future" in future_resp.json()["detail"].lower()

        # 3. Verify expired date (> 2 days ago) bulk save is rejected (400)
        expired_date = (date.today() - timedelta(days=5)).isoformat()
        expired_resp = await client.post("/api/v1/attendance/bulk", json={
            "date": expired_date,
            "items": [{"timetable_entry_id": tt_id, "subject_id": sub_id, "status": "ATTENDED"}]
        }, headers=headers)
        assert expired_resp.status_code == 400
        assert "closed" in expired_resp.json()["detail"].lower() or "window" in expired_resp.json()["detail"].lower()

        # 4. Verify today's date bulk save succeeds (200)
        save_resp = await client.post("/api/v1/attendance/bulk", json={
            "date": today_str,
            "items": [{"timetable_entry_id": tt_id, "subject_id": sub_id, "status": "ATTENDED"}]
        }, headers=headers)
        assert save_resp.status_code == 200
        save_data = save_resp.json()
        assert save_data["updated_count"] == 1

        # 5. Verify weekly-status reflects the attendance record
        weekly_resp = await client.get("/api/v1/timetable/weekly-status?week_offset=0", headers=headers)
        assert weekly_resp.status_code == 200
        weekly_data = weekly_resp.json()
        assert len(weekly_data["days"]) == 7
        today_day = next(d for d in weekly_data["days"] if d["is_today"])
        assert len(today_day["slots"]) == 1
        assert today_day["slots"][0]["is_attended"] is True
        assert today_day["slots"][0]["attendance_status"] == "ATTENDED"

