import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.models.telegram_link import TelegramLink

TELEGRAM_API = "https://api.telegram.org/bot{token}"


class TelegramService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.token = settings.TELEGRAM_BOT_TOKEN
        self.bot_username = ""

    async def _get_bot_info(self) -> dict:
        if not self.token:
            return {}
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(f"{TELEGRAM_API.format(token=self.token)}/getMe")
                data = resp.json()
                if data.get("ok"):
                    self.bot_username = data["result"].get("username", "")
                    return data["result"]
        except Exception:
            pass
        return {}

    async def get_link(self, phone: str) -> TelegramLink | None:
        result = await self.db.execute(
            select(TelegramLink).where(TelegramLink.phone == phone)
        )
        return result.scalar_one_or_none()

    async def link_phone(self, phone: str, chat_id: str) -> TelegramLink:
        link = await self.get_link(phone)
        if link:
            link.chat_id = str(chat_id)
        else:
            link = TelegramLink(phone=phone, chat_id=str(chat_id))
            self.db.add(link)
        await self.db.flush()
        return link

    async def unlink_phone(self, phone: str) -> None:
        link = await self.get_link(phone)
        if link:
            await self.db.delete(link)
            await self.db.flush()

    async def send_message(self, chat_id: str, text: str, reply_markup: dict | None = None) -> bool:
        if not self.token:
            return False
        payload = {"chat_id": chat_id, "text": text}
        if reply_markup:
            payload["reply_markup"] = reply_markup
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(
                    f"{TELEGRAM_API.format(token=self.token)}/sendMessage",
                    json=payload,
                )
                data = resp.json()
                return bool(data.get("ok"))
        except Exception:
            return False

    async def send_otp(self, phone: str, otp: str) -> dict:
        link = await self.get_link(phone)
        if not link:
            return {"delivered": False, "reason": "unlinked", "bot_username": self.bot_username}

        text = (
            f"Your Abdul Ghaffar Meat Shop login code is: <b>{otp}</b>\n"
            "It expires in 5 minutes. Do not share it with anyone."
        )
        ok = await self.send_message(link.chat_id, text, {"parse_mode": "HTML"})
        return {"delivered": ok, "reason": "sent" if ok else "failed", "bot_username": self.bot_username}

    async def handle_update(self, update: dict) -> dict | None:
        message = update.get("message") or {}
        contact = message.get("contact")
        text = (message.get("text") or "").strip()
        chat = message.get("chat") or {}
        chat_id = str(chat.get("id", ""))

        if contact and contact.get("phone_number"):
            phone = contact["phone_number"].replace(" ", "")
            await self.link_phone(phone, chat_id)
            await self.send_message(
                chat_id,
                f"Your phone <b>{phone}</b> is linked. You can now log in to the app.",
                {"parse_mode": "HTML"},
            )
            return {"linked": phone}

        if text == "/start":
            markup = {
                "keyboard": [[{"text": "Share phone number", "request_contact": True}]],
                "resize_keyboard": True,
                "one_time_keyboard": True,
            }
            await self.send_message(
                chat_id,
                "Welcome! To receive your login codes here, tap the button below to share your phone number.",
                markup,
            )
            return {"started": True}

        return None
