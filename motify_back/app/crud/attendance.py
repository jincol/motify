from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models.attendance import Attendance, AttendanceType
from app.schemas.attendance import AttendanceCreate

async def create_attendance(db: AsyncSession, user_id: int, attendance_in: AttendanceCreate):
    db_attendance = Attendance(
        user_id=user_id,
        type=AttendanceType(attendance_in.type).value,
        photo_url=attendance_in.photo_url,
        gps_lat=attendance_in.gps_lat,
        gps_lng=attendance_in.gps_lng,
        confirmed=True
    )
    db.add(db_attendance)
    await db.commit()
    await db.refresh(db_attendance)
    return db_attendance