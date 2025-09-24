from sqlalchemy import Column, Integer, Float, String, DateTime, Boolean, ForeignKey, Enum as SQLAlchemyEnum
from sqlalchemy.sql import func
from app.db.database import Base
import enum

class AttendanceType(str, enum.Enum):
    CHECK_IN = "check-in"
    CHECK_OUT = "check-out"

class Attendance(Base):
    __tablename__ = "attendances"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(SQLAlchemyEnum(AttendanceType, values_callable=lambda x: [e.value for e in x]), nullable=False)
    photo_url = Column(String, nullable=False)
    gps_lat = Column(Float, nullable=False)
    gps_lng = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    confirmed = Column(Boolean, default=True, nullable=False)