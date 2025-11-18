from typing import List
from app.api import deps
from app.db.models import User
from app.db.database import get_async_db
from sqlalchemy.exc import IntegrityError
from app.crud.crud_order import crud_order
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException
from app.schemas.order import Order, OrderCreate, OrderUpdate

router = APIRouter()

@router.post("/", response_model=Order, status_code=201)
async def create_order(
    order_in: OrderCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(deps.get_current_user),
):
    extra = {}

    role_val = None
    if hasattr(current_user, "role"):
        role_attr = getattr(current_user, "role")
        role_val = getattr(role_attr, "value", str(role_attr))

    if role_val and role_val.lower() == "motorizado":
        extra["courier_id"] = current_user.id
        extra["admin_id"] = None

    try:
        created = await crud_order.create(db, order_in, extra=extra)
        return created
    except IntegrityError as e:
        raise HTTPException(status_code=400, detail=f"Datos inválidos o referencia ausente: {str(e)}")


@router.get("/mine", response_model=List[Order])
async def read_my_orders(
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(deps.get_current_user),
):
    """Retorna los pedidos asignados al motorizado autenticado (courier)."""
    # Si no hay user id, retorna vacio
    courier_id = getattr(current_user, "id", None)
    if courier_id is None:
        return []
    return await crud_order.get_by_courier(db, courier_id)

@router.get("/courier/{courier_id}/today", response_model=List[Order])
async def read_courier_orders_today(
    courier_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(deps.get_current_user),
):
    """
    Retorna los pedidos del día actual de un motorizado específico.
    Solo accesible para admins del grupo o el mismo motorizado.
    """
    from app.db.models.user import UserRole
    from app.crud.user import get_user_by_id
    
    # Validación: Motorizado solo puede ver sus propios pedidos
    if current_user.role == UserRole.MOTORIZADO:
        if courier_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="No puedes ver los pedidos de otro motorizado"
            )
    
    # Validación: Admin solo puede ver pedidos de su grupo
    elif current_user.role == UserRole.ADMIN_MOTORIZADO:
        target_user = await get_user_by_id(db, courier_id)
        
        if not target_user:
            raise HTTPException(status_code=404, detail=f"Motorizado {courier_id} no encontrado")
        
        if target_user.grupo_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="No puedes ver pedidos de motorizados fuera de tu grupo"
            )
    
    return await crud_order.get_by_courier_today(db, courier_id)


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