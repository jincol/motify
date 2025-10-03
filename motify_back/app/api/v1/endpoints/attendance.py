from app.schemas.attendance import AttendanceCreate, AttendanceRead
from app.api.v1.endpoints.ws_events import manager
from app.crud.attendance import create_attendance
from sqlalchemy.ext.asyncio import AsyncSession
from app.crud.user import get_user_by_id
from fastapi import APIRouter, Depends
from app.api import deps
import json


router = APIRouter()

@router.post("/check-in", response_model=AttendanceRead)
async def check_in_attendance(
    attendance_in: AttendanceCreate,
    db: AsyncSession = Depends(deps.get_async_db),
    current_user = Depends(deps.get_current_user)
):
    attendance_obj = await create_attendance(db, user_id=current_user.id, attendance_in=attendance_in)
    attendance_dict = attendance_obj.__dict__.copy()
    attendance_dict['type'] = attendance_obj.type.value

    user_db_obj = await get_user_by_id(db, current_user.id)
    if attendance_in.type == "check-in":
        user_db_obj.work_state = "JORNADA_ACTIVA"
    elif attendance_in.type == "check-out":
        user_db_obj.work_state = "INACTIVO"
    print(f"DEBUG: Usuario {current_user.id} work_state actualizado a {user_db_obj.work_state}")
    db.add(user_db_obj)
    await db.commit()
    await db.refresh(user_db_obj)
    #Notificamos via webSocketreque
    admin_user = await get_user_by_id(db, user_db_obj.grupo_id)
    await manager.send_to_group(
        admin_user.id,
        json.dumps({
            "type": "estado_actualizado",
            "usuario_id": user_db_obj.id,
            "nuevo_estado": user_db_obj.work_state
        })
    )

    return AttendanceRead.model_validate(attendance_dict)
