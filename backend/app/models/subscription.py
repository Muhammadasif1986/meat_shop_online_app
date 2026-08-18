import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime, Integer, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class SubscriptionStatus:
    active = "active"
    paused = "paused"
    cancelled = "cancelled"
    expired = "expired"


class SubscriptionInterval:
    weekly = "weekly"
    biweekly = "biweekly"
    monthly = "monthly"


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    plan_name = Column(String(100), nullable=False)
    description = Column(Text)
    interval_type = Column(String(50), default=SubscriptionInterval.weekly)
    interval_count = Column(Integer, default=1)
    total_cycles = Column(Integer)
    cycles_remaining = Column(Integer)
    price_per_cycle = Column(Float(), nullable=False)
    total_price = Column(Float(), nullable=False)
    discount_percent = Column(Float(), default=0)
    status = Column(String(50), default=SubscriptionStatus.active)
    next_order_date = Column(DateTime(timezone=True), nullable=False)
    delivery_slot = Column(String(50))
    delivery_notes = Column(Text)
    auto_renew = Column(Boolean, default=False)
    address_id = Column(String(36), ForeignKey("addresses.id"), nullable=False)
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True))
    cancelled_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="subscriptions")
    items = relationship("SubscriptionItem", back_populates="subscription", cascade="all, delete-orphan")


class SubscriptionItem(Base):
    __tablename__ = "subscription_items"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    subscription_id = Column(String(36), ForeignKey("subscriptions.id"), nullable=False)
    product_id = Column(String(36), ForeignKey("products.id"), nullable=False)
    weight_kg = Column(Float(), nullable=False)
    cut_type = Column(String(50), nullable=False)

    subscription = relationship("Subscription", back_populates="items")
