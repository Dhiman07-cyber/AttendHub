from typing import List, Optional
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.subject import SubjectOut, SubjectDetailOut, SubjectCreate, SubjectUpdate
from app.services.subject_service import (
    list_subjects, get_subject_detail, create_subject, update_subject, delete_subject
)

router = APIRouter(prefix="/subjects", tags=["Subjects"])

@router.get("", response_model=List[SubjectOut])
async def get_subjects(
    semester_id: Optional[str] = Query(None),
    include_inactive: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List subjects for the active semester with lightweight attendance snapshot."""
    return await list_subjects(db, current_user.id, semester_id, include_inactive)

@router.post("", response_model=SubjectOut, status_code=status.HTTP_201_CREATED)
async def add_subject(
    data: SubjectCreate,
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new subject in the current semester."""
    return await create_subject(db, current_user.id, data, semester_id)

@router.get("/{id}", response_model=SubjectDetailOut)
async def get_subject(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get subject detail with attendance forecast (classes needed, safe absences)."""
    return await get_subject_detail(db, current_user.id, id)

@router.patch("/{id}", response_model=SubjectDetailOut)
async def modify_subject(
    id: str,
    data: SubjectUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update subject properties."""
    return await update_subject(db, current_user.id, id, data)

@router.delete("/{id}")
async def remove_subject(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Safely delete or archive subject."""
    return await delete_subject(db, current_user.id, id)
