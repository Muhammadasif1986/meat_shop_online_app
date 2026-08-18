import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime, Integer, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class MeatCategory:
    beef = "beef"
    chicken = "chicken"
    mutton = "mutton"


class CutType:
    curry_cut = "curry_cut"
    bbq_cut = "bbq_cut"
    boneless = "boneless"
    mince = "mince"
    custom = "custom"


class Category(Base):
    __tablename__ = "categories"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)
    name_ur = Column(String(100))
    slug = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text)
    description_ur = Column(Text)
    image_url = Column(String(500))
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    products = relationship("Product", back_populates="category")


class Product(Base):
    __tablename__ = "products"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    category_id = Column(String(36), ForeignKey("categories.id"), nullable=False)
    name = Column(String(200), nullable=False)
    name_ur = Column(String(200))
    slug = Column(String(200), unique=True, nullable=False, index=True)
    description = Column(Text)
    description_ur = Column(Text)
    price_per_kg = Column(Float(), nullable=False)
    compare_price = Column(Float())
    stock_kg = Column(Float(), default=0)
    min_order_kg = Column(Float(), default=0.5)
    max_order_kg = Column(Float(), default=5.0)
    images = Column(Text(), default="[]")
    freshness_status = Column(String(50), default="Fresh")
    is_featured = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    cut_options = Column(Text())
    stock_updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    category = relationship("Category", back_populates="products")
