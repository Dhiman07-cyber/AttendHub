import asyncio
from sqlalchemy import text
from app.db.session import AsyncSessionLocal

async def main():
    async with AsyncSessionLocal() as session:
        print("Starting Supabase database cleanup...")
        

        # 2. Delete test users (CASCADE will delete their profiles, semesters, subjects, timetable, holidays, sessions, attendance)
        del_users_res = await session.execute(text("DELETE FROM public.users WHERE email != 'dhiman@adtu.edu.in';"))
        print(f"Deleted {del_users_res.rowcount} test users and all their cascaded records.")

        # 3. Clean mock records for dhiman@adtu.edu.in
        sem_res = await session.execute(text("SELECT id FROM public.semesters WHERE user_id = (SELECT id FROM public.users WHERE email = 'dhiman@adtu.edu.in');"))
        sem_ids = [r[0] for r in sem_res.fetchall()]
        if sem_ids:
            sem_ids_str = ", ".join(f"'{sid}'" for sid in sem_ids)
            await session.execute(text(f"DELETE FROM public.attendance_records WHERE class_session_id IN (SELECT id FROM public.class_sessions WHERE semester_id IN ({sem_ids_str}));"))
            await session.execute(text(f"DELETE FROM public.class_sessions WHERE semester_id IN ({sem_ids_str});"))
            await session.execute(text(f"DELETE FROM public.timetable_entries WHERE semester_id IN ({sem_ids_str});"))
            await session.execute(text(f"DELETE FROM public.subjects WHERE semester_id IN ({sem_ids_str});"))
            await session.execute(text(f"DELETE FROM public.holidays WHERE semester_id IN ({sem_ids_str});"))
            print("Cleaned mock semester data for dhiman@adtu.edu.in.")

        await session.commit()
        print("Database transaction committed.")

        # 4. Check final row counts
        tables = [
            "users", "academic_profiles", "semesters", "subjects",
            "timetable_entries", "class_sessions", "holidays", "attendance_records"
        ]
        print("\n--- Final Supabase Table Counts ---")
        for tbl in tables:
            cnt_res = await session.execute(text(f"SELECT COUNT(*) FROM public.{tbl};"))
            cnt = cnt_res.scalar()
            print(f"public.{tbl}: {cnt} rows")

if __name__ == "__main__":
    asyncio.run(main())
