from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class UserLocation(Base):
    """
    Modelo para almacenar las ubicaciones GPS de los motorizados.
    """
    __tablename__ = "user_locations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    accuracy = Column(Float, nullable=True) 
    timestamp = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), index=True)
    work_state = Column(String(50), nullable=True)  # 'INACTIVO', 'JORNADA_ACTIVA', 'EN_RUTA'
    pedido_id = Column(Integer, ForeignKey("orders.id", ondelete="SET NULL"), nullable=True, index=True) 
    speed = Column(Float, nullable=True)  # Velocidad en m/s
    heading = Column(Float, nullable=True)  # Dirección (0-360 grados)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Índices para optimizar queries frecuentes
    __table_args__ = (
        Index('ix_user_locations_user_timestamp', 'user_id', 'timestamp'),
        Index('ix_user_locations_work_state', 'work_state'),
        Index('ix_user_locations_pedido', 'pedido_id'),  
        Index('ix_user_locations_user_pedido', 'user_id', 'pedido_id'),  
    )

    def __repr__(self):
        return f"<UserLocation(id={self.id}, user_id={self.user_id}, lat={self.latitude}, lng={self.longitude}, timestamp={self.timestamp})>"