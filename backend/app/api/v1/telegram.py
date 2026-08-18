import httpx
from fastapi import APIRouter, Depends, Request, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.database import get_db
from app.services.telegram import TelegramService

router = APIRouter(prefix="/telegram", tags=["Telegram"])


@router.post("/webhook")
async def telegram_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    if not settings.TELEGRAM_BOT_TOKEN:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Telegram not configured")

    update = await request.json()
    await TelegramService(db).handle_update(update)
    await db.flush()
    return {"success": True}


@router.post("/set-webhook")
async def set_webhook(request: Request):
    if not settings.TELEGRAM_BOT_TOKEN:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Telegram not configured")

    body = await request.json()
    url = body.get("url")
    if not url:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="url is required")

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/setWebhook",
            json={"url": url},
        )
        data = resp.json()

    if not data.get("ok"):
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=data.get("description"))

    return {"success": True, "data": data.get("result")}


@router.get("/status")
async def telegram_status(db: AsyncSession = Depends(get_db)):
    if not settings.TELEGRAM_BOT_TOKEN:
        return {"configured": False}

    service = TelegramService(db)
    info = await service._get_bot_info()
    return {"configured": True, "bot": info}
