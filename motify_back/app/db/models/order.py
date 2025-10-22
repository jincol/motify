from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, Enum
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime
import enum

class OrderStatusEnum(str, enum.Enum):
    pending = "pending"
    in_process = "in_process"
    finished = "finished"
    cancelled = "cancelled"
    with_issue = "with_issue"

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, index=True, nullable=False)
    courier_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    admin_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    title = Column(String(255), nullable=False)
    sender_name = Column(String(255), nullable=False)
    sender_phone = Column(String(20))
    description = Column(Text)
    instructions = Column(Text)
    status = Column(Enum(OrderStatusEnum), nullable=False, default=OrderStatusEnum.pending)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    assigned_at = Column(DateTime)
    finished_at = Column(DateTime)

    # Relationship example (if you have a Parada model)
    # stops = relationship("Stop", back_populates="order")