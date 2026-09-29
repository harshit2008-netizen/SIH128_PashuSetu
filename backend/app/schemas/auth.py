import uuid

from pydantic import BaseModel, Field

from app.schemas.common import Language


class OtpRequestIn(BaseModel):
    phone: str = Field(pattern=r"^\d{10}$", examples=["9000000002"])


class OtpRequestOut(BaseModel):
    sent: bool
    # Only filled in demo mode, so the login screen can say "OTP is 123456".
    demo_otp: str | None = None


class OtpVerifyIn(BaseModel):
    phone: str = Field(pattern=r"^\d{10}$", examples=["9000000002"])
    otp: str = Field(pattern=r"^\d{4,8}$", examples=["123456"])


class AreaOut(BaseModel):
    id: uuid.UUID
    code: str
    name: dict


class UserOut(BaseModel):
    id: uuid.UUID
    phone: str
    name: str
    role: str
    language: Language
    village: AreaOut | None = None
    block: AreaOut | None = None
    district: AreaOut | None = None


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class DemoAccountOut(BaseModel):
    role: str
    phone: str
    name: str
    language: Language
