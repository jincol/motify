from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class OrderStatusEnum(str, Enum):
    pending = "pending"
    in_process = "in_process"
    finished = "finished"
    cancelled = "cancelled"
    with_issue = "with_issue"


class OrderBase(BaseModel):
    title: str
    sender_name: str
    sender_phone: Optional[str] = None
    description: Optional[str] = None
    instructions: Optional[str] = None

class OrderCreate(OrderBase):
    pass

class OrderUpdate(OrderBase):
    title: str
    sender_name: str
    sender_phone: Optional[str] = None
    description: Optional[str] = None
    instructions: Optional[str] = None
    status: Optional[OrderStatusEnum] = None

class OrderInDBBase(BaseModel):
    id: int
    code: str
    courier_id: Optional[int] = None
    admin_id: Optional[int] = None
    title: str
    sender_name: str
    sender_phone: Optional[str] = None
    description: Optional[str] = None
    instructions: Optional[str] = None
    status: OrderStatusEnum = OrderStatusEnum.pending
    created_at: datetime
    assigned_at: Optional[datetime]
    finished_at: Optional[datetime]

    class Config:
        orm_mode = True

class Order(OrderInDBBase):
    pass