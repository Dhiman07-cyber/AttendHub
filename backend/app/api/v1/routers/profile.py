from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.profile import (
    AcademicProfileOut, AcademicProfileUpdate,
    SetupStatusOut, FullAcademicSetupRequest,
    FullAcademicSetupDataOut
)
from app.services.academic_service import (
    get_user_profile, update_user_profile,
    get_setup_status, execute_academic_setup,
    get_academic_setup_data
)

router = APIRouter(prefix="/profile", tags=["Profile"])

@router.get("", response_model=AcademicProfileOut)
async def read_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve full student academic profile and attendance settings."""
    return await get_user_profile(db, current_user.id)

@router.get("/setup-status", response_model=SetupStatusOut)
async def check_setup_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Check explicit academic setup completeness state."""
    return await get_setup_status(db, current_user.id)

@router.get("/setup-data", response_model=FullAcademicSetupDataOut)
async def read_academic_setup_data(
    semester_number: Optional[int] = Query(None, description="Optional semester number to load"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Fetch stored academic setup data for initial pre-fill or semester switching."""
    return await get_academic_setup_data(db, current_user.id, requested_semester_number=semester_number)

@router.post("/setup", response_model=AcademicProfileOut)
async def save_academic_setup(
    data: FullAcademicSetupRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Atomically commit full academic setup including profile, semester, subjects, routine, and holidays."""
    return await execute_academic_setup(db, current_user.id, data)

@router.patch("", response_model=AcademicProfileOut)
async def update_profile(
    data: AcademicProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update profile fields, minimum attendance percentage, or personal target."""
    return await update_user_profile(db, current_user.id, data)

