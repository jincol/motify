# app/db/models/user.py
from sqlalchemy import Column, Integer, String, Boolean, Enum as SQLAlchemyEnum, DateTime
from sqlalchemy.sql import func
from ..database import Base
from enum import Enum

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# AQUÍ SE DEFINE EL ENUM UserRole y workState
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
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
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100) , nullable=True, index=True)  
    lastname = Column(String(100), nullable=True, index=True)  
    username = Column(String(100), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    full_name = Column(String(255), nullable=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(SQLAlchemyEnum(UserRole, name="userrole_enum", create_constraint=True), nullable=False, default=UserRole.MOTORIZADO)
    grupo_id = Column(Integer, nullable=True, index=True)  
    is_active = Column(Boolean(), default=True, nullable=False)
    is_superuser = Column(Boolean(), default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=func.now(), server_default=func.now(), onupdate=func.now(), nullable=False)
    work_state = Column(SQLAlchemyEnum(WorkState, name="workstate_enum", create_constraint=True), nullable=False, default=WorkState.INACTIVO)  
    phone = Column(String, nullable=True)
    placa_unidad = Column(String, nullable=True)
    avatar_url = Column(String(512), nullable=True) 
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}', role='{self.role.value}', work_state='{self.work_state.value}')>"

