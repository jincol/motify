from sqlalchemy import select
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
    db.add(stop)
    await db.commit()
    await db.refresh(stop)
    return stop
