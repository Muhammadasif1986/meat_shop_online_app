from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.order import Order, OrderStatus
from app.models.review import Review
from pydantic import BaseModel

router = APIRouter(prefix="/reviews", tags=["Reviews"])


class CreateReviewRequest(BaseModel):
    order_id: str
    product_id: str
    rating: int
    comment: str | None = None
    images: list[str] = []


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_review(
    request: CreateReviewRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    order_result = await db.execute(
        select(Order).where(
            Order.id == request.order_id,
            Order.user_id == current_user.id,
            Order.status == OrderStatus.delivered,
        )
    )
    order = order_result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=400, detail="Order not found or not yet delivered")

    existing = await db.execute(
        select(Review).where(Review.order_id == request.order_id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Review already submitted for this order")

    review = Review(
        order_id=request.order_id,
        user_id=current_user.id,
        product_id=request.product_id,
        rating=request.rating,
        comment=request.comment,
        images=request.images,
        is_approved=False,
    )
    db.add(review)
    await db.flush()
    return {"success": True, "data": {"id": str(review.id)}}


@router.get("")
async def list_reviews(
    product_id: str = None,
    page: int = 1,
    per_page: int = 20,
    db: AsyncSession = Depends(get_db),
):
    query = select(Review).where(Review.is_approved == True)
    if product_id:
        query = query.where(Review.product_id == product_id)
    query = query.order_by(Review.created_at.desc())

    from sqlalchemy import func
    total_result = await db.execute(select(func.count()).select_from(query.subquery()))
    total = total_result.scalar()

    result = await db.execute(query.offset((page - 1) * per_page).limit(per_page))
    reviews = result.scalars().all()

    return {
        "success": True,
        "data": reviews,
        "meta": {
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": (total + per_page - 1) // per_page,
        },
    }
