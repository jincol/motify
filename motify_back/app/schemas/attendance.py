from pydantic import BaseModel
from typing import Literal
from datetime import datetime

class AttendanceBase(BaseModel):
    type: Literal["check-in", "check-out"]
    photo_url: str
    gps_lat: float
    gps_lng: float

class AttendanceCreate(AttendanceBase):
    pass

class AttendanceRead(AttendanceBase):
    id: int
    user_id: int
    timestamp: datetime
    confirmed: bool

    class Config:
        from_attributes = True