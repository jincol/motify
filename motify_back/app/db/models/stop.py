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

    id = Column("id_parada", Integer, primary_key=True, index=True)
    order_id = Column("pedido_id", Integer, ForeignKey("pedidos.id_pedido"), nullable=False)
    type = Column("tipo", Enum(StopTypeEnum), nullable=False)
    order_index = Column("orden", Integer, nullable=False)
    address = Column("direccion", String(500), nullable=True)
    gps_lat = Column("gps_lat", Float, nullable=True)
    gps_lng = Column("gps_lng", Float, nullable=True)
    photo_url = Column("foto_url", String(512), nullable=True)
    datetime_at = Column("fecha_hora", DateTime, nullable=True)
    confirmed = Column("confirmado", Boolean, nullable=False, default=False)
    notes = Column("notes", Text, nullable=True)  # <--- usa la columna DB "notes"
    created_at = Column("created_at", DateTime, default=datetime.utcnow)
    updated_at = Column("updated_at", DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    order = relationship("Order", back_populates="stops")