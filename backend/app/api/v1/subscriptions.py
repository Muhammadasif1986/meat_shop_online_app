from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.subscription import Subscription, SubscriptionItem, SubscriptionStatus
from pydantic import BaseModel
from typing import List
from uuid import uuid4

router = APIRouter(prefix="/subscriptions", tags=["Subscriptions"])


class SubscriptionItemCreate(BaseModel):
    product_id: str
    weight_kg: float
    cut_type: str


class CreateSubscriptionRequest(BaseModel):
    plan_name: str
    interval_type: str = "weekly"
    total_cycles: int = 4
    items: List[SubscriptionItemCreate]
    delivery_slot: str
    address_id: str
    start_date: str


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_subscription(
    request: CreateSubscriptionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime
    from app.models.product import Product

    total_per_cycle = 0.0
    sub_items = []
    for item in request.items:
        product_result = await db.execute(select(Product).where(Product.id == item.product_id))
        product = product_result.scalar_one_or_none()
        if not product:
            raise HTTPException(status_code=404, detail=f"Product {item.product_id} not found")
        price = float(product.price_per_kg) * item.weight_kg
        total_per_cycle += price
        sub_items.append(item)

    discount = 0.10 if request.interval_type == "monthly" else 0.0
    total_price = total_per_cycle * request.total_cycles * (1 - discount)

    subscription = Subscription(
        user_id=current_user.id,
        plan_name=request.plan_name,
        interval_type=request.interval_type,
        total_cycles=request.total_cycles,
        cycles_remaining=request.total_cycles,
        price_per_cycle=total_per_cycle,
        total_price=total_price,
        discount_percent=discount * 100,
        next_order_date=datetime.fromisoformat(request.start_date),
        delivery_slot=request.delivery_slot,
        address_id=request.address_id,
        start_date=datetime.fromisoformat(request.start_date),
    )
    db.add(subscription)
    await db.flush()

    for item in sub_items:
        db.add(SubscriptionItem(
            subscription_id=subscription.id,
            product_id=item.product_id,
            weight_kg=item.weight_kg,
            cut_type=item.cut_type,
        ))

    await db.flush()
    return {"success": True, "data": {"id": str(subscription.id)}}


@router.get("")
async def list_subscriptions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Subscription).where(Subscription.user_id == current_user.id)
    )
    subs = result.scalars().all()
    return {"success": True, "data": subs}


@router.patch("/{sub_id}")
async def update_subscription(
    sub_id: str,
    action: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Subscription).where(Subscription.id == sub_id, Subscription.user_id == current_user.id)
    )
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    if action == "pause":
        sub.status = SubscriptionStatus.paused
    elif action == "resume":
        sub.status = SubscriptionStatus.active
    elif action == "cancel":
        sub.status = SubscriptionStatus.cancelled
    else:
        raise HTTPException(status_code=400, detail="Invalid action")

    await db.flush()
    return {"success": True, "message": f"Subscription {action}d"}
