from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notification import Notification


class NotificationService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def send(self, user_id: str, title: str, body: str, type: str = None, ref_id: str = None):
        notification = Notification(
            user_id=user_id,
            title=title,
            body=body,
            type=type,
            ref_id=ref_id,
        )
        self.db.add(notification)
        await self.db.flush()

        # TODO: Send FCM push notification
        # firebase_messaging.send(...)

        return notification
