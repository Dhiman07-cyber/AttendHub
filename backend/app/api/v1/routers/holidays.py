from typing import List, Optional
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.holiday import HolidayOut, HolidayCreate, HolidayUpdate
from app.services.holiday_service import (
    list_holidays, create_holiday, update_holiday, delete_holiday
)

router = APIRouter(prefix="/holidays", tags=["Holidays"])

@router.get("", response_model=List[HolidayOut])
async def get_holidays(
    filter_type: Optional[str] = Query(None), # upcoming, past, all
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List holidays and academic calendar events."""
    return await list_holidays(db, current_user.id, semester_id, filter_type)

@router.post("", response_model=HolidayOut, status_code=status.HTTP_201_CREATED)
async def add_holiday(
    data: HolidayCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a new holiday or multi-day break."""
    return await create_holiday(db, current_user.id, data)

@router.patch("/{id}", response_model=HolidayOut)
async def modify_holiday(
    id: str,
    data: HolidayUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update holiday details."""
    return await update_holiday(db, current_user.id, id, data)

@router.delete("/{id}")
async def remove_holiday(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a holiday record."""
    return await delete_holiday(db, current_user.id, id)
