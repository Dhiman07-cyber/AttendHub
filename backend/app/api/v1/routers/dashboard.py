from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.schemas.dashboard import DashboardOverviewOut
from app.services.dashboard_service import get_dashboard_overview

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("", response_model=DashboardOverviewOut)
async def read_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve full dashboard overview with overall attendance, semester progress, today snapshot, and insights."""
    return await get_dashboard_overview(db, current_user.id)
