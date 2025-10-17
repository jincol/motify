from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from jose import JWTError
from app.api.deps import get_current_user, get_async_db

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[int, list[WebSocket]] = {}

    async def connect(self, grupo_id: int, websocket: WebSocket):
        await websocket.accept()
        if grupo_id not in self.active_connections:
            self.active_connections[grupo_id] = []
        self.active_connections[grupo_id].append(websocket)
        print(f"[WS] Conectado grupo_id={grupo_id}. Total conexiones en grupo: {len(self.active_connections[grupo_id])}")

    def disconnect(self, grupo_id: int, websocket: WebSocket):
        if grupo_id in self.active_connections:
            if websocket in self.active_connections[grupo_id]:
                self.active_connections[grupo_id].remove(websocket)
            if not self.active_connections[grupo_id]:
                del self.active_connections[grupo_id]

    async def send_to_group(self, grupo_id: int, message: str):
        conexiones = self.active_connections.get(grupo_id, [])
        print(f"[WS] Enviando mensaje a grupo_id={grupo_id}. Conexiones activas en grupo: {len(conexiones)}. Mensaje: {message}")
        for ws in conexiones:
            await ws.send_text(message)

manager = ConnectionManager()

@router.websocket("/ws/events")
async def websocket_endpoint(websocket: WebSocket):
    # Obtén la sesión async manualmente
    async for db in get_async_db():
        try:
            token = websocket.query_params.get("token")
            if not token:
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                return

            if token.lower().startswith("bearer "):
                token = token[7:]

            user = await get_current_user(db=db, token=token)
            # Debug: mostrar user y role
            print(f"[WS] Usuario conectado: id={getattr(user, 'id', None)}, role={getattr(user, 'role', None)}, grupo_id={getattr(user, 'grupo_id', None)}")

            # Asegurar que role sea string para comparar
            role_str = str(user.role) if user.role is not None else ""
            if hasattr(user, "role") and any(r in role_str.upper() for r in ["ADMIN_ANFITRIONA", "ADMIN_MOTORIZADO", "SUPER_ADMIN"]):
                grupo_id = user.id
            else:
                grupo_id = user.grupo_id

            # Si grupo_id sigue siendo None, forzar a -1 para evitar errores
            if grupo_id is None:
                print("[WS][WARN] grupo_id es None, asignando -1 (no debería ocurrir)")
                grupo_id = -1

            await manager.connect(grupo_id, websocket)

            try:
                while True:
                    msg = await websocket.receive_text()
                    await websocket.send_text(f"Echo: {msg}")
            except WebSocketDisconnect:
                manager.disconnect(grupo_id, websocket)

        except JWTError:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        except Exception:
            await websocket.close(code=status.WS_1011_INTERNAL_ERROR)
        finally:
            await db.close()
        break  # Solo una sesión por conexión