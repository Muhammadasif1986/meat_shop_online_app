from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


class CartItemCreate(BaseModel):
    product_id: str
    weight_kg: float
    cut_type: str
    custom_instructions: str | None = None


class CartItemUpdate(BaseModel):
    weight_kg: float | None = None
    cut_type: str | None = None
    custom_instructions: str | None = None


class CartItemResponse(BaseModel):
    id: str
    product_id: str
    weight_kg: float
    cut_type: str
    unit_price: float
    subtotal: float
    custom_instructions: str | None

    class Config:
        from_attributes = True


class CartResponse(BaseModel):
    id: str
    items: List[CartItemResponse]
    promo_code: str | None
    discount_amount: float
    subtotal: float
    delivery_fee: float
    total: float

    class Config:
        from_attributes = True


class CreateOrderRequest(BaseModel):
    delivery_address: str | None = None
    address_id: str | None = None
    delivery_notes: str | None = None
    is_asap: bool = True
    scheduled_date: str | None = None
    scheduled_slot: str | None = None
    payment_method: str = "cod"
    items: List[CartItemCreate] = []


class OrderStatusUpdate(BaseModel):
    status: str
    notes: str | None = None


class RiderAssignment(BaseModel):
    rider_id: str


class OrderItemResponse(BaseModel):
    id: str
    product_id: str
    product_name: str
    weight_kg: float
    cut_type: str
    unit_price: float
    subtotal: float
    custom_instructions: str | None

    class Config:
        from_attributes = True


class StatusLogResponse(BaseModel):
    from_status: str | None
    to_status: str
    timestamp: datetime

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: str
    order_number: str
    status: str
    subtotal: float
    delivery_fee: float
    discount: float
    total: float
    payment_method: str
    payment_status: str
    items: List[OrderItemResponse]
    status_logs: List[StatusLogResponse]
    scheduled_date: datetime | None
    scheduled_slot: str | None
    is_asap: bool
    estimated_delivery_at: datetime | None
    rider_id: str | None
    delivery_notes: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class TrackOrderResponse(BaseModel):
    status: str
    estimated_delivery: datetime | None
    current_slot: int
    total_slots: int
    statuses: List[dict]
    rider: dict | None
