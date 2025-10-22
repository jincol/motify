from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from typing import List
from app.api import deps
from app.db.database import get_async_db
from app.schemas.order import Order, OrderCreate, OrderUpdate
from app.crud.crud_order import crud_order
from app.db.models import User

router = APIRouter(
    tags=["orders"],
)

@router.post("/", response_model=Order)
async def create_order(
    order_in: OrderCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(deps.get_current_user),
):
    data = order_in.dict()
    # Normalizar el role (puede venir como Enum con .value en mayúsculas)
    role_val = None
    if hasattr(current_user, "role"):
        role_attr = getattr(current_user, "role")
        role_val = getattr(role_attr, "value", str(role_attr))
    if role_val and role_val.lower() == "motorizado":
        data["courier_id"] = current_user.id
        data["admin_id"] = None
    try:
        return await crud_order.create(db, OrderCreate(**data))
    except IntegrityError:
        raise HTTPException(status_code=400, detail="Datos inválidos: referencia a usuario inexistente u otro conflicto")

@router.get("/", response_model=List[Order])
async def read_orders(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_async_db)):
    return await crud_order.get_multi(db, skip=skip, limit=limit)

@router.get("/{order_id}", response_model=Order)
async def read_order(order_id: int, db: AsyncSession = Depends(get_async_db)):
    order = await crud_order.get(db, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.put("/{order_id}", response_model=Order)
async def update_order(order_id: int, order_in: OrderUpdate, db: AsyncSession = Depends(get_async_db)):
    db_order = await crud_order.get(db, order_id)
    if not db_order:
        raise HTTPException(status_code=404, detail="Order not found")
    return await crud_order.update(db, db_order, order_in)

@router.delete("/{order_id}", response_model=Order)
async def delete_order(order_id: int, db: AsyncSession = Depends(get_async_db)):
    db_order = await crud_order.get(db, order_id)
    if not db_order:
        raise HTTPException(status_code=404, detail="Order not found")
    return await crud_order.remove(db, order_id)