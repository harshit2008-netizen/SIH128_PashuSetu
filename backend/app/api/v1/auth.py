"""Demo OTP login and the logged-in user's profile."""

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import create_access_token, get_current_user
from app.models import Block, District, User, Village
from app.schemas.auth import DemoAccountOut, OtpRequestIn, OtpRequestOut, OtpVerifyIn, TokenOut, UserOut

router = APIRouter(tags=["auth"])

# One fixed account per role, shown on the demo role picker (seeded by make seed).
DEMO_PHONES = {"farmer": "9000000001", "pashu_sevak": "9000000002", "vet": "9000000003",
               "lab": "9000000004", "district_officer": "9000000005"}


def area(row) -> dict | None:
    return {"id": row.id, "code": row.code, "name": row.name} if row else None


def user_out(db: Session, user: User) -> dict:
    return {
        "id": user.id, "phone": user.phone, "name": user.name, "role": user.role, "language": user.language,
        "village": area(db.get(Village, user.village_id) if user.village_id else None),
        "block": area(db.get(Block, user.block_id) if user.block_id else None),
        "district": area(db.get(District, user.district_id) if user.district_id else None),
    }


def find_user(db: Session, phone: str) -> User:
    user = db.scalar(select(User).where(User.phone == phone))
    if user is None:
        # No self-registration in this prototype (spec: out of scope).
        raise AppError(404, "unknown_phone", "This number is not registered. Ask your pashu sevak or vet.")
    return user


@router.get("/auth/demo-accounts", response_model=list[DemoAccountOut])
def demo_accounts(db: Session = Depends(get_db)):
    """The fixed demo account for each role. Empty when DEMO_MODE is off."""
    if not get_settings().demo_mode:
        return []
    users = db.scalars(select(User).where(User.phone.in_(DEMO_PHONES.values()))).all()
    order = list(DEMO_PHONES.values())
    return sorted(users, key=lambda u: order.index(u.phone))


@router.post("/auth/otp/request", response_model=OtpRequestOut)
def request_otp(body: OtpRequestIn, db: Session = Depends(get_db)):
    find_user(db, body.phone)
    settings = get_settings()
    if not settings.demo_mode:
        raise AppError(501, "sms_not_configured", "SMS OTP is not set up. Turn on DEMO_MODE for the demo.")
    return {"sent": True, "demo_otp": settings.demo_otp}


@router.post("/auth/otp/verify", response_model=TokenOut)
def verify_otp(body: OtpVerifyIn, db: Session = Depends(get_db)):
    user = find_user(db, body.phone)
    settings = get_settings()
    if not settings.demo_mode or body.otp != settings.demo_otp:
        raise AppError(401, "wrong_otp", "That OTP is not right. Check it and try again.")
    return {"access_token": create_access_token(user), "user": user_out(db, user)}


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return user_out(db, user)
