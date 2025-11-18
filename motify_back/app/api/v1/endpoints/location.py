from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user
from sqlalchemy.ext.asyncio import AsyncSession
from app.crud import location as location_crud
from app.db.models.user import User, UserRole
from app.db.database import get_async_db
from app.crud.user import get_user_by_id
from datetime import datetime
from typing import List
from app.schemas.location import LocationResponse, LocationUpdate, UserLocationDetail

router = APIRouter()


@router.post("/update", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
async def update_location(
    location_in: LocationUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Endpoint para actualizar la ubicación GPS de un motorizado.**

      vamos a validar estos registros 
    - El usuario debe estar autenticado
    - Solo motorizados pueden actualizar su propia ubicación
    - Admins pueden actualizar ubicaciones de su grupo
    """
    # VALIDACIÓN: Si envía pedido_id, verificar que existe y está activo
    if location_in.pedido_id is not None:
        from app.crud.crud_order import crud_order
        order = await crud_order.get(db, location_in.pedido_id)
        
        if not order:
            print(f'⚠️ Pedido {location_in.pedido_id} no existe, guardando sin pedido_id')
            location_in.pedido_id = None
        elif order.status not in ['pending', 'in_process']:
            print(f'⚠️ Pedido {location_in.pedido_id} no está activo (status={order.status}), guardando sin pedido_id')
            location_in.pedido_id = None
        elif order.courier_id != location_in.user_id:
            print(f'⚠️ Pedido {location_in.pedido_id} no pertenece al usuario {location_in.user_id}, guardando sin pedido_id')
            location_in.pedido_id = None
    
    if current_user.role == UserRole.MOTORIZADO:
        if location_in.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes actualizar la ubicación de otro usuario"
            )
    
    elif current_user.role in [UserRole.ADMIN_MOTORIZADO, UserRole.SUPER_ADMIN]:
        # Verificar que el usuario pertenece al grupo del admin
        target_user = await get_user_by_id(db, location_in.user_id)
        
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario {location_in.user_id} no encontrado"
            )
        
        if current_user.role == UserRole.ADMIN_MOTORIZADO:
            if target_user.grupo_id != current_user.grupo_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="No puedes actualizar ubicaciones de usuarios fuera de tu grupo"
                )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu rol no tiene permisos para actualizar ubicaciones"
        )
    
    # Crear la ubicación
    db_location = await location_crud.create_location(db=db, location_in=location_in)
    return db_location


@router.get("/user/{user_id}", response_model=LocationResponse)
async def get_user_last_location(
    user_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Obtiene la última ubicación registrada de un usuario específico.**
    
      Aca tambien validaresmos
    - El usuario debe estar autenticado
    - Motorizados solo pueden ver su propia ubicación
    - Admins solo pueden ver ubicaciones de su grupo
    - Super Admin puede ver cualquier ubicación
    """
    # Validación: Motorizado solo puede ver su ubicación
    if current_user.role == UserRole.MOTORIZADO:
        if user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver la ubicación de otro usuario"
            )
    
    # Validación: Admin solo puede ver ubicaciones de su grupo
    elif current_user.role == UserRole.ADMIN_MOTORIZADO:
        target_user = await get_user_by_id(db, user_id)
        
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario {user_id} no encontrado"
            )
        
        if target_user.grupo_id != current_user.grupo_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver ubicaciones de usuarios fuera de tu grupo"
            )
    
    # Obtener última ubicación
    location = await location_crud.get_last_location_by_user(db=db, user_id=user_id)
    
    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se encontró ninguna ubicación para el usuario {user_id}"
        )
    
    return location


