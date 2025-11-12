import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict


load_dotenv()

class Settings(BaseSettings):# Define tus variables de entorno/configuración aquí
    PROJECT_NAME: str = "Motify API"
    PROJECT_VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256" # Puedes tener valores por defecto
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 días (24h * 7 = 168h = 10080 min)

    model_config = SettingsConfigDict(
        env_file=".env",              
        env_file_encoding='utf-8',
        extra='ignore'
    )


settings = Settings()

print("Configuración cargada:")
print(f"  DATABASE_URL: {settings.DATABASE_URL}")
print(f"  SECRET_KEY: {'*' * len(settings.SECRET_KEY) if settings.SECRET_KEY else None}")
print(f"  ALGORITHM: {settings.ALGORITHM}")
print(f"  ACCESS_TOKEN_EXPIRE_MINUTES: {settings.ACCESS_TOKEN_EXPIRE_MINUTES}")
