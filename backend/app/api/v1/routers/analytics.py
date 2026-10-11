from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.analytics import AnalyticsOverviewOut
from app.services.analytics_service import get_analytics_overview

router = APIRouter(prefix="/analytics", tags=["Analytics"])

@router.get("/overview", response_model=AnalyticsOverviewOut)
async def read_analytics_overview(
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve full analytics overview with deterministic forecasting and insights."""
    return await get_analytics_overview(db, current_user.id, semester_id)