@router.get("/group/{grupo_id}", response_model=List[UserLocationDetail])
async def get_group_locations(
    grupo_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Obtiene las últimas ubicaciones de todos los usuarios de un grupo.**
    
    Validaciones:
    - Solo Admins y Super Admins pueden usar este endpoint
    - Admin solo puede ver ubicaciones de SU grupo (motorizados cuyo grupo_id = admin.id)
    - Super Admin puede ver cualquier grupo
    
    **Uso típico:** Dashboard de admin para ver mapa en tiempo real de su equipo
    
    **IMPORTANTE:** grupo_id es el ID del admin, no del motorizado
    """
    # Validación: Solo admins
    if current_user.role not in [UserRole.ADMIN_MOTORIZADO, UserRole.SUPER_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden ver ubicaciones de grupo"
        )
    
    # Validación: Admin solo puede ver ubicaciones de motorizados de su grupo
    # El grupo_id debe ser igual al ID del admin (no al grupo_id del admin, que es NULL)
    if current_user.role == UserRole.ADMIN_MOTORIZADO:
        if grupo_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver ubicaciones de otro grupo"
            )
    
    # Obtener ubicaciones del grupo
    # Esto busca motorizados que tienen grupo_id = grupo_id (que es el ID del admin)
    locations = await location_crud.get_locations_by_group(db=db, grupo_id=grupo_id)
    
    return locations


@router.get("/history/{user_id}", response_model=List[LocationResponse])
async def get_user_location_history(
    user_id: int,
    start_date: datetime = None,
    end_date: datetime = None,
    limit: int = 100,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Obtiene el historial de ubicaciones de un usuario con filtros.**
    
    **Validaciones:**
    - Motorizado solo puede ver su historial
    - Admin solo puede ver historial de su grupo
    - Super Admin puede ver cualquier historial
    
    **Uso típico:** Ver ruta completa de un motorizado en un día específico
    """
    # Validación: Motorizado solo puede ver su historial
    if current_user.role == UserRole.MOTORIZADO:
        if user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver el historial de otro usuario"
            )
    
    # Validación: Admin solo puede ver historial de su grupo
    # El grupo_id de los motorizados debe ser igual al ID del admin
    elif current_user.role == UserRole.ADMIN_MOTORIZADO:
        target_user = await get_user_by_id(db, user_id)
        
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario {user_id} no encontrado"
            )
        
        if target_user.grupo_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver historial de usuarios fuera de tu grupo"
            )
    
    history = await location_crud.get_location_history(
        db=db,
        user_id=user_id,
        start_date=start_date,
        end_date=end_date,
        limit=limit
    )
    
    return history

@router.get("/active-route/{user_id}", response_model=List[LocationResponse])
async def get_active_route_locations(
    user_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Obtiene las ubicaciones GPS del pedido activo de un motorizado.**
    """
    # Validación: Motorizado solo puede ver su ruta
    if current_user.role == UserRole.MOTORIZADO:
        if user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver la ruta de otro usuario"
            )
    
    # Validación: Admin solo puede ver rutas de su grupo
    # El grupo_id de los motorizados debe ser igual al ID del admin
    elif current_user.role == UserRole.ADMIN_MOTORIZADO:
        target_user = await get_user_by_id(db, user_id)
        
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario {user_id} no encontrado"
            )
        
        if target_user.grupo_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver rutas de usuarios fuera de tu grupo"
            )
    
    # Obtener el pedido activo del usuario (EN_RUTA o ASIGNADO)
    from app.crud.crud_order import crud_order
    
    print(f'🔍 Buscando pedido activo para usuario {user_id}...')
    active_order = await crud_order.get_active_order_by_motorizado(db, user_id)
    
    if not active_order:
        # No hay pedido activo, retornar lista vacía
        print(f'❌ No hay pedido activo para usuario {user_id}')
        return []
    
    print(f'✅ Pedido activo encontrado: ID={active_order.id}, status={active_order.status}, courier_id={active_order.courier_id}')
    
    # Obtener ubicaciones del pedido activo
    print(f'📍 Consultando ubicaciones: user_id={user_id}, pedido_id={active_order.id}')
    locations = await location_crud.get_locations_by_order(
        db=db,
        user_id=user_id,
        pedido_id=active_order.id
    )
    
    print(f'� Ubicaciones encontradas: {len(locations)}')
    if len(locations) > 0:
        print(f'   Primera: {locations[0].timestamp}')
        print(f'   Última: {locations[-1].timestamp}')
    
    return locations

@router.get("/active-route-with-stops/{user_id}")
async def get_active_route_with_stops(
    user_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Obtiene el pedido activo con sus paradas (stops) y ubicaciones GPS.**
    
    Retorna:
    - order: Información del pedido activo (id, code, status, etc)
    - stops: Lista de paradas (pickup/delivery) con coordenadas
    - gps_points: Lista de ubicaciones GPS capturadas durante la ruta
    """
    # Validación: Motorizado solo puede ver su ruta
    if current_user.role == UserRole.MOTORIZADO:
        if user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver la ruta de otro usuario"
            )
    
    # Validación: Admin solo puede ver rutas de su grupo
    elif current_user.role == UserRole.ADMIN_MOTORIZADO:
        target_user = await get_user_by_id(db, user_id)
        
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario {user_id} no encontrado"
            )
        
        if target_user.grupo_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver rutas de usuarios fuera de tu grupo"
            )
    
    # Obtener el pedido activo del usuario
    from app.crud.crud_order import crud_order
    
    active_order = await crud_order.get_active_order_by_motorizado(db, user_id)
    
    if not active_order:
        # No hay pedido activo
        return {
            "order": None,
            "stops": [],
            "gps_points": []
        }
    
    # Obtener ubicaciones GPS del pedido
    gps_locations = await location_crud.get_locations_by_order(
        db=db,
        user_id=user_id,
        pedido_id=active_order.id
    )
    
    # Convertir stops a diccionarios
    stops_list = [
        {
            "id": stop.id,
            "order_id": stop.order_id,
            "type": stop.type.value,
            "stop_order": stop.stop_order,
            "address": stop.address,
            "latitude": stop.latitude,
            "longitude": stop.longitude,
            "photo_url": stop.photo_url,
            "timestamp": stop.timestamp.isoformat() if stop.timestamp else None,
            "confirmed": stop.confirmed,
            "notes": stop.notes,
        }
        for stop in active_order.stops
    ]
    
    # Convertir ubicaciones GPS a diccionarios
    gps_points_list = [
        {
            "latitude": loc.latitude,
            "longitude": loc.longitude,
            "timestamp": loc.timestamp.isoformat(),
            "accuracy": loc.accuracy,
            "speed": loc.speed,
            "heading": loc.heading,
        }
        for loc in gps_locations
    ]
    
    return {
        "order": {
            "id": active_order.id,
            "code": active_order.code,
            "title": active_order.title,
            "status": active_order.status.value,
            "courier_id": active_order.courier_id,
        },
        "stops": stops_list,
        "gps_points": gps_points_list
    }


