from pathlib import Path
from pydantic_settings import BaseSettings
from typing import List
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

    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_PHONE_NUMBER: str = ""

    TELEGRAM_BOT_TOKEN: str = ""

    RATE_LIMIT_PER_MINUTE: int = 100
    RATE_LIMIT_AUTH_PER_MINUTE: int = 5

    CORS_ORIGINS: List[str] = ["http://localhost:3000"]

    UPLOADS_DIR: Path = UPLOADS_DIR

    class Config:
        env_file = ".env"


settings = Settings()
