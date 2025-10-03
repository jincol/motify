import os
from app.db import models 
from fastapi import FastAPI
from app.db.database import engine
from app.core.config import settings
from contextlib import asynccontextmanager 
from fastapi.staticfiles import StaticFiles
from app.api.v1.endpoints import auth as auth_endpoints 
from app.api.v1.endpoints import users as users_endpoints 
from app.api.v1.endpoints import photo as photo_endpoints
from app.api.v1.endpoints import ws_events as ws_events_endpoints
from app.api.v1.endpoints import attendance as attendance_endpoints

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("INFO:     Aplicación iniciándose...")
    yield
    print("INFO:     Aplicación apagándose...")

app = FastAPI(
    title=settings.PROJECT_NAME, 
    version=settings.PROJECT_VERSION,
    lifespan=lifespan
)

fotos_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "fotos"))
os.makedirs(fotos_dir, exist_ok=True)
app.mount("/fotos", StaticFiles(directory=fotos_dir), name="fotos")

# Routers
# Router para autenticación
app.include_router(
    auth_endpoints.router, 
    prefix=f"{settings.API_V1_STR}/auth", 
    tags=["Auth"] 
)
# Router para usuarios
app.include_router(
    users_endpoints.router, 
    prefix=f"{settings.API_V1_STR}/users",
    tags=["Users"]
)
#Asistencia
app.include_router(
    attendance_endpoints.router,
    prefix=f"{settings.API_V1_STR}/attendance",
    tags=["Attendance"]
)

#fotos
app.include_router(
    photo_endpoints.router,
    prefix=f"{settings.API_V1_STR}",
    tags=["Photo"]
)

# Router Websocket
app.include_router(
    ws_events_endpoints.router,
    prefix="",  # Sin prefijo para que sea /ws/events
    tags=["WebSocket"]
)

# --- Endpoint Raíz (Opcional) ---
@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.PROJECT_NAME}!"}





# --- Consideraciones Adicionales (Middleware, CORS, etc.) ---
# Por ejemplo, para CORS (Cross-Origin Resource Sharing) si tu frontend está en otro dominio:
# from fastapi.middleware.cors import CORSMiddleware
# origins = [
#     "http://localhost",
#     "http://localhost:3000", # Si tu frontend corre en el puerto 3000
#     # Añade aquí los orígenes permitidos
# ]
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=origins,
#     allow_credentials=True,
#     allow_methods=["*"], # Permite todos los métodos (GET, POST, etc.)
#     allow_headers=["*"], # Permite todas las cabeceras
# )


