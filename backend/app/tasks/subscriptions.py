from app.core.celery_app import celery_app


@celery_app.task
def generate_subscription_orders():
    """Generate recurring orders for active subscriptions due today."""
    # TODO: Query active subscriptions where next_order_date == today
    # Create orders from subscription items
    # Update next_order_date
    # Send notifications
    pass
