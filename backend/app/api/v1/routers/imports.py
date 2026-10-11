from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.import_schema import (
    ImportParseResponse, RoutineReviewRequest, HolidayReviewRequest
)
from app.services.import_service import (
    parse_routine_file, parse_holiday_file, confirm_routine_draft, confirm_holiday_draft
)

router = APIRouter(prefix="/imports", tags=["Imports & File Processing"])

import os

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg", ".webp", ".csv"}
ALLOWED_MIME_TYPES = {"application/pdf", "image/png", "image/jpeg", "image/webp", "text/csv", "text/plain"}

def _validate_uploaded_file(file: UploadFile, content: bytes) -> None:
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="File size exceeds 10MB limit.")
    
    filename = file.filename or ""
    ext = os.path.splitext(filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file extension '{ext}'. Allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
        )
    
    if file.content_type and file.content_type.lower() not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported MIME type '{file.content_type}'. Allowed: {', '.join(sorted(ALLOWED_MIME_TYPES))}"
        )

@router.post("/routine/parse", response_model=ImportParseResponse)
async def upload_routine_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload routine image/PDF. Parses document into structured draft for user review.
    Enforces review-before-save architecture and strict file validation.
    """
    content = await file.read()
    _validate_uploaded_file(file, content)
    return await parse_routine_file(file.filename, content)

@router.post("/routine/confirm")
async def confirm_routine(
    payload: RoutineReviewRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Confirm and commit reviewed timetable draft entries into the database."""
    return await confirm_routine_draft(db, current_user.id, payload)

@router.post("/holidays/parse", response_model=ImportParseResponse)
async def upload_holiday_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload holiday list image/PDF for parsing into draft."""
    content = await file.read()
    _validate_uploaded_file(file, content)
    return await parse_holiday_file(file.filename, content)

@router.post("/holidays/confirm")
async def confirm_holidays(
    payload: HolidayReviewRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Confirm and commit reviewed holiday draft into the database."""
    return await confirm_holiday_draft(db, current_user.id, payload)
