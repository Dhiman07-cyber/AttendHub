from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.auth import (
    UserRegister, UserLogin, Token, RefreshTokenRequest,
    UserOut, PasswordResetRequest, PasswordResetConfirm
)
from app.services.auth_service import register_user, authenticate_user, refresh_user_token
from app.api.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new student account and initialize default 5th semester and subjects."""
    _, token = await register_user(db, data)
    return token

@router.post("/login", response_model=Token)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    """Authenticate student with email and password."""
    _, token = await authenticate_user(db, data)
    return token

@router.post("/refresh", response_model=Token)
async def refresh(data: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """Refresh access token using valid refresh token."""
    return await refresh_user_token(db, data.refresh_token)

@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user)):
    """Client clears token; endpoint confirms session termination."""
    return {"status": "success", "message": "Successfully logged out."}

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get currently authenticated student profile."""
    return current_user
