# app/schemas/token.py
from pydantic import BaseModel
from typing import Optional

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer" # Siempre es "bearer" para JWT con OAuth2

class TokenPayload(BaseModel): # Renombrado de TokenData para más claridad sobre su propósito
    sub: Optional[str] = None # 'sub' (subject) es el campo estándar para el identificador del usuario (username en nuestro caso)
    # Puedes añadir aquí otros campos que quieras en el payload del token, como:
    # exp: Optional[int] = None # Aunque la librería jose lo maneja, podrías quererlo explícito
    # role: Optional[str] = None # Si quieres incluir el rol en el token para decisiones rápidas en el cliente
