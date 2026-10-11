import uuid
from datetime import datetime, timezone
from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.session import Base

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: uuid.uuid4().hex)
    class_session_id: Mapped[str] = mapped_column(String(36), ForeignKey("class_sessions.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False) # ATTENDED, ABSENT, NOT_HELD
    marked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    source: Mapped[str] = mapped_column(String(30), default="manual") # manual, bulk, import, system_generated
    
    # Relationships
    session = relationship("ClassSession", back_populates="attendance_record")
    user = relationship("User", back_populates="attendance_records")

