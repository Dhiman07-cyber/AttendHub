import uuid
from datetime import date
from sqlalchemy import String, Boolean, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.session import Base

class ClassSession(Base):
    __tablename__ = "class_sessions"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: uuid.uuid4().hex)
    semester_id: Mapped[str] = mapped_column(String(36), ForeignKey("semesters.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id: Mapped[str] = mapped_column(String(36), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    timetable_entry_id: Mapped[str] = mapped_column(String(36), nullable=True, index=True)
    start_time: Mapped[str] = mapped_column(String(10), nullable=True) # "09:00"
    end_time: Mapped[str] = mapped_column(String(10), nullable=True) # "10:00"
    faculty_name: Mapped[str] = mapped_column(String(100), nullable=True)
    room: Mapped[str] = mapped_column(String(50), nullable=True)
    session_status: Mapped[str] = mapped_column(String(20), default="SCHEDULED") # SCHEDULED, HELD, CANCELLED, HOLIDAY, NOT_HELD
    is_extra: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Relationships
    semester = relationship("Semester", back_populates="class_sessions")
    subject = relationship("Subject", back_populates="class_sessions")
    attendance_record = relationship("AttendanceRecord", back_populates="session", uselist=False, cascade="all, delete-orphan")
