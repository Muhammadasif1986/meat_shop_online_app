from app.core.celery_app import celery_app


@celery_app.task
def clean_expired_carts():
    """Remove carts older than 24 hours."""
    # TODO: DELETE FROM carts WHERE updated_at < NOW() - INTERVAL '24 hours'
    pass
