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
from sqlalchemy.future import select

router = APIRouter()


@router.post("/register-first", response_model=user_schema.UserRead, status_code=status.HTTP_201_CREATED)
async def register_first_user(
    *,
    db: AsyncSession = Depends(deps.get_async_db),
    user_in: user_schema.UserCreate,
) -> Any:
    """
    Crea el primer usuario (bootstrap).
    Este endpoint SOLO funciona si no existe ningún usuario en la tabla `users`.
    Está pensado para uso inicial; una vez creado el primer usuario devolverá 400.
    """
    # Comprobar si ya existe al menos un usuario
    result = await db.execute(select(models.User).limit(1))
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe al menos un usuario; el endpoint de bootstrap está deshabilitado.",
        )

    # Validaciones básicas
    if not user_in.password or len(user_in.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos 8 caracteres.",
        )

    # Forzar atributos de superusuario para el primer usuario
    user_in.is_superuser = True
    # Si no viene role definido, lo forzamos a SUPER_ADMIN
    try:
        # user_in.role es un Enum; asignamos si está vacío
        if not getattr(user_in, "role", None):
            user_in.role = user_schema.UserRole.SUPER_ADMIN
    except Exception:
        # si algo raro ocurre, forzamos el rol por string
        user_in.role = user_schema.UserRole.SUPER_ADMIN

    user = await crud.user.create_user(db=db, user_in=user_in)
    return user

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
                detail=f"El correo electrónico  ya está en uso.",
            )
    
    if len(user_in.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos 8 caracteres.",
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
    stmt = stmt.filter(User.is_active == True)
    stmt = stmt.offset(skip).limit(limit)
    result = await db.execute(stmt)
    users = result.scalars().all()
    return users

@router.delete("/{user_id}", response_model=user_schema.UserRead)
async def delete_user(
    *,
    db: AsyncSession = Depends(deps.get_async_db),
    user_id: int,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Elimina lógicamente (desactiva) un usuario.
    Solo puede ser usado por el admin del grupo o super admin.
    """
    user = await crud.user.delete_user_logically(db, user_id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user

from sqlalchemy.exc import IntegrityError

@router.put("/{user_id}", response_model=user_schema.UserRead)
async def update_user_endpoint(
    *,
    db: AsyncSession = Depends(deps.get_async_db),
    user_id: int,
    user_in: user_schema.UserUpdate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    db_user = await crud.user.get_user_by_id(db, user_id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if current_user.role != "SUPER_ADMIN":
        if db_user.grupo_id != current_user.id:
            raise HTTPException(status_code=403, detail="No tienes permiso para editar este usuario")

    if user_in.username and user_in.username != db_user.username:
        existing_user = await crud.user.get_user_by_username(db, username=user_in.username)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El nombre de usuario '{user_in.username}' ya está en uso.",
            )

    if user_in.email and user_in.email != db_user.email:
        existing_email = await crud.user.get_user_by_email(db, email=user_in.email)
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El correo electrónico ya está en uso.",
            )

    if user_in.password and len(user_in.password) < 7:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos 8 caracteres.",
        )

    try:
        user = await crud.user.update_user(db, db_user, user_in)
        return user
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail="El nombre de usuario o correo ya está en uso."
        )