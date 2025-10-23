from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# Importar las dependencias correctas desde app.api.deps
from app.api.deps import get_async_db, get_current_user
from app.crud import crud_stop
from app.schemas.stop import StopConfirm
from app.db.models.order import Order

router = APIRouter(prefix="/stops", tags=["stops"])


@router.post("/{stop_id}/confirm", status_code=status.HTTP_200_OK)
async def confirm_stop(
    stop_id: int,
    payload: StopConfirm,
    db: AsyncSession = Depends(get_async_db),
    current_user = Depends(get_current_user),
):
    # obtener la parada
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
    # `confirm_stop` en CRUD debe encargarse de commit/refresh y devolver el objeto actualizado

    return {"detail": "stop confirmed", "stop_id": stop_id}