from app.schemas.attendance import AttendanceCreate, AttendanceRead
from app.crud.attendance import get_attendances_by_user
from app.api.v1.endpoints.ws_events import manager
from app.crud.attendance import create_attendance
from sqlalchemy.ext.asyncio import AsyncSession
from app.crud.user import get_user_by_id
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy import select, and_
from app.db import models
from app.api import deps
from typing import List
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

@router.get("/", response_model=List[AttendanceRead])
async def get_user_attendances(
    db: AsyncSession = Depends(deps.get_async_db),
    current_user = Depends(deps.get_current_user)
):
    attendances = await get_attendances_by_user(db, user_id=current_user.id)
    return [
        AttendanceRead.model_validate({
            **a.__dict__,
            "type": a.type.value if hasattr(a.type, "value") else a.type
        })
        for a in attendances
    ]

@router.get("/by-group", response_model=List[AttendanceRead])
async def get_group_attendances_today(
    db: AsyncSession = Depends(deps.get_async_db),
    current_user = Depends(deps.get_current_user)
):
    # Obtener usuarios del grupo del admin actual
    group_id = current_user.grupo_id
    users = await db.execute(select(models.User).where(models.User.grupo_id == current_user.id))
    user_ids = [u.id for u in users.scalars().all()]

    # Calcular rango de fecha de hoy (UTC)
    now = datetime.utcnow()
    today_start = datetime(now.year, now.month, now.day)
    today_end = today_start + timedelta(days=1)

    # Traer asistencias de esos usuarios solo del día actual
    result = await db.execute(
        select(models.Attendance)
        .where(
            models.Attendance.user_id.in_(user_ids),
            models.Attendance.timestamp >= today_start,
            models.Attendance.timestamp < today_end
        )
        .order_by(models.Attendance.timestamp.desc())
    )
    attendances = result.scalars().all()
    return [
        AttendanceRead.model_validate({
            **a.__dict__,
            "type": a.type.value if hasattr(a.type, "value") else a.type
        })
        for a in attendances
    ]