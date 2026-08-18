import random
from datetime import datetime, timezone, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.security import create_access_token, create_refresh_token
from app.models.user import User, UserRole


class AuthService:
    _dev_otp_store: dict = {}

    def __init__(self, db: AsyncSession):
        self.db = db

    async def send_otp(self, phone: str) -> dict:
        otp = (
            "123456"
            if settings.DEBUG or getattr(settings, "ALLOW_DEBUG_OTP", False)
            else str(random.randint(100000, 999999))
        )

        try:
            from app.core.redis import redis_client
            await redis_client.setex(f"otp:{phone}", 300, otp)
        except Exception:
            AuthService._dev_otp_store[phone] = otp

        if settings.DEBUG or getattr(settings, "ALLOW_DEBUG_OTP", False):
            print(f"[SMS] OTP for {phone}: {otp}")
            return {"expires_in": 300, "delivered": True, "reason": "debug"}

        from app.services.telegram import TelegramService
        result = await TelegramService(self.db).send_otp(phone, otp)

        return {"expires_in": 300, **result}

    async def verify_otp(self, phone: str, otp: str) -> dict:
        stored = None
        redis_available = False
        try:
            from app.core.redis import redis_client
            stored = await redis_client.get(f"otp:{phone}")
            if isinstance(stored, bytes):
                stored = stored.decode()
            redis_available = True
        except Exception:
            stored = AuthService._dev_otp_store.pop(phone, None)

        if not stored or stored != otp:
            return None

        if redis_available:
            await redis_client.delete(f"otp:{phone}")

        # Find or create user
        result = await self.db.execute(select(User).where(User.phone == phone))
        user = result.scalar_one_or_none()

        if not user:
            user = User(phone=phone, role=UserRole.customer, is_verified=True)
            self.db.add(user)
            await self.db.flush()
        else:
            user.is_verified = True

        tokens = self._generate_tokens(user)
        return {
            "access_token": tokens["access_token"],
            "refresh_token": tokens["refresh_token"],
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            "user": {
                "id": str(user.id),
                "name": user.name,
                "phone": user.phone,
                "role": user.role if isinstance(user.role, str) else user.role.value,
                "is_verified": user.is_verified,
                "language_pref": user.language_pref or "ur",
                "avatar_url": user.avatar_url,
            },
        }

    def _generate_tokens(self, user: User) -> dict:
        role = user.role if isinstance(user.role, str) else user.role.value
        payload = {"sub": str(user.id), "phone": user.phone, "role": role}
        return {
            "access_token": create_access_token(payload),
            "refresh_token": create_refresh_token(payload),
        }

    async def refresh_token(self, refresh_token: str) -> dict:
        from app.core.security import decode_token
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            return None

        result = await self.db.execute(
            select(User).where(User.id == payload.get("sub"))
        )
        user = result.scalar_one_or_none()
        if not user or not user.is_active:
            return None

        tokens = self._generate_tokens(user)
        return {
            "access_token": tokens["access_token"],
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        }