@router.get("/route-by-order/{order_id}")
async def get_route_by_order(
    order_id: int,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    """
    **Obtiene la ruta de un pedido específico (activo o finalizado) con sus paradas y GPS points.**
    
    Parámetros:
    - order_id: ID del pedido del cual queremos ver la ruta
    
    Retorna:
    - order: Información del pedido
    - stops: Lista de paradas (pickup/delivery)
    - gps_points: Ubicaciones GPS capturadas (con pedido_id)
    """
    from app.crud.crud_order import crud_order
    
    # Obtener el pedido
    order = await crud_order.get(db, order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pedido {order_id} no encontrado"
        )
    
    # Validación: Motorizado solo puede ver sus propios pedidos
    if current_user.role == UserRole.MOTORIZADO:
        if order.courier_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver pedidos de otro usuario"
            )
    
    # Validación: Admin solo puede ver pedidos de su grupo
    elif current_user.role == UserRole.ADMIN_MOTORIZADO:
        # Obtener el motorizado del pedido
        if order.courier_id:
            target_user = await get_user_by_id(db, order.courier_id)
            
            if not target_user:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Usuario {order.courier_id} no encontrado"
                )
            
            if target_user.grupo_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="No puedes ver pedidos de usuarios fuera de tu grupo"
                )
    
    # Obtener ubicaciones GPS del pedido
    gps_locations = await location_crud.get_locations_by_order(
        db=db,
        user_id=order.courier_id,
        pedido_id=order_id
    )
    
    # Convertir stops a diccionarios
    stops_list = [
        {
            "id": stop.id,
            "order_id": stop.order_id,
            "type": stop.type.value,
            "stop_order": stop.stop_order,
            "address": stop.address,
            "latitude": stop.latitude,
            "longitude": stop.longitude,
            "photo_url": stop.photo_url,
            "timestamp": stop.timestamp.isoformat() if stop.timestamp else None,
            "confirmed": stop.confirmed,
            "notes": stop.notes,
        }
        for stop in order.stops
    ]
    
    # Convertir ubicaciones GPS a diccionarios
    gps_points_list = [
        {
            "latitude": loc.latitude,
            "longitude": loc.longitude,
            "timestamp": loc.timestamp.isoformat(),
            "accuracy": loc.accuracy,
            "speed": loc.speed,
            "heading": loc.heading,
            "pedido_id": loc.pedido_id,
        }
        for loc in gps_locations
    ]
    
    print(f"📍 Ruta del pedido {order_id}: {len(stops_list)} paradas, {len(gps_points_list)} puntos GPS")
    
    return {
        "order": {
            "id": order.id,
            "code": order.code,
            "title": order.title,
            "status": order.status.value,
            "courier_id": order.courier_id,
        },
        "stops": stops_list,
        "gps_points": gps_points_list
    }


@router.post("/update-test", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
async def update_location_test(
    location_in: LocationUpdate,
    db: AsyncSession = Depends(get_async_db)
):
    """
    **[TESTING ONLY] Endpoint SIN validación de permisos**
    
    Usa este endpoint solo para probar que la funcionalidad básica funciona.
    NO usar en producción. No requiere autenticación.
    """
    db_location = await location_crud.create_location(db=db, location_in=location_in)
    return db_location