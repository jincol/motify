from pydantic import BaseModel, EmailStr, Field, ConfigDict 
from typing import Optional
from datetime import datetime 
from enum import Enum

class UserRole(str, Enum):
    MOTORIZADO = "MOTORIZADO"
    ADMIN_MOTORIZADO = "ADMIN_MOTORIZADO"
    ANFITRIONA = "ANFITRIONA"
    ADMIN_ANFITRIONA = "ADMIN_ANFITRIONA"
    SUPER_ADMIN = "SUPER_ADMIN"

class WorkState(str, Enum):
    INACTIVO = "INACTIVO"
    JORNADA_ACTIVA = "JORNADA_ACTIVA"
    EN_RUTA = "EN_RUTA"

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=100, description="Nombre de usuario único")
    email: Optional[EmailStr] = Field(None, description="Correo electrónico del usuario") # Considera si el email debe ser siempre obligatorio
    full_name: Optional[str] = Field(None, max_length=255, description="Nombre completo del usuario")
    role: UserRole = Field(..., description="Rol del usuario en el sistema")
    work_state: WorkState = Field(..., description="Estado de jornada del usuario")

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, description="Contraseña del usuario (mínimo 8 caracteres)")
    is_active: Optional[bool] = True
    is_superuser: Optional[bool] = False
    work_state: Optional[WorkState] = WorkState.INACTIVO  
    
class UserUpdate(BaseModel): # Esquema para actualizar un usuario por un admin
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = Field(None, min_length=8, description="Nueva contraseña (opcional, mínimo 8 caracteres)")
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None
    is_superuser: Optional[bool] = None

class UserRead(UserBase):
    id: int # <--- AÑADE ESTO si no lo tenías (asumo que tu modelo User tiene un id)
    is_active: bool # Heredado de UserBase, pero aquí lo haces no opcional para la lectura
    is_superuser: bool # Heredado de UserBase, pero aquí lo haces no opcional para la lectura
    
    created_at: datetime  # <--- CAMBIO PRINCIPAL: Añadir created_at
    updated_at: datetime  # <--- CAMBIO PRINCIPAL: Añadir updated_at

    # No incluimos password_hash (correcto)

    # Para Pydantic V2 (recomendado si estás empezando un proyecto nuevo o puedes actualizar):
    model_config = ConfigDict(from_attributes=True)
    
    # Para Pydantic v1 (si estás atado a esta versión):
    # class Config:
    #     orm_mode = True

class UserResponse(UserBase):
    id: int
    is_superuser: bool
    # No incluimos password_hash aquí

    class Config:
        # orm_mode = True
        from_attributes = True
