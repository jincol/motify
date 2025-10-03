# app/api/v1/endpoints/users.py
from app.db import models
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Any, Optional
from app import crud
from app.schemas.user import UserRead
from app.schemas import user as user_schema 
from app.db.models.user import User
from app.api import deps 

router = APIRouter()

@router.get("/me", response_model=user_schema.UserResponse) 
async def read_users_me(
    current_user: User = Depends(deps.get_current_user) 
) -> Any: 
    """
    Obtiene el perfil del usuario actualmente autenticado.
    """
    return current_user
# ---------------------------------


@router.post("/", response_model=user_schema.UserRead, status_code=status.HTTP_201_CREATED)
async def create_user_endpoint(
    *,
    db: AsyncSession = Depends(deps.get_async_db),
    user_in: user_schema.UserCreate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Crea un nuevo usuario.
    """
    existing_user_by_username = await crud.user.get_user_by_username(db, username=user_in.username)
    if existing_user_by_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El nombre de usuario '{user_in.username}' ya está en uso.",
        )
    if user_in.email:
        existing_user_by_email = await crud.user.get_user_by_email(db, email=user_in.email)
        if existing_user_by_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El correo electrónico '{user_in.email}' ya está en uso.",
            )
    user_in.grupo_id = current_user.id
    user = await crud.user.create_user(db=db, user_in=user_in)
    return user

@router.get("/{user_id}", response_model=UserRead)
async def read_user_endpoint(
    *,
    db: AsyncSession = Depends(deps.get_async_db),
    user_id: int,
) -> models.User:
    """
    Obtiene un usuario por su ID.
    """
    db_user = await crud.user.get_user_by_id(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return db_user


@router.get("/", response_model=List[user_schema.UserRead])
async def list_users(
    db: AsyncSession = Depends(deps.get_async_db),
    current_user: User = Depends(deps.get_current_user),
    role: Optional[user_schema.UserRole] = None,
    grupo_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Lista usuarios filtrados por rol y grupo, según permisos del usuario autenticado.
    """
    from sqlalchemy.future import select
    stmt = select(User)
    if current_user.role == user_schema.UserRole.SUPER_ADMIN:
        if role:
            stmt = stmt.filter(User.role == role)
        if grupo_id:
            stmt = stmt.filter(User.grupo_id == grupo_id)
    elif current_user.role == user_schema.UserRole.ADMIN_MOTORIZADO:
        stmt = stmt.filter(User.grupo_id == current_user.id, User.role == user_schema.UserRole.MOTORIZADO)
    elif current_user.role == user_schema.UserRole.ADMIN_ANFITRIONA:
        stmt = stmt.filter(User.grupo_id == current_user.id, User.role == user_schema.UserRole.ANFITRIONA)
    else:
        stmt = stmt.filter(User.id == current_user.id)
    stmt = stmt.offset(skip).limit(limit)
    result = await db.execute(stmt)
    users = result.scalars().all()
    return users

# @router.get("/{user_id}", response_model=user_schema.UserRead)
# async def read_user_by_id(
#     user_id: int,
#     db: Session = Depends(deps.get_db),
#     # current_user: models.User = Depends(deps.get_current_active_user) # Para protegerlo
# ) -> Any:
#     """
#     Obtiene un usuario por su ID.
#     """
#     user = crud.user.get_user_by_id(db, user_id=user_id)
#     if not user:
#         raise HTTPException(
#             status_code=status.HTTP_404_NOT_FOUND,
#             detail="User not found",
#         )
#     # Aquí podrías añadir lógica de permisos si el usuario actual solo puede ver ciertos usuarios
#     return user

