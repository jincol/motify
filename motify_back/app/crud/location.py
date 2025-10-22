from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc, and_, func
from typing import Optional, List
from datetime import datetime

from app.db.models.user_location import UserLocation
from app.db.models.user import User
from app.schemas.location import LocationUpdate, UserLocationDetail


async def create_location(
    db: AsyncSession, 
    location_in: LocationUpdate
) -> UserLocation:
    """
    Crea un nuevo registro de ubicación en la base de datos.
    retornara el userLocation:
    """
    location_data = location_in.model_dump()
    
    # Si no envió timestamp, usar el del servidor
    if location_data.get("timestamp") is None:
        location_data.pop("timestamp", None)
    
    db_location = UserLocation(**location_data)
    db.add(db_location)
    await db.commit()
    await db.refresh(db_location)
    return db_location


async def get_last_location_by_user(
    db: AsyncSession, 
    user_id: int
) -> Optional[UserLocation]:
    """
    Obtiene la última ubicación registrada de un usuario.
    
    Returns:
        UserLocation | None: Última ubicación o None si no existe
    """
    result = await db.execute(
        select(UserLocation)
        .filter(UserLocation.user_id == user_id)
        .order_by(desc(UserLocation.timestamp))
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_locations_by_group(
    db: AsyncSession, 
    grupo_id: int
) -> List[UserLocationDetail]:
    """
    Obtiene las últimas ubicaciones de todos los usuarios de un grupo.
    
    Hace un JOIN con la tabla users para traer datos del motorizado.
    Retorna solo la ubicación más reciente de cada usuario.

    """
    subquery = (
        select(
            UserLocation.user_id,
            func.max(UserLocation.timestamp).label("max_timestamp")
        )
        .group_by(UserLocation.user_id)
        .subquery()
    )
    
    # Query principal con JOIN
    result = await db.execute(
        select(
            UserLocation.user_id,
            User.username,
            User.name,
            User.lastname,
            User.role,
            User.work_state,
            UserLocation.latitude,
            UserLocation.longitude,
            UserLocation.accuracy,
            UserLocation.timestamp,
            UserLocation.speed,
            UserLocation.heading
        )
        .join(User, UserLocation.user_id == User.id)
        .join(
            subquery,
            and_(
                UserLocation.user_id == subquery.c.user_id,
                UserLocation.timestamp == subquery.c.max_timestamp
            )
        )
        .filter(User.grupo_id == grupo_id)
        .filter(User.is_active == True)
    )
    
    rows = result.all()
    
    # Convertir a lista de objetos UserLocationDetail
    locations = []
    for row in rows:
        locations.append(UserLocationDetail(
            user_id=row.user_id,
            username=row.username,
            name=row.name,
            lastname=row.lastname,
            role=row.role.value,
            work_state=row.work_state.value,
            latitude=row.latitude,
            longitude=row.longitude,
            accuracy=row.accuracy,
            timestamp=row.timestamp,
            speed=row.speed,
            heading=row.heading
        ))
    
    return locations


async def get_location_history(
    db: AsyncSession,
    user_id: int,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    limit: int = 100
) -> List[UserLocation]:
    """
    Obtiene el historial de ubicaciones de un usuario con filtros.
    
    Args:
        db: Sesión async de la base de datos
        user_id: ID del usuario
        start_date: Fecha de inicio (opcional)
        end_date: Fecha de fin (opcional)
        limit: Límite de registros (default 100, máximo 1000)
        
    Returns:
        List[UserLocation]: Lista de ubicaciones ordenadas por timestamp DESC
    """
    query = select(UserLocation).filter(UserLocation.user_id == user_id)
    
    if start_date:
        query = query.filter(UserLocation.timestamp >= start_date)
    
    if end_date:
        query = query.filter(UserLocation.timestamp <= end_date)
    
    query = query.order_by(desc(UserLocation.timestamp)).limit(min(limit, 1000))
    
    result = await db.execute(query)
    return result.scalars().all()