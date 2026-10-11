from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.session import ClassSessionOut, ExtraClassCreate
from app.services.attendance_service import add_extra_class_session

router = APIRouter(prefix="/sessions", tags=["Class Sessions"])

@router.post("/extra", response_model=ClassSessionOut, status_code=status.HTTP_201_CREATED)
async def create_extra_class(
    data: ExtraClassCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create an extra unscheduled class session."""
    return await add_extra_class_session(db, current_user.id, data)
