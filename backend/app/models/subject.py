import uuid
from sqlalchemy import String, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.session import Base

class Subject(Base):
    __tablename__ = "subjects"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: uuid.uuid4().hex)
    semester_id: Mapped[str] = mapped_column(String(36), ForeignKey("semesters.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    code: Mapped[str] = mapped_column(String(50), nullable=True)
    faculty_name: Mapped[str] = mapped_column(String(100), nullable=True)
    color: Mapped[str] = mapped_column(String(20), default="#C96E5B") # Terracotta, Sage, Amber, Rose, etc.
    icon: Mapped[str] = mapped_column(String(50), default="book")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    
    # Relationships
    semester = relationship("Semester", back_populates="subjects")
    timetable_entries = relationship("TimetableEntry", back_populates="subject", cascade="all, delete-orphan")
    class_sessions = relationship("ClassSession", back_populates="subject", cascade="all, delete-orphan")
