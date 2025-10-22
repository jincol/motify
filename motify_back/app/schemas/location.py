from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class LocationUpdate(BaseModel):
    """
    Schema para recibir actualización de ubicación desde la app móvil.
    """
    user_id: int = Field(..., description="ID del usuario motorizado")
    latitude: float = Field(..., ge=-90, le=90, description="Latitud GPS")
    longitude: float = Field(..., ge=-180, le=180, description="Longitud GPS")
    accuracy: Optional[float] = Field(None, description="Precisión del GPS en metros")
    work_state: Optional[str] = Field(None, description="Estado laboral del motorizado")
    speed: Optional[float] = Field(None, description="Velocidad en m/s")
    heading: Optional[float] = Field(None, ge=0, le=360, description="Dirección en grados")
    timestamp: Optional[datetime] = Field(None, description="Hora de captura GPS (ISO 8601)")

    class Config:
        json_schema_extra = {
            "example": {
                "user_id": 5,
                "latitude": -12.046374,
                "longitude": -77.042793,
                "accuracy": 10.5,
                "work_state": "EN_RUTA",
                "speed": 5.2,
                "heading": 45.0,
                "timestamp": "2025-10-16T10:30:00Z"
            }
        }


class LocationResponse(BaseModel):
    """
    Schema para responder con la ubicación almacenada.
    """
    id: int
    user_id: int
    latitude: float
    longitude: float
    accuracy: Optional[float]
    timestamp: datetime
    work_state: Optional[str]
    speed: Optional[float]
    heading: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True


class UserLocationDetail(BaseModel):
    """
    Schema para responder con ubicación + datos básicos del usuario.
    Usado en el endpoint de grupo.
    """
    user_id: int
    username: str
    name: Optional[str]
    lastname: Optional[str]
    role: str
    work_state: str
    latitude: float
    longitude: float
    accuracy: Optional[float]
    timestamp: datetime
    speed: Optional[float]
    heading: Optional[float]

    class Config:
        from_attributes = True


class LocationHistoryQuery(BaseModel):
    """
    Schema para filtrar historial de ubicaciones.
    """
    user_id: int
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    limit: int = Field(100, le=1000, description="Máximo 1000 registros")