"""Check current database schema."""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import settings

async def check_schema():
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    
    async with engine.begin() as conn:
        # Check if alembic_version table exists
        result = await conn.execute(text(
            "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'alembic_version')"
        ))
        has_alembic = result.scalar()
        
        if has_alembic:
            # Get current migration version
            version_result = await conn.execute(text("SELECT version_num FROM alembic_version"))
            version = version_result.scalar()
            print(f"Current Alembic version: {version}")
        else:
            print("No alembic_version table found - database not yet migrated")
        
        # List all tables
        tables_result = await conn.execute(text(
            "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name"
        ))
        tables = [r[0] for r in tables_result]
        print(f"\nTables in database ({len(tables)}):")
        for table in tables:
            print(f"  - {table}")
        
        # Check if class_type column exists in timetable_entries
        column_check = await conn.execute(text(
            "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name='timetable_entries' AND column_name='class_type')"
        ))
        has_class_type = column_check.scalar()
        print(f"\nclass_type column in timetable_entries: {has_class_type}")
        
        # Check if class_type column exists in class_sessions
        session_column_check = await conn.execute(text(
            "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name='class_sessions' AND column_name='class_type')"
        ))
        has_session_class_type = session_column_check.scalar()
        print(f"class_type column in class_sessions: {has_session_class_type}")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check_schema())
