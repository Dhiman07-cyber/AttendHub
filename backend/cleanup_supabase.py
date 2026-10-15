import asyncio
from sqlalchemy import text
from app.db.session import AsyncSessionLocal

async def main():
    async with AsyncSessionLocal() as session:
        print("Starting complete Supabase database wipe...")
        
        # Delete from child tables to parent tables cleanly
        await session.execute(text("DELETE FROM public.attendance_records;"))
        await session.execute(text("DELETE FROM public.class_sessions;"))
        await session.execute(text("DELETE FROM public.timetable_entries;"))
        await session.execute(text("DELETE FROM public.holidays;"))
        await session.execute(text("DELETE FROM public.subjects;"))
        await session.execute(text("DELETE FROM public.academic_profiles;"))
        await session.execute(text("DELETE FROM public.semesters;"))
        await session.execute(text("DELETE FROM public.users;"))
        
        await session.commit()
        print("All tables wiped and transaction committed.")

        # Check final row counts
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
