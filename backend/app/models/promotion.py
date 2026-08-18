import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime, Integer, Float
from app.core.database import Base


class Promotion(Base):
    __tablename__ = "promotions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    code = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text)
    description_ur = Column(Text)
    banner_url = Column(String(500))
    banner_url_ur = Column(String(500))
    discount_type = Column(String(20), nullable=False)
    discount_value = Column(Float(), nullable=False)
    min_order_amount = Column(Float(), default=0)
    max_discount = Column(Float())
    max_uses = Column(Integer)
    current_uses = Column(Integer, default=0)
    per_user_limit = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    starts_at = Column(DateTime(timezone=True))
    expires_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
