from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.attendance import AttendanceCreate, AttendanceRead
from app.crud.attendance import create_attendance
from app.api import deps
from app.db.models.attendance import Attendance
from app.crud.user import get_user_by_id

router = APIRouter()


@router.post("/check-in", response_model=AttendanceRead)
def check_in_attendance(
    attendance_in: AttendanceCreate,
    db: Session = Depends(deps.get_db),
    current_user = Depends(deps.get_current_user)
):
    attendance_obj = create_attendance(db, user_id=current_user.id, attendance_in=attendance_in)
    attendance_dict = attendance_obj.__dict__.copy()
    attendance_dict['type'] = attendance_obj.type.value

    user_db_obj = get_user_by_id(db, current_user.id)
    if attendance_in.type == "check-in":
        user_db_obj.work_state = "JORNADA_ACTIVA"
    elif attendance_in.type == "check-out":
        user_db_obj.work_state = "INACTIVO"
    print(f"DEBUG: Usuario {current_user.id} work_state actualizado a {user_db_obj.work_state}")  
    db.commit()
    db.refresh(user_db_obj)

    return AttendanceRead.model_validate(attendance_dict)
