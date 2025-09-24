# app/api/deps.py

from typing import Generator, Optional 

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer 
from sqlalchemy.orm import Session

from app.db.database import SessionLocal
from app.core import security 
from app.core.config import settings 
# --- AJUSTE EN IMPORTACIONES CRUD Y MODELS ---
from app import crud # Correcto para acceder a crud.get_user_by_username
from app.db.models import User # Importamos directamente el modelo User

# --- Dependencia para obtener la sesión de BD (ya la tienes) ---
def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- OAuth2PasswordBearer Instance ---
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/token" 
)

# --- Dependencia para obtener el Usuario Actual ---
def get_current_user(
    db: Session = Depends(get_db), 
    token: str = Depends(oauth2_scheme)
) -> User: # Devuelve el modelo User completo (antes models.User, ahora solo User)
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudieron validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = security.decode_token_payload(token) 
    if payload is None: 
        raise credentials_exception
    
    username: Optional[str] = payload.get("sub")
    if username is None:
        raise credentials_exception
    
    # --- AJUSTE EN LA LLAMADA A CRUD ---
    # Ahora llamamos directamente a crud.get_user_by_username
    user = crud.get_user_by_username(db, username=username) 
    
    if user is None:
        raise credentials_exception 
            
    return user

def get_current_active_superuser(
    current_user: User = Depends(get_current_user), # Ahora usa User directamente
) -> User: # Ahora usa User directamente
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cuenta inactiva"
        )
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="El usuario no tiene suficientes privilegios"
        )
    return current_user

