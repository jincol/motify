from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models.stop import Stop
from datetime import datetime

async def get_stop(db: AsyncSession, stop_id: int):
    res = await db.execute(select(Stop).where(Stop.id == stop_id))
    return res.scalars().first()

async def confirm_stop(db: AsyncSession, stop: Stop, payload, confirmed_by: int):
    stop.photo_url = payload.photo_url
    stop.latitude = payload.latitude
    stop.longitude = payload.longitude
    stop.notes = payload.notes
    stop.confirmed = True
    stop.timestamp = datetime.utcnow()
    stop.updated_at = datetime.utcnow()
    stop.confirmed_by = confirmed_by
    db.add(stop)
    await db.commit()
    await db.refresh(stop)
    return stop

async def create_and_confirm_stop(db: AsyncSession, payload, confirmed_by: int):
    """Crea y confirma una parada en un solo paso"""
    # Calcular stop_order automáticamente
    result = await db.execute(
        select(func.count(Stop.id)).where(Stop.order_id == payload.order_id)
    )
    current_count = result.scalar() or 0
    
    new_stop = Stop(
        order_id=payload.order_id,
        type=payload.type,
        address=payload.address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        photo_url=payload.photo_url,
        timestamp=payload.timestamp or datetime.utcnow(),
        stop_order=current_count + 1,
        confirmed=True,  # Ya confirmada
        confirmed_by=confirmed_by,
        notes=payload.notes,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    
    db.add(new_stop)
    await db.commit()
    await db.refresh(new_stop)
    return new_stop
