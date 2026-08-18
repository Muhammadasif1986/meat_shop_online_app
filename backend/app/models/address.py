import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class Address(Base):
    __tablename__ = "addresses"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    label = Column(String(50), default="Home")
    full_address = Column(Text, nullable=False)
    street = Column(String(255))
    sector = Column(String(100))
    house_no = Column(String(50))
    landmark = Column(String(255))
    latitude = Column(Float())
    longitude = Column(Float())
    is_default = Column(Boolean, default=False)
    is_in_service_area = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="addresses")
