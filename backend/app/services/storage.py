import uuid
from pathlib import Path
import httpx
from app.core.config import settings

ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


class SupabaseStorage:
    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip("/") if settings.SUPABASE_URL else ""
        self.service_key = settings.SUPABASE_SERVICE_ROLE_KEY

    @property
    def enabled(self) -> bool:
        return bool(self.base_url and self.service_key)

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.service_key}",
            "apikey": self.service_key,
        }

    async def upload_avatar(self, file) -> str:
        if not self.enabled:
            return ""

        ext = ALLOWED_TYPES.get(file.content_type)
        if not ext:
            return ""

        content = await file.read()
        filename = f"{uuid.uuid4().hex}{ext}"

        url = f"{self.base_url}/storage/v1/object/avatars/{filename}"
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                url,
                headers={**self._headers(), "Content-Type": file.content_type},
                content=content,
            )
            if resp.status_code not in (200, 201):
                return ""

        return f"{self.base_url}/storage/v1/object/public/avatars/{filename}"


storage = SupabaseStorage()
