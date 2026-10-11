import uuid
from sqlalchemy import String, Integer, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.session import Base

class AcademicProfile(Base):
    __tablename__ = "academic_profiles"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: uuid.uuid4().hex)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    university_name: Mapped[str] = mapped_column(String(200), default="Assam down town University")
    course_name: Mapped[str] = mapped_column(String(200), default="B.Tech Computer Science & Engineering")
    student_id_number: Mapped[str] = mapped_column(String(100), nullable=True, default="ADTU/0/2024-28/BCSM/001")
    academic_duration_years: Mapped[int] = mapped_column(Integer, default=4)
    academic_session_start: Mapped[int] = mapped_column(Integer, default=2024)
    academic_session_end: Mapped[int] = mapped_column(Integer, default=2028)
    current_semester_id: Mapped[str] = mapped_column(String(36), nullable=True)
    
    # Defaults per spec
    minimum_attendance: Mapped[float] = mapped_column(Float, default=75.0)
    personal_target: Mapped[float] = mapped_column(Float, default=75.0)
    low_attendance_alert: Mapped[float] = mapped_column(Float, default=70.0)
    
    # Relationship
    user = relationship("User", back_populates="profile")
