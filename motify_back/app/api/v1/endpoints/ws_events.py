from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from fastapi.exceptions import WebSocketException
from sqlalchemy.orm import Session
from typing import List
from jose import JWTError
from app.api.deps import get_current_user   
from app.db.database import SessionLocal

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for c in self.active_connections:
            await c.send_text(message)

manager = ConnectionManager()

@router.websocket("/ws/events")
async def websocket_endpoint(websocket: WebSocket):
    db: Session = SessionLocal()
    try:
        token = websocket.query_params.get("token")
        if not token:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        if token.lower().startswith("bearer "):
            token = token[7:]

        # OJO: get_current_user es SÍNCRONA → sin await
        user = get_current_user(db=db, token=token)

        await manager.connect(websocket)

        try:
            while True:
                msg = await websocket.receive_text()
                await websocket.send_text(f"Echo: {msg}")
        except WebSocketDisconnect:
            manager.disconnect(websocket)

    except JWTError:
        # JWT inválido → 1008
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
    except Exception:
        # Cualquier otra falla interna → 1011
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)
    finally:
        db.close()
