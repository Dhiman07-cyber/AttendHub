"""Verify production schema state - READ ONLY."""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import settings

async def verify_schema():
    """Read-only schema verification."""
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    
    async with engine.begin() as conn:
        # Check Alembic version
        result = await conn.execute(text("SELECT version_num FROM alembic_version"))
        version = result.scalar()
        print(f"✓ Alembic version: {version}")
        
        # Check working_days column details
        col_check = await conn.execute(text("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name='semesters' AND column_name='working_days'
        """))
        col_info = col_check.fetchone()
        if col_info:
            print(f"✓ working_days column exists:")
            print(f"  - Type: {col_info[1]}")
            print(f"  - Nullable: {col_info[2]}")
            print(f"  - Default: {col_info[3]}")
        else:
            print("✗ working_days column NOT FOUND")
        
        # Check sample working_days values (anonymized)
        sample = await conn.execute(text("""
            SELECT COUNT(*) as total,
                   COUNT(working_days) as with_value,
                   COUNT(*) - COUNT(working_days) as nulls
            FROM semesters
        """))
        stats = sample.fetchone()
        print(f"✓ Semester working_days stats:")
        print(f"  - Total semesters: {stats[0]}")
        print(f"  - With working_days value: {stats[1]}")
        print(f"  - Null working_days: {stats[2]}")
        
        # Sample value (first non-null)
        if stats[1] > 0:
            sample_val = await conn.execute(text("""
                SELECT working_days 
                FROM semesters 
                WHERE working_days IS NOT NULL 
                LIMIT 1
            """))
            val = sample_val.scalar()
            print(f"  - Sample value: {val}")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(verify_schema())
