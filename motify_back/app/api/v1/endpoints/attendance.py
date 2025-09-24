from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.attendance import AttendanceCreate, AttendanceRead
from app.crud.attendance import create_attendance
from app.api import deps

router = APIRouter()
@router.post("/check-in", response_model=AttendanceRead)
def check_in_attendance(
    attendance_in: AttendanceCreate,
    db: Session = Depends(deps.get_db),
    current_user = Depends(deps.get_current_user)
):
    attendance_obj = create_attendance(db, user_id=current_user.id, attendance_in=attendance_in)
    attendance_obj.type = attendance_obj.type.value
    return AttendanceRead.model_validate(attendance_obj)