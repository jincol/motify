# app/api/deps.py
from typing import Generator
from sqlalchemy.orm import Session

from app.db.database import SessionLocal # Importa tu SessionLocal

def get_db() -> Generator[Session, None, None]:
    """
    Dependencia de FastAPI para obtener una sesión de base de datos.
    Asegura que la sesión de base de datos se cierre después de cada solicitud.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

