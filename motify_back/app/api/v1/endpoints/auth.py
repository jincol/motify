# app/api/v1/endpoints/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Any
from app import crud 
from app.schemas import token as token_schema 
from app.core.security import create_access_token, verify_password
from app.api import deps 

router = APIRouter()

@router.post("/token", response_model=token_schema.Token)
def login_for_access_token(
    db: Session = Depends(deps.get_db), 
    form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests.
    """
    user = crud.user.get_user_by_username(db, username=form_data.username)
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
    return {
        "access_token": access_token,
        "token_type": "bearer",
    }

