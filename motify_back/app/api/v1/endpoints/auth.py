# app/api/v1/endpoints/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any
from app import crud 
from fastapi import Body
from app.schemas import token as token_schema 
from app.core.security import create_access_token, verify_password, create_refresh_token, verify_refresh_token

from app.api import deps 

router = APIRouter()

@router.post("/token", response_model=token_schema.Token)
async def login_for_access_token(
    db: AsyncSession = Depends(deps.get_async_db),
    form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests.
    """
    user = await crud.user.get_user_by_username(db, username=form_data.username)
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    access_token = create_access_token(
        subject=user.username
    )
    refresh_token = create_refresh_token(subject=user.username)

    return {
    "access_token": access_token,
    "refresh_token": refresh_token,
    "token_type": "bearer",
}


@router.post("/refresh", response_model=token_schema.Token)
async def refresh_access_token(
    refresh_token: str = Body(..., embed=True)
):
    username = verify_refresh_token(refresh_token)
    if not username:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    access_token = create_access_token(subject=username)
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,  # puedes emitir uno nuevo si quieres rotar
        "token_type": "bearer",
    }