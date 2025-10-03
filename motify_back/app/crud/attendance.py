from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models.attendance import Attendance, AttendanceType
from app.schemas.attendance import AttendanceCreate
from sqlalchemy import select

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


async def get_attendances_by_user(db: AsyncSession, user_id: int):
    result = await db.execute(
        select(Attendance).where(Attendance.user_id == user_id).order_by(Attendance.timestamp.desc())
    )
    return result.scalars().all()