from pydantic import BaseModel, Field
from typing import Optional


class SendOTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[1-9]\d{9,14}$")


class VerifyOTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[1-9]\d{9,14}$")
    otp: str = Field(..., min_length=4, max_length=6)


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int
    user: "UserResponse"


class UserResponse(BaseModel):
    id: str
    name: str | None
    phone: str
    role: str
    is_verified: bool
    language_pref: str = "ur"
    avatar_url: str | None = None

    class Config:
        from_attributes = True


class UserUpdateRequest(BaseModel):
    name: str | None = None
    email: str | None = None
    avatar_url: str | None = None
    language_pref: str | None = None
