from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
import httpx
import logging

from app.core.config import settings
from app.db.session import engine, Base, get_db
from app.api.v1.api import api_router
import app.models  # Ensure all models are registered

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("attendhub")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Auto-create tables on startup for local development / testing
    logger.info("Initializing AttendHub database tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database initialized successfully.")
    yield
    # Shutdown
    logger.info("Shutting down AttendHub engine...")
    await engine.dispose()

app = FastAPI(
    title="AttendHub API",
    description="AttendHub Production-Grade Student Attendance Tracking & Analytics Engine",
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS setup
_cors_origins = [
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]
for origin in settings.CORS_ORIGINS:
    if origin != "*" and origin not in _cors_origins:
        _cors_origins.append(origin)

_cors_regex = (
    r"^https?://.*$"
    if "*" in settings.CORS_ORIGINS
    else r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_origin_regex=_cors_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API v1 router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception(f"Unhandled exception on {request.method} {request.url}: {exc}")
    origin = request.headers.get("origin")
    response = JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An internal server error occurred. Please try again."},
    )
    if origin:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
    return response

@app.api_route("/health", methods=["GET", "HEAD"], tags=["Health"])
@app.api_route(f"{settings.API_V1_STR}/health", methods=["GET", "HEAD"], tags=["Health"])
async def health_check(db: AsyncSession = Depends(get_db)):
    """
    Health check & keep-alive endpoint for Render and cron jobs.
    Actively queries Supabase PostgreSQL and pings the Supabase REST gateway
    so neither Render nor the Supabase free-tier project goes to sleep/pauses.
    """
    db_status = "disconnected"
    try:
        await db.execute(text("SELECT COUNT(id) FROM users"))
        db_status = "connected"
    except Exception:
        try:
            await db.execute(text("SELECT 1"))
            db_status = "connected"
        except Exception as e:
            logger.warning(f"Database ping failed during health check: {e}")

    supabase_rest_status = "skipped"
    if settings.SUPABASE_URL and settings.SUPABASE_PUBLISHABLE_KEY:
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                resp = await client.get(
                    f"{settings.SUPABASE_URL.rstrip('/')}/rest/v1/",
                    headers={"apikey": settings.SUPABASE_PUBLISHABLE_KEY},
                )
                supabase_rest_status = "ok" if resp.status_code < 500 else f"http_{resp.status_code}"
        except Exception as e:
            logger.debug(f"Supabase REST keep-alive ping skipped/failed: {e}")
            supabase_rest_status = "unreachable"

    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "service": "AttendiFy Backend",
        "version": settings.VERSION,
        "database": db_status,
        "supabase_ping": supabase_rest_status,
    }

@app.get("/", tags=["Health"])
async def root():
    return {
        "message": "Welcome to AttendiFy API — Track · Plan · Stay Above",
        "documentation": "/docs",
        "version": settings.VERSION
    }
