import uuid
from datetime import date
from sqlalchemy import String, Integer, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.session import Base

class TimetableEntry(Base):
    __tablename__ = "timetable_entries"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: uuid.uuid4().hex)
    semester_id: Mapped[str] = mapped_column(String(36), ForeignKey("semesters.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id: Mapped[str] = mapped_column(String(36), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=True) # 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
    start_time: Mapped[str] = mapped_column(String(10), nullable=True) # "09:00"
    end_time: Mapped[str] = mapped_column(String(10), nullable=True) # "10:00"
    faculty_name: Mapped[str] = mapped_column(String(100), nullable=True)
    room: Mapped[str] = mapped_column(String(50), nullable=True)
    effective_from: Mapped[date] = mapped_column(Date, nullable=True)
    effective_to: Mapped[date] = mapped_column(Date, nullable=True)
    
    # Relationships
    semester = relationship("Semester", back_populates="timetable_entries")
    subject = relationship("Subject", back_populates="timetable_entries")
