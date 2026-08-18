from app.core.celery_app import celery_app


@celery_app.task
def send_stock_alerts():
    """Check for low stock and send alerts to admin."""
    # TODO: Query products WHERE stock_kg < threshold
    # Send FCM notification to admin users
    pass
