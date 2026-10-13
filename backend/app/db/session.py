from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings

if not settings.DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not configured. Please provide Supabase PostgreSQL connection string in .env.")

_connect_args = {}
_engine_kwargs = {}
if settings.DATABASE_URL.startswith("postgresql+asyncpg"):
    _connect_args["statement_cache_size"] = 0
    _engine_kwargs["pool_size"] = 10
    _engine_kwargs["max_overflow"] = 20

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
    pool_pre_ping=True,
    pool_recycle=300,
    connect_args=_connect_args,
    **_engine_kwargs,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=AsyncSession
)

Base = declarative_base()

async def get_db():
    """Async database session dependency generator."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
