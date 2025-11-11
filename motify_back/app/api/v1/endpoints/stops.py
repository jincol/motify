from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.api.deps import get_async_db, get_current_user
from app.crud import crud_stop
from app.schemas.stop import StopConfirm, StopOut, StopCreateAndConfirm
from app.db.models.order import Order
from app.db.models.user import User
from app.db.models.stop import Stop

router = APIRouter()


@router.post("/{stop_id}/confirm", status_code=status.HTTP_200_OK)
async def confirm_stop(
    stop_id: int,
    payload: StopConfirm,
    db: AsyncSession = Depends(get_async_db),
    current_user = Depends(get_current_user),
):
    stop = await crud_stop.get_stop(db, stop_id)
    if stop is None:
        raise HTTPException(status_code=404, detail="Stop not found")

    stmt = select(Order).where(Order.id == stop.order_id)
    result = await db.execute(stmt)
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    if not getattr(current_user, "is_superuser", False):
        courier_id = getattr(order, "courier_id", None)
        if courier_id is None or courier_id != getattr(current_user, "id", None):
            raise HTTPException(status_code=403, detail="Not allowed to confirm this stop")

    updated = await crud_stop.confirm_stop(db, stop, payload, confirmed_by=current_user.id)

    # 🚀 Lógica de cambio de work_state
    if stop.type == "pickup" and updated:
        # Al confirmar recojo → EN_RUTA
        stmt_update_user = (
            update(User)
            .where(User.id == current_user.id)
            .values(work_state="EN_RUTA")
        )
        await db.execute(stmt_update_user)
        await db.commit()
        print(f"✅ Usuario {current_user.id} cambió a EN_RUTA al confirmar recojo")
    
    elif stop.type == "delivery" and updated:
        # Al confirmar entrega → verificar si todas las entregas están completas
        stmt_stops = (
            select(Stop)
            .where(Stop.order_id == order.id)
        )
        result_stops = await db.execute(stmt_stops)
        all_stops = result_stops.scalars().all()
        
        # Verificar si todas las entregas están confirmadas
        deliveries = [s for s in all_stops if s.type == "delivery"]
        all_deliveries_confirmed = all(s.confirmed for s in deliveries)
        
        print(f"🔍 Pedido {order.id}: {len(deliveries)} entregas, confirmadas: {all_deliveries_confirmed}")
        
        if all_deliveries_confirmed and len(deliveries) > 0:
            # Cambiar estado del pedido a finished (completado)
            stmt_update_order = (
                update(Order)
                .where(Order.id == order.id)
                .values(status="finished")
            )
            await db.execute(stmt_update_order)
            print(f"✅ Pedido {order.id} marcado como finished")
            
            # Verificar si hay otros pedidos activos
            stmt_active_orders = (
                select(Order)
                .where(
                    Order.courier_id == current_user.id,
                    Order.id != order.id,
                    Order.status == "in_process"
                )
            )
            result_active = await db.execute(stmt_active_orders)
            active_orders = result_active.scalars().all()
            
            print(f"🔍 Usuario {current_user.id}: {len(active_orders)} pedidos activos (excluyendo el actual)")
            
            if len(active_orders) == 0:
                # No hay más pedidos activos → JORNADA_ACTIVA
                stmt_update_user = (
                    update(User)
                    .where(User.id == current_user.id)
                    .values(work_state="JORNADA_ACTIVA")
                )
                await db.execute(stmt_update_user)
                print(f"✅ Usuario {current_user.id} cambió a JORNADA_ACTIVA (no hay más pedidos activos)")
            else:
                print(f"⚠️ Usuario {current_user.id} mantiene EN_RUTA ({len(active_orders)} pedidos activos)")
        
        await db.commit()

    return {"detail": "stop confirmed", "stop_id": stop_id}


@router.post("/", response_model=StopOut, status_code=status.HTTP_201_CREATED)
async def create_and_confirm_stop(
    payload: StopCreateAndConfirm,
    db: AsyncSession = Depends(get_async_db),
    current_user = Depends(get_current_user),
):
    # 1. Crear la parada
    stop = await crud_stop.create_and_confirm_stop(db, payload, confirmed_by=current_user.id)
    if not stop:
        raise HTTPException(status_code=400, detail="Could not create/confirm stop")
    
    # 🚀 Lógica de cambio de work_state
    if stop.type == "pickup":
        # Al confirmar recojo → EN_RUTA
        stmt_update_user = (
            update(User)
            .where(User.id == current_user.id)
            .values(work_state="EN_RUTA")
        )
        await db.execute(stmt_update_user)
        await db.commit()
        print(f"✅ Usuario {current_user.id} cambió a EN_RUTA al confirmar recojo")
    
    elif stop.type == "delivery":
        # Al confirmar entrega → verificar si todas las entregas están completas
        stmt_stops = (
            select(Stop)
            .where(Stop.order_id == stop.order_id)
        )
        result_stops = await db.execute(stmt_stops)
        all_stops = result_stops.scalars().all()
        
        # Verificar si todas las entregas están confirmadas
        deliveries = [s for s in all_stops if s.type == "delivery"]
        all_deliveries_confirmed = all(s.confirmed for s in deliveries)
        
        print(f"🔍 Pedido {stop.order_id}: {len(deliveries)} entregas, confirmadas: {all_deliveries_confirmed}")
        
        if all_deliveries_confirmed and len(deliveries) > 0:
            # Cambiar estado del pedido a finished (completado)
            stmt_update_order = (
                update(Order)
                .where(Order.id == stop.order_id)
                .values(status="finished")
            )
            await db.execute(stmt_update_order)
            print(f"✅ Pedido {stop.order_id} marcado como finished")
            
            # Verificar si hay otros pedidos activos
            stmt_active_orders = (
                select(Order)
                .where(
                    Order.courier_id == current_user.id,
                    Order.id != stop.order_id,
                    Order.status == "in_process"
                )
            )
            result_active = await db.execute(stmt_active_orders)
            active_orders = result_active.scalars().all()
            
            print(f"🔍 Usuario {current_user.id}: {len(active_orders)} pedidos activos (excluyendo el actual)")
            
            if len(active_orders) == 0:
                # No hay más pedidos activos → JORNADA_ACTIVA
                stmt_update_user = (
                    update(User)
                    .where(User.id == current_user.id)
                    .values(work_state="JORNADA_ACTIVA")
                )
                await db.execute(stmt_update_user)
                print(f"✅ Usuario {current_user.id} cambió a JORNADA_ACTIVA (no hay más pedidos activos)")
            else:
                print(f"⚠️ Usuario {current_user.id} mantiene EN_RUTA ({len(active_orders)} pedidos activos)")
        
        await db.commit()
    
    return stop