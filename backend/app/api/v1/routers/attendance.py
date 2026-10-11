from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.today import TodayOverviewOut
from app.schemas.attendance import (
    AttendanceBulkMarkRequest, AttendanceCorrectionRequest, AttendanceSaveResult
)
from app.services.attendance_service import (
    get_today_sessions, bulk_save_attendance, correct_attendance_record
)

router = APIRouter(prefix="/attendance", tags=["Attendance"])

@router.get("/today", response_model=TodayOverviewOut)
@router.get("/day", response_model=TodayOverviewOut)
async def read_today(
    target_date: Optional[date] = Query(None, alias="target_date"),
    date_query: Optional[date] = Query(None, alias="date"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve scheduled classes, timing status, attendance marks, and impact for a date."""
    effective_date = date_query or target_date
    return await get_today_sessions(db, current_user.id, effective_date)

@router.post("/bulk", response_model=AttendanceSaveResult)
@router.post("/day/bulk", response_model=AttendanceSaveResult)
async def save_daily_attendance(
    payload: AttendanceBulkMarkRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Save daily attendance marks for multiple classes in one atomic transaction."""
    return await bulk_save_attendance(db, current_user.id, payload)

@router.patch("/{id}", response_model=AttendanceSaveResult)
async def correct_attendance(
    id: str,
    payload: AttendanceCorrectionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Correct a previously marked attendance record with audit log trail."""
    return await correct_attendance_record(db, current_user.id, id, payload)
