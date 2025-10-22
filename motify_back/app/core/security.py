# app/core/security.py
from datetime import datetime, timedelta, timezone
from typing import Any, Union, Optional
from jose import jwt, JWTError
from passlib.context import CryptContext
from app.core.config import settings 


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = settings.ALGORITHM
SECRET_KEY = settings.SECRET_KEY
ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES


def create_access_token(
    subject: Union[str, Any], expires_delta: Optional[timedelta] = None
) -> str:
    """
    Crea un nuevo token de acceso JWT.

    :param subject: El sujeto del token (ej. username o id del usuario).
    :param expires_delta: Tiempo de expiración opcional. Si no se provee,
                          usa ACCESS_TOKEN_EXPIRE_MINUTES de la configuración.
    :return: El token JWT codificado como string.
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verifica una contraseña plana contra su hash.

    :param plain_password: La contraseña en texto plano.
    :param hashed_password: La contraseña hasheada almacenada.
    :return: True si la contraseña coincide, False en caso contrario.
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """
    Genera el hash de una contraseña.

    :param password: La contraseña en texto plano.
    :return: La contraseña hasheada como string.
    """
    return pwd_context.hash(password)


def decode_token_payload(token: str) -> Optional[dict]:
    """
    Decodifica un token JWT y devuelve su payload.
    :param token: El token JWT a decodificar.
    :return: El payload del token como un diccionario, o None si hay un error.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError: #<- me captura el error de token invalido
        return None

def create_refresh_token(
    subject: Union[str, Any], expires_delta: Optional[timedelta] = None
) -> str:
    """
    Crea un refresh token JWT con expiración larga (ej. 7 días).
    """
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(days=7))
    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_refresh_token(token: str) -> Optional[str]:
    """
    Verifica el refresh token y retorna el subject (username/id) si es válido.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            return None
        return payload.get("sub")
    except JWTError:
        return None