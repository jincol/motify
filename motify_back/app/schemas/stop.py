from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class StopConfirm(BaseModel):
    photo_url: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    notes: Optional[str] = None


class StopOut(BaseModel):
    id: int
    order_id: int
    type: str
    stop_order: int
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    photo_url: Optional[str]
    timestamp: Optional[datetime]
    confirmed: bool
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


class StopCreateAndConfirm(BaseModel):
    order_id: int
    type: str  
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    photo_url: Optional[str]
    timestamp: Optional[datetime]
    notes: Optional[str] = None
