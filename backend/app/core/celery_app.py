from celery import Celery
from app.core.config import settings

celery_app = Celery(
    "agms",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.tasks"],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Karachi",
    enable_utc=True,
    task_track_started=True,
    task_soft_time_limit=300,
    beat_schedule={
        "generate-subscription-orders": {
            "task": "app.tasks.subscriptions.generate_subscription_orders",
            "schedule": 86400,  # daily
        },
        "clean-expired-carts": {
            "task": "app.tasks.maintenance.clean_expired_carts",
            "schedule": 3600,  # hourly
        },
        "send-stock-alerts": {
            "task": "app.tasks.inventory.send_stock_alerts",
            "schedule": 1800,  # every 30 min
        },
    },
)
