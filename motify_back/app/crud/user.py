# app/crud/user.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import Optional, List, Dict, Any

from app.db import models
from app.schemas import user as user_schemas  # Importa tus esquemas Pydantic para usuarios
from app.core.security import get_password_hash, verify_password  # Importa utilidades


async def get_user_by_id(db: AsyncSession, user_id: int) -> Optional[models.User]:
    """
    Obtiene un usuario por su ID.
    """
    result = await db.execute(select(models.User).filter(models.User.id == user_id))
    return result.scalar_one_or_none()

async def get_user_by_username(db: AsyncSession, username: str) -> Optional[models.User]:
    """
    Obtiene un usuario por su nombre de usuario.
    """
    result = await db.execute(
        select(models.User).filter(func.lower(models.User.username) == username.lower())
    )
    return result.scalar_one_or_none()

async def get_user_by_email(db: AsyncSession, email: str) -> Optional[models.User]:
    """
    Obtiene un usuario por su email.
    """
    result = await db.execute(
        select(models.User).filter(models.User.email == email)
    )
    return result.scalar_one_or_none()

async def get_users(db: AsyncSession, skip: int = 0, limit: int = 100) -> List[models.User]:
    """
    Obtiene una lista de usuarios con paginación.
    """
    result = await db.execute(
        select(models.User).offset(skip).limit(limit)
    )
    return result.scalars().all()

async def create_user(db: AsyncSession, user_in: user_schemas.UserCreate) -> models.User:
    """
    Crea un nuevo usuario en la base de datos.
    """
    hashed_password = get_password_hash(user_in.password)
    db_user_data = user_in.dict(exclude={"password"})
    db_user_data["username"] = db_user_data["username"].lower()
    db_user_data["password_hash"] = hashed_password
    print("DEBUG db_user_data:", db_user_data)
    if db_user_data["role"] == "super_admin":
        db_user_data["is_superuser"] = True
    db_user = models.User(**db_user_data)
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

async def update_user(
    db: AsyncSession,
    user_db_obj: models.User,
    user_in: user_schemas.UserUpdate
) -> models.User:
    """
    Actualiza un usuario existente.
    'user_db_obj' es el objeto usuario obtenido de la BD.
    'user_in' es un esquema Pydantic con los campos a actualizar.
    """
    update_data = user_in.dict(exclude_unset=True)
    print("DEBUG user_in:", user_in)
    print("DEBUG update_data:", update_data)
    if "password" in update_data and update_data["password"]:
        hashed_password = get_password_hash(update_data["password"])
        del update_data["password"]
        update_data["password_hash"] = hashed_password
    for field, value in update_data.items():
        print(f"Set {field} = {value}")
        setattr(user_db_obj, field, value)
    name = update_data.get("name", user_db_obj.name)
    lastname = update_data.get("lastname", user_db_obj.lastname)
    user_db_obj.full_name = f"{name} {lastname}".strip()
    db.add(user_db_obj)
    await db.commit()
    await db.refresh(user_db_obj)
    return user_db_obj

async def delete_user_logically(db: AsyncSession, user_id: int) -> Optional[models.User]:
    """
    Marca un usuario como inactivo (eliminación lógica).
    """
    user_db_obj = await get_user_by_id(db, user_id=user_id)
    if user_db_obj:
        user_db_obj.is_active = False
        user_db_obj.work_state = "INACTIVO"
        db.add(user_db_obj)
        await db.commit()
        await db.refresh(user_db_obj)
    return user_db_obj

async def delete_user_physically(db: AsyncSession, user_id: int) -> Optional[models.User]:
    """
    Elimina físicamente un usuario de la base de datos.
    ¡Usar con precaución debido a posibles problemas de integridad referencial - NO SEAS GILBERTO! 
    """
    user_db_obj = await get_user_by_id(db, user_id=user_id)
    if user_db_obj:
        await db.delete(user_db_obj)
        await db.commit()
    return user_db_obj

async def authenticate_user(db: AsyncSession, *, username: str, password: str) -> Optional[models.User]:
    """
    Autentica un usuario.

    1. Busca al usuario por su nombre de usuario.
    2. Si el usuario existe, verifica su contraseña.
    3. Si la contraseña es correcta, devuelve el objeto User del modelo.
    4. En cualquier otro caso (usuario no encontrado o contraseña incorrecta), devuelve None.
    """
    db_user = await get_user_by_username(db, username=username)
    if not db_user:
        return None
    if not verify_password(password, db_user.password_hash):
        return None
    if not db_user.is_active:
        return None
    return db_user

