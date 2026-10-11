from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.calendar import CalendarMonthOut
from app.services.calendar_service import get_calendar_month

router = APIRouter(prefix="/calendar", tags=["Calendar"])

@router.get("", response_model=CalendarMonthOut)
async def read_calendar(
    year: Optional[int] = Query(None),
    month: Optional[int] = Query(None),
    selected_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve monthly calendar with day markers and sessions for the selected day."""
    return await get_calendar_month(db, current_user.id, year, month, selected_date)
