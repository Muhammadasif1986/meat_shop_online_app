import random
import string
from datetime import datetime


def generate_order_number() -> str:
    """Generate unique order number: AGMS-YYYYMMDD-XXXXX"""
    date_part = datetime.now().strftime("%Y%m%d")
    random_part = ''.join(random.choices(string.digits, k=5))
    return f"AGMS-{date_part}-{random_part}"


def calculate_delivery_fee(subtotal: float, free_delivery_threshold: float = 1000.0) -> float:
    if subtotal >= free_delivery_threshold:
        return 0.0
    return 50.0
