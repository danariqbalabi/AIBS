from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

import jwt
from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient
from jwt.exceptions import PyJWKClientConnectionError

from app.core.errors import ApiError

bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class User:
    id: UUID
    anonymous: bool = False


class JWTVerifier:
    def __init__(self, supabase_url: str):
        self.issuer = supabase_url.rstrip("/") + "/auth/v1"
        self.jwks = PyJWKClient(self.issuer + "/.well-known/jwks.json", timeout=10)

    def verify(self, token: str) -> User:
        try:
            key = self.jwks.get_signing_key_from_jwt(token).key
            claims = jwt.decode(
                token,
                key,
                algorithms=["ES256", "RS256"],
                audience="authenticated",
                issuer=self.issuer,
                options={"require": ["exp", "iat", "sub", "iss", "aud", "role"]},
            )
            if claims["role"] != "authenticated":
                raise jwt.InvalidTokenError("Invalid role")
            return User(UUID(claims["sub"]), claims.get("is_anonymous") is True)
        except PyJWKClientConnectionError as exc:
            raise ApiError(
                503, "auth_unavailable", "Layanan masuk belum tersedia.", retryable=True
            ) from exc
        except (jwt.PyJWTError, ValueError, TypeError, KeyError) as exc:
            raise ApiError(401, "unauthorized", "Silakan masuk kembali.") from exc


def get_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> User:
    if credentials is None:
        raise ApiError(401, "unauthorized", "Silakan masuk terlebih dahulu.")
    return request.app.state.jwt_verifier.verify(credentials.credentials)
