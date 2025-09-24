# app/crud/user.py
from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any

from app.db import models 
from app.schemas import user as user_schemas # Importa tus esquemas Pydantic para usuarios
from app.core.security import get_password_hash, verify_password # Importa utilidades

def get_user_by_id(db: Session, user_id: int) -> Optional[models.User]:
    """
    Obtiene un usuario por su ID.
    """
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_username(db: Session, username: str) -> Optional[models.User]:
    """
    Obtiene un usuario por su nombre de usuario.
    """
    return db.query(models.User).filter(models.User.username == username).first()

def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """
    Obtiene un usuario por su email.
    """
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100) -> List[models.User]:
    """
    Obtiene una lista de usuarios con paginación.
    """
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user_in: user_schemas.UserCreate) -> models.User:
    """
    Crea un nuevo usuario en la base de datos.
    """
    hashed_password = get_password_hash(user_in.password)
    db_user_data = user_in.dict(exclude={"password"}) 
    db_user_data["password_hash"] = hashed_password
    
    if db_user_data["role"] == "super_admin":
        db_user_data["is_superuser"] = True
    
    db_user = models.User(**db_user_data)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(
    db: Session, 
    user_db_obj: models.User, 
    user_in: user_schemas.UserUpdate  
) -> models.User:
    """
    Actualiza un usuario existente.
    'user_db_obj' es el objeto usuario obtenido de la BD.
    'user_in' es un esquema Pydantic con los campos a actualizar.
    """

    update_data = user_in.dict(exclude_unset=True) 

    if "password" in update_data and update_data["password"]:
        hashed_password = get_password_hash(update_data["password"])
        del update_data["password"] 
        update_data["password_hash"] = hashed_password

    for field, value in update_data.items():
        setattr(user_db_obj, field, value)
    
    db.add(user_db_obj) 
    db.commit()
    db.refresh(user_db_obj)
    return user_db_obj

def delete_user_logically(db: Session, user_id: int) -> Optional[models.User]:
    """
    Marca un usuario como inactivo (eliminación lógica).
    """
    user_db_obj = get_user_by_id(db, user_id=user_id)
    if user_db_obj:
        user_db_obj.is_active = False
        db.add(user_db_obj)
        db.commit()
        db.refresh(user_db_obj)
    return user_db_obj

def delete_user_physically(db: Session, user_id: int) -> Optional[models.User]:
    """
    Elimina físicamente un usuario de la base de datos.
    ¡Usar con precaución debido a posibles problemas de integridad referencial!
    """
    user_db_obj = get_user_by_id(db, user_id=user_id)
    if user_db_obj:
        db.delete(user_db_obj)
        db.commit()
    return user_db_obj 

def authenticate_user(db: Session, *, username: str, password: str) -> Optional[models.User]:
    """
    Autentica un usuario.

    1. Busca al usuario por su nombre de usuario.
    2. Si el usuario existe, verifica su contraseña.
    3. Si la contraseña es correcta, devuelve el objeto User del modelo.
    4. En cualquier otro caso (usuario no encontrado o contraseña incorrecta), devuelve None.

    :param db: La sesión de SQLAlchemy.
    :param username: El nombre de usuario a autenticar.
    :param password: La contraseña en texto plano a verificar.
    :return: El objeto User si la autenticación es exitosa, None en caso contrario.
    """
    db_user = get_user_by_username(db, username=username)
    if not db_user:
        return None 
    if not verify_password(password, db_user.password_hash):
        return None  
    
    if not db_user.is_active:
        return None 

    return db_user

