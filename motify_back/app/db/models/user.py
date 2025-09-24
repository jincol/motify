# app/db/models/user.py
from sqlalchemy import Column, Integer, String, Boolean, Enum as SQLAlchemyEnum, DateTime
from sqlalchemy.sql import func
from ..database import Base
import enum 

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# AQUÍ SE DEFINE EL ENUM UserRole
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
class UserRole(str, enum.Enum): # Hereda de str y enum.Enum
    MOTORIZADO = "motorizado"
    ADMIN_MOTORIZADO = "admin_motorizado"
    ANFITRIONA = "anfitriona"
    ADMIN_ANFITRIONA = "admin_anfitriona"
    SUPER_ADMIN = "super_admin"
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# AQUÍ TERMINA LA DEFINICIÓN DEL ENUM UserRole
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(100), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    full_name = Column(String(255), nullable=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(SQLAlchemyEnum(UserRole, name="userrole_enum", create_constraint=True), nullable=False, default=UserRole.MOTORIZADO)
    is_active = Column(Boolean(), default=True, nullable=False)
    is_superuser = Column(Boolean(), default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=func.now(), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}', role='{self.role.value}')>"

