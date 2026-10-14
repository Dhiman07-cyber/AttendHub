from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.semester import SemesterOut, SemesterCreate, SemesterUpdate, SemesterSwitchRequest
from app.services.academic_service import (
    list_semesters, create_semester, update_semester, switch_semester
)

router = APIRouter(prefix="/semesters", tags=["Semesters"])

@router.get("", response_model=List[SemesterOut])
async def get_semesters(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all semesters scoped to this student."""
    return await list_semesters(db, current_user.id)

@router.post("", response_model=SemesterOut, status_code=status.HTTP_201_CREATED)
async def add_semester(
    data: SemesterCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a new semester record."""
    return await create_semester(db, current_user.id, data)

@router.patch("/{id}", response_model=SemesterOut)
async def modify_semester(
    id: str,
    data: SemesterUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update semester term details like start_date, end_date, total_weeks, or label."""
    return await update_semester(db, current_user.id, id, data)

@router.post("/switch", response_model=SemesterOut)
async def change_active_semester(
    data: SemesterSwitchRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Switch active semester context. Switches all subjects, timetable, and attendance context."""
    return await switch_semester(db, current_user.id, data.semester_id)

@router.post("/{id}/activate", response_model=SemesterOut)
async def activate_semester_by_id(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Activate semester by ID path parameter."""
    return await switch_semester(db, current_user.id, id)
