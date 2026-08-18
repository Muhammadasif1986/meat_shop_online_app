from pathlib import Path
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List
import json
import os

BACKEND_DIR = Path(__file__).resolve().parents[2]
UPLOADS_DIR = BACKEND_DIR.parent / "uploads"


class Settings(BaseSettings):
    APP_NAME: str = "Abdul Ghaffar Meat Shop API"
    DEBUG: bool = False
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    DATABASE_URL: str
    DATABASE_URL_SYNC: str

    REDIS_URL: str = "redis://localhost:6379/0"
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/1"

    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_PHONE_NUMBER: str = ""

    TELEGRAM_BOT_TOKEN: str = ""

    RATE_LIMIT_PER_MINUTE: int = 100
    RATE_LIMIT_AUTH_PER_MINUTE: int = 5

    cors_origins: str = "http://localhost:3000"

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        return v

    @property
    def CORS_ORIGINS(self) -> List[str]:
        raw = self.cors_origins
        if isinstance(raw, str):
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, list):
                    return parsed
            except (json.JSONDecodeError, TypeError):
                pass
            return [o.strip() for o in raw.split(",") if o.strip()]
        return raw

    UPLOADS_DIR: Path = UPLOADS_DIR

    class Config:
        env_file = ".env"


settings = Settings()
