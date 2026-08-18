import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, Integer, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class OrderStatus:
    pending = "pending"
    confirmed = "confirmed"
    preparing = "preparing"
    cutting = "cutting"
    packed = "packed"
    rider_assigned = "rider_assigned"
    out_for_delivery = "out_for_delivery"
    delivered = "delivered"
    cancelled = "cancelled"


class PaymentMethod:
    cod = "cod"
    card = "card"
    wallet = "wallet"
    jazzcash = "jazzcash"
    easypaisa = "easypaisa"


class PaymentStatus:
    pending = "pending"
    paid = "paid"
    failed = "failed"
    refunded = "refunded"


class Order(Base):
    __tablename__ = "orders"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_number = Column(String(20), unique=True, nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    address_id = Column(String(36), ForeignKey("addresses.id"), nullable=False)
    status = Column(String(50), default=OrderStatus.pending, index=True)
    subtotal = Column(Float(), nullable=False)
    delivery_fee = Column(Float(), default=0)
    discount = Column(Float(), default=0)
    total = Column(Float(), nullable=False)
    payment_method = Column(String(50), default=PaymentMethod.cod)
    payment_status = Column(String(50), default=PaymentStatus.pending)
    delivery_notes = Column(Text)
    scheduled_date = Column(DateTime(timezone=True))
    scheduled_slot = Column(String(50))
    is_asap = Column(Boolean, default=True)
    estimated_delivery_at = Column(DateTime(timezone=True))
    delivered_at = Column(DateTime(timezone=True))
    rider_id = Column(String(36), ForeignKey("users.id"))
    preparation_time_min = Column(Integer)
    cancellation_reason = Column(Text)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="orders", foreign_keys="Order.user_id")
    address = relationship("Address", foreign_keys="Order.address_id")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    status_logs = relationship("OrderStatusLog", back_populates="order", cascade="all, delete-orphan")
    review = relationship("Review", back_populates="order", uselist=False)


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String(36), ForeignKey("orders.id"), nullable=False)
    product_id = Column(String(36), ForeignKey("products.id"), nullable=False)
    product_name = Column(String(200), nullable=False)
    weight_kg = Column(Float(), nullable=False)
    cut_type = Column(String(50), nullable=False)
    unit_price = Column(Float(), nullable=False)
    subtotal = Column(Float(), nullable=False)
    custom_instructions = Column(Text)

    order = relationship("Order", back_populates="items")


class OrderStatusLog(Base):
    __tablename__ = "order_status_log"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String(36), ForeignKey("orders.id"), nullable=False)
    from_status = Column(String(50))
    to_status = Column(String(50), nullable=False)
    changed_by = Column(String(36), ForeignKey("users.id"))
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    order = relationship("Order", back_populates="status_logs")
