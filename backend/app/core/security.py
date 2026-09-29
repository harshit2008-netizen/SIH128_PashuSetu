"""JWT login tokens and role guards.

Login is a demo OTP: when DEMO_MODE is on, the OTP is always DEMO_OTP
(123456) and the login screen says so. Real SMS OTP is out of scope.
"""

import uuid
from collections.abc import Callable
from datetime import UTC, datetime, timedelta

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.db import get_db
from app.core.errors import AppError, forbidden
from app.models import User

ALGORITHM = "HS256"
# Long-lived so a field worker is not logged out in a village with no signal.
TOKEN_LIFETIME = timedelta(days=30)

bearer_scheme = HTTPBearer(auto_error=False, description="Token from POST /api/v1/auth/otp/verify")


def create_access_token(user: User) -> str:
    now = datetime.now(UTC)
    claims = {
        "sub": str(user.id),
        "role": user.role,
        "district_id": str(user.district_id) if user.district_id else None,
        "block_id": str(user.block_id) if user.block_id else None,
        "village_id": str(user.village_id) if user.village_id else None,
        "iat": now,
        "exp": now + TOKEN_LIFETIME,
    }
    return jwt.encode(claims, get_settings().jwt_secret, algorithm=ALGORITHM)


def not_logged_in(message: str = "Please log in again.") -> AppError:
    return AppError(401, "not_authenticated", message)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise not_logged_in("Log in to use this.")
    try:
        claims = jwt.decode(credentials.credentials, get_settings().jwt_secret, algorithms=[ALGORITHM])
        user_id = uuid.UUID(claims["sub"])
    except (jwt.PyJWTError, KeyError, ValueError) as exc:
        raise not_logged_in() from exc
    user = db.get(User, user_id)
    if user is None:
        raise not_logged_in()
    return user


def require_roles(*roles: str) -> Callable[..., User]:
    """Dependency that lets only the given roles through."""

    def guard(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise forbidden()
        return user

    return guard


# Role groups used by the routers.
REPORTERS = ("farmer", "pashu_sevak")
RESPONDERS = ("vet", "district_officer")
ALL_ROLES = ("farmer", "pashu_sevak", "vet", "lab", "district_officer")
