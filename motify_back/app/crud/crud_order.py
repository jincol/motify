from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete
from sqlalchemy.orm import selectinload
from app.db.models.order import Order
from app.schemas.order import OrderCreate, OrderUpdate
from typing import List, Optional, Dict, Any
from datetime import datetime
from uuid import uuid4


def _generate_order_code() -> str:
    """Genera un código legible y suficientemente único para pedidos."""
    ts = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    suffix = uuid4().hex[:6].upper()
    return f"PED-{ts}-{suffix}"


class CRUDOrder:
    async def get(self, db: AsyncSession, order_id: int) -> Optional[Order]:
        result = await db.execute(
            select(Order)
            .options(selectinload(Order.stops))  # Cargar las paradas relacionadas
            .where(Order.id == order_id)
        )
        return result.scalars().first()

    async def get_multi(self, db: AsyncSession, skip: int = 0, limit: int = 100) -> List[Order]:
        result = await db.execute(select(Order).offset(skip).limit(limit))
        return result.scalars().all()

    async def get_by_courier(self, db: AsyncSession, courier_id: int, skip: int = 0, limit: int = 100) -> List[Order]:
        """Obtener pedidos asignados a un courier (motorizado) con sus paradas."""
        result = await db.execute(
            select(Order)
            .options(selectinload(Order.stops))  # Cargar las paradas relacionadas
            .where(Order.courier_id == courier_id)
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()

    async def create(self, db: AsyncSession, obj_in: OrderCreate, extra: Optional[Dict[str, Any]] = None) -> Order:
        """
        Crea un Order en DB.

        - obj_in: campos que vienen del cliente (title, sender_name, sender_phone, description, instructions).
        - extra: diccionario opcional con campos server-side (por ejemplo 'courier_id', 'admin_id').
        - recomendado: que el endpoint pase 'courier_id' tomado del token aquí.
        """
        data = obj_in.dict()
        if extra:
            data.update(extra)

        if not data.get("code"):
            data["code"] = _generate_order_code()

        db_obj = Order(**data)
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

    async def update(self, db: AsyncSession, db_obj: Order, obj_in: OrderUpdate) -> Order:
        obj_data = obj_in.dict(exclude_unset=True)
        for field, value in obj_data.items():
            setattr(db_obj, field, value)
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

    async def remove(self, db: AsyncSession, order_id: int) -> Optional[Order]:
        result = await db.execute(select(Order).where(Order.id == order_id))
        db_obj = result.scalars().first()
        if db_obj:
            await db.delete(db_obj)
            await db.commit()
        return db_obj

crud_order = CRUDOrder()