from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime
import enum

class StopTypeEnum(str, enum.Enum):
    pickup = "pickup"
    delivery = "delivery"

class Stop(Base):
    __tablename__ = "stops"

    id = Column("id", Integer, primary_key=True, index=True)
    order_id = Column("order_id", Integer, ForeignKey("orders.id"), nullable=False)
    type = Column("type", Enum(StopTypeEnum, name="tipoparada_enum"), nullable=False)
    stop_order = Column("stop_order", Integer, nullable=False)
    address = Column("address", String(500), nullable=True)
    latitude = Column("latitude", Float, nullable=True)
    longitude = Column("longitude", Float, nullable=True)
    photo_url = Column("photo_url", String(512), nullable=True)
    timestamp = Column("timestamp", DateTime, nullable=True)
    confirmed = Column("confirmed", Boolean, nullable=False, default=False)
    notes = Column("notes", Text, nullable=True)
    confirmed_by = Column("confirmed_by", Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column("created_at", DateTime, default=datetime.utcnow)
    updated_at = Column("updated_at", DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    order = relationship("Order", back_populates="stops")
    confirmed_by_user = relationship("User", foreign_keys=[confirmed_by])