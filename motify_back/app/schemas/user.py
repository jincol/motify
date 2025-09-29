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
    email: Optional[EmailStr] = Field(None, description="Correo electrónico del usuario") 
    full_name: Optional[str] = Field(None, max_length=255, description="Nombre completo del usuario")
    role: UserRole = Field(..., description="Rol del usuario en el sistema")
    work_state: WorkState = Field(..., description="Estado de jornada del usuario")
    grupo_id: Optional[int] = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, description="Contraseña del usuario (mínimo 8 caracteres)")
    is_active: Optional[bool] = True
    is_superuser: Optional[bool] = False
    work_state: Optional[WorkState] = WorkState.INACTIVO  
    
class UserUpdate(BaseModel): 
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = Field(None, min_length=8, description="Nueva contraseña (opcional, mínimo 8 caracteres)")
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None
    is_superuser: Optional[bool] = None
    grupo_id: Optional[int] = None

class UserRead(UserBase):
    id: int
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
    
class UserResponse(UserBase):
    id: int
    is_superuser: bool

    class Config:
        # orm_mode = True
        from_attributes = True
