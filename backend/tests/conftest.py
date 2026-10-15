import os
from dotenv import load_dotenv
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.db.session import Base, get_db
from app.main import app as fastapi_app
import app.models

load_dotenv()

TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL", "sqlite+aiosqlite:///./test_attendhub.db")

is_sqlite = "sqlite" in TEST_DATABASE_URL

from sqlalchemy.pool import NullPool

if is_sqlite:
    test_engine = create_async_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        echo=False
    )
else:
    test_engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        poolclass=NullPool
    )

TestAsyncSessionLocal = async_sessionmaker(
    bind=test_engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=AsyncSession
)

async def override_get_db():
    async with TestAsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

@pytest_asyncio.fixture(autouse=True)
async def setup_test_db():
    fastapi_app.dependency_overrides[get_db] = override_get_db
    # Always recreate tables for fresh schema (handles migrations/model changes)
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    fastapi_app.dependency_overrides.clear()
