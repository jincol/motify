from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_async_db
from app.api import deps
from app.crud import crud_stop
from app.schemas.stop import StopConfirm, StopOut

router = APIRouter()


@router.post("/{stop_id}/confirm", response_model=StopOut)
async def confirm_stop(
    stop_id: int,
    payload: StopConfirm,
    db: AsyncSession = Depends(get_async_db),
    current_user = Depends(deps.get_current_user),
):
    stop = await crud_stop.get_stop(db, stop_id)
    if not stop:
        raise HTTPException(status_code=404, detail="Stop not found")

    order = stop.order
    courier_id = getattr(order, 'courier_id', None) or getattr(order, 'motorizado_id', None)
    if getattr(current_user, 'role', None) != 'admin' and current_user.id != courier_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    updated = await crud_stop.confirm_stop(db, stop, payload, current_user.id)
    return updated
