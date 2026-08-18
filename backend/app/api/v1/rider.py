from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.user import User
from app.models.order import Order, OrderStatus
from app.services.order import OrderService

router = APIRouter(prefix="/rider", tags=["Rider"])
rider_dep = Depends(require_role("rider"))


@router.get("/orders")
async def rider_orders(
    current_user: User = rider_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order)
        .where(
            Order.rider_id == current_user.id,
            Order.status.in_([OrderStatus.rider_assigned, OrderStatus.out_for_delivery]),
        )
        .order_by(Order.created_at.desc())
    )
    return {"success": True, "data": result.scalars().all()}


@router.patch("/orders/{order_id}/status")
async def rider_update_status(
    order_id: str,
    request: dict,
    current_user: User = rider_dep,
    db: AsyncSession = Depends(get_db),
):
    new_status = request.get("status")
    allowed_transitions = {
        "rider_assigned": ["out_for_delivery", "cancelled"],
        "out_for_delivery": ["delivered", "cancelled"],
    }

    result = await db.execute(
        select(Order).where(Order.id == order_id, Order.rider_id == current_user.id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found or not assigned")

    current = order.status if isinstance(order.status, str) else (order.status.value if order.status else "")
    if new_status not in allowed_transitions.get(current, []):
        raise HTTPException(status_code=400, detail=f"Cannot transition from {current} to {new_status}")

    service = OrderService(db)
    order = await service.update_status(order_id, OrderStatus(new_status), str(current_user.id))
    status = order.status if isinstance(order.status, str) else order.status.value
    return {"success": True, "data": {"id": str(order.id), "status": status}}
