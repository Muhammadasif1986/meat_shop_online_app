from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.order import Order, OrderStatus
from app.schemas.order import CreateOrderRequest, OrderResponse, TrackOrderResponse
from app.services.order import OrderService

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_order(
    request: CreateOrderRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = OrderService(db)
    try:
        order = await service.create_from_cart(
            user_id=str(current_user.id),
            data=request.model_dump(),
        )
        return {"success": True, "data": {"order_id": str(order.id), "order_number": order.order_number}}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("")
async def list_orders(
    page: int = 1,
    per_page: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order)
        .where(Order.user_id == current_user.id)
        .order_by(Order.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    orders = result.scalars().all()
    return {"success": True, "data": orders}


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order).where(Order.id == order_id, Order.user_id == current_user.id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return order


@router.get("/{order_id}/track", response_model=TrackOrderResponse)
async def track_order(
    order_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order).where(Order.id == order_id, Order.user_id == current_user.id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    status_order = [
        "pending", "confirmed", "preparing", "cutting", "packed",
        "rider_assigned", "out_for_delivery", "delivered"
    ]
    order_status = order.status if isinstance(order.status, str) else order.status.value
    current_idx = status_order.index(order_status) if order_status in status_order else 0

    rider_info = None
    if order.rider_id and order.status in [OrderStatus.rider_assigned, OrderStatus.out_for_delivery]:
        rider_result = await db.execute(select(User).where(User.id == order.rider_id))
        rider = rider_result.scalar_one_or_none()
        if rider:
            rider_info = {"name": rider.name, "phone": rider.phone}

    return TrackOrderResponse(
        status=order_status,
        estimated_delivery=order.estimated_delivery_at,
        current_slot=current_idx + 1,
        total_slots=len(status_order),
        statuses=[
            {"status": s, "label": s.replace("_", " ").title()}
            for s in status_order[:current_idx + 1]
        ],
        rider=rider_info,
    )


@router.post("/{order_id}/cancel")
async def cancel_order(
    order_id: str,
    reason: str = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order).where(Order.id == order_id, Order.user_id == current_user.id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.status not in [OrderStatus.pending, OrderStatus.confirmed]:
        raise HTTPException(status_code=400, detail="Order cannot be cancelled at this stage")

    service = OrderService(db)
    await service.update_status(order_id, OrderStatus.cancelled, reason, str(current_user.id))
    return {"success": True, "message": "Order cancelled"}


@router.post("/{order_id}/reorder")
async def reorder(
    order_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order).where(Order.id == order_id, Order.user_id == current_user.id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    from app.models.cart import Cart, CartItem
    cart_result = await db.execute(select(Cart).where(Cart.user_id == current_user.id))
    cart = cart_result.scalar_one_or_none()
    if not cart:
        cart = Cart(user_id=current_user.id)
        db.add(cart)
        await db.flush()

    for item in order.items:
        cart_item = CartItem(
            cart_id=cart.id,
            product_id=item.product_id,
            weight_kg=item.weight_kg,
            cut_type=item.cut_type,
            unit_price=item.unit_price,
            subtotal=item.subtotal,
        )
        db.add(cart_item)

    await db.flush()
    return {"success": True, "message": "Items added to cart"}
