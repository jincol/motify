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
    - Admin solo puede ver ubicaciones de su propio grupo
    - Super Admin puede ver cualquier grupo
    
    **Uso típico:** Dashboard de admin para ver mapa en tiempo real de su equipo
    """
    # Validación: Solo admins
    if current_user.role not in [UserRole.ADMIN_MOTORIZADO, UserRole.SUPER_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden ver ubicaciones de grupo"
        )
    
    # Validación: Admin solo puede ver su grupo
    if current_user.role == UserRole.ADMIN_MOTORIZADO:
        if grupo_id != current_user.grupo_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes ver ubicaciones de otro grupo"
            )
    
    # Obtener ubicaciones del grupo
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