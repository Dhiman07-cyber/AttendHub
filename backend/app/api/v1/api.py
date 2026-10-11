from fastapi import APIRouter
from app.api.v1.routers import (
    auth, profile, semesters, subjects, timetable,
    sessions, attendance, holidays, dashboard,
    calendar, analytics, imports
)

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(semesters.router)
api_router.include_router(subjects.router)
api_router.include_router(timetable.router)
api_router.include_router(sessions.router)
api_router.include_router(attendance.router)
api_router.include_router(holidays.router)
api_router.include_router(dashboard.router)
api_router.include_router(calendar.router)
api_router.include_router(analytics.router)
api_router.include_router(imports.router)
