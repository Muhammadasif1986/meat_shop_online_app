from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token
from app.schemas.auth import SendOTPRequest, VerifyOTPRequest, RefreshTokenRequest, UserUpdateRequest, UserResponse
from app.models.user import User, UserRole
from app.services.auth import AuthService
from app.services.storage import storage, ALLOWED_TYPES


class AdminLoginRequest(BaseModel):
    email: str
    password: str

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/admin/login")
async def admin_login(request: AdminLoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == request.email, User.hashed_password.isnot(None))
    )
    user = result.scalar_one_or_none()
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if user.role not in ("admin", "superadmin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    tokens = _generate_admin_tokens(user)
    return {"success": True, "data": tokens}


def _generate_admin_tokens(user: User) -> dict:
    role = user.role if isinstance(user.role, str) else user.role.value
    payload = {"sub": str(user.id), "email": user.email, "role": role}
    return {
        "token": create_access_token(payload),
        "refresh_token": create_refresh_token(payload),
        "expires_in": 3600,
        "user": {
            "id": str(user.id),
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "role": role,
        },
    }


@router.post("/send-otp")
async def send_otp(request: SendOTPRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    result = await service.send_otp(request.phone)
    return {"success": True, "message": "OTP sent", "data": result}


@router.post("/verify-otp")
async def verify_otp(request: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    result = await service.verify_otp(request.phone, request.otp)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired OTP",
        )
    return {"success": True, "data": result}


@router.post("/refresh")
async def refresh_token(request: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    result = await service.refresh_token(request.refresh_token)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )
    return {"success": True, "data": result}


@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user)):
    # Invalidate tokens (add to blacklist in Redis for production)
    return {"success": True, "message": "Logged out"}


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me")
async def update_profile(
    request: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if request.name is not None:
        current_user.name = request.name
    if request.email is not None:
        current_user.email = request.email
    if request.avatar_url is not None:
        current_user.avatar_url = request.avatar_url
    if request.language_pref is not None:
        current_user.language_pref = request.language_pref
    await db.flush()
    return {"success": True, "data": current_user}


@router.post("/me/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only JPG, PNG, WEBP or GIF images are allowed")

    if storage.enabled:
        avatar_url = await storage.upload_avatar(file)
        if not avatar_url:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to upload avatar")
    else:
        from app.core.config import UPLOADS_DIR
        from pathlib import Path
        import uuid, shutil

        upload_dir = UPLOADS_DIR / "avatars"
        upload_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{uuid.uuid4().hex}{ALLOWED_TYPES[file.content_type]}"
        dest = upload_dir / filename
        with dest.open("wb") as out:
            shutil.copyfileobj(file.file, out)
        avatar_url = f"/uploads/avatars/{filename}"

    current_user.avatar_url = avatar_url
    await db.flush()

    return {
        "success": True,
        "data": {
            "avatar_url": current_user.avatar_url,
            "user": current_user,
        },
    }
