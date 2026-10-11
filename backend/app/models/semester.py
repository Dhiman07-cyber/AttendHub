import uuid
from datetime import date
from sqlalchemy import String, Integer, Boolean, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.session import Base

class Semester(Base):
    __tablename__ = "semesters"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: uuid.uuid4().hex)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    semester_number: Mapped[int] = mapped_column(Integer, nullable=False)
    label: Mapped[str] = mapped_column(String(100), nullable=False) # e.g. "5th Semester"
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="ACTIVE") # ACTIVE, COMPLETED, UPCOMING
    is_active: Mapped[bool] = mapped_column(Boolean, default=True) # currently selected semester
    total_weeks: Mapped[int] = mapped_column(Integer, default=16)
    
    # Relationships
    user = relationship("User", back_populates="semesters")
    subjects = relationship("Subject", back_populates="semester", cascade="all, delete-orphan")
    timetable_entries = relationship("TimetableEntry", back_populates="semester", cascade="all, delete-orphan")
    class_sessions = relationship("ClassSession", back_populates="semester", cascade="all, delete-orphan")
    holidays = relationship("Holiday", back_populates="semester", cascade="all, delete-orphan")
