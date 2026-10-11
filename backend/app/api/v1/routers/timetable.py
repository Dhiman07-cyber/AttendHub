from typing import List, Optional
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.timetable import (
    TimetableEntryOut,
    TimetableEntryCreate,
    TimetableEntryUpdate,
    WeeklyRoutineStatusOut,
)
from app.services.timetable_service import (
    list_timetable,
    create_timetable_entry,
    update_timetable_entry,
    delete_timetable_entry,
    list_weekly_status,
)

router = APIRouter(prefix="/timetable", tags=["Timetable"])

@router.get("/weekly-status", response_model=WeeklyRoutineStatusOut)
async def get_weekly_status(
    week_offset: int = Query(0, ge=-52, le=52),
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get synthesized weekly routine slots joined with actual saved attendance status."""
    return await list_weekly_status(db, current_user.id, semester_id, week_offset)

@router.get("", response_model=List[TimetableEntryOut])
async def get_routine(
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get weekly timetable entries for the semester."""
    return await list_timetable(db, current_user.id, semester_id)

@router.post("", response_model=TimetableEntryOut, status_code=status.HTTP_201_CREATED)
async def add_routine_entry(
    data: TimetableEntryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a timetable schedule slot."""
    return await create_timetable_entry(db, current_user.id, data)

@router.patch("/{id}", response_model=TimetableEntryOut)
async def update_routine_entry(
    id: str,
    data: TimetableEntryUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update a timetable schedule slot."""
    return await update_timetable_entry(db, current_user.id, id, data)

@router.delete("/{id}")
async def delete_routine_entry(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Remove a timetable schedule slot."""
    return await delete_timetable_entry(db, current_user.id, id)
