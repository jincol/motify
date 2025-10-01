# app/api/v1/endpoints/users.py
from app.db import models
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Any, Optional
from app import crud
from app.schemas.user import UserRead
from app.schemas import user as user_schema 
from app.db.models.user import User
from app.api import deps # Para la dependencia get_db

router = APIRouter()

@router.get("/me", response_model=user_schema.UserResponse) 
def read_users_me(
    current_user: User = Depends(deps.get_current_user) 
) -> Any: 
    """
    Obtiene el perfil del usuario actualmente autenticado.
    """
    return current_user
# ---------------------------------


@router.post("/", response_model=user_schema.UserRead, status_code=status.HTTP_201_CREATED)
def create_user_endpoint(
    *, # El '*' fuerza a que los siguientes argumentos sean keyword-only
    db: Session = Depends(deps.get_db),
    user_in: user_schema.UserCreate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Crea un nuevo usuario.
    """
    existing_user_by_username = crud.user.get_user_by_username(db, username=user_in.username)
    if existing_user_by_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El nombre de usuario '{user_in.username}' ya está en uso.",
        )

    if user_in.email:
        existing_user_by_email = crud.user.get_user_by_email(db, email=user_in.email)
        if existing_user_by_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El correo electrónico '{user_in.email}' ya está en uso.",
            )
    user_in.grupo_id = current_user.id
    user = crud.user.create_user(db=db, user_in=user_in)
    return user

@router.get("/{user_id}", response_model=UserRead)
def read_user_endpoint(
    *,
    db: Session = Depends(deps.get_db),
    user_id: int,
) -> models.User:
    """
    Obtiene un usuario por su ID.
    """
    db_user = crud.user.get_user_by_id(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return db_user


@router.get("/", response_model=List[user_schema.UserRead])
def list_users(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    role: Optional[user_schema.UserRole] = None,
    grupo_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Lista usuarios filtrados por rol y grupo, según permisos del usuario autenticado.
    """
    query = db.query(User)
    if current_user.role == user_schema.UserRole.SUPER_ADMIN:
        if role:
            query = query.filter(User.role == role)
        if grupo_id:
            query = query.filter(User.grupo_id == grupo_id)
    elif current_user.role == user_schema.UserRole.ADMIN_MOTORIZADO:
        query = query.filter(User.grupo_id == current_user.id, User.role == user_schema.UserRole.MOTORIZADO)
    elif current_user.role == user_schema.UserRole.ADMIN_ANFITRIONA:
        query = query.filter(User.grupo_id == current_user.id, User.role == user_schema.UserRole.ANFITRIONA)
    else:
        query = query.filter(User.id == current_user.id)
    users = query.offset(skip).limit(limit).all()
    return users

# @router.get("/{user_id}", response_model=user_schema.UserRead)
# def read_user_by_id(
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

