from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, case, delete
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone, timedelta
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.user import User
from app.models.order import Order, OrderStatus
from app.models.product import Product, Category
from app.models.review import Review
from app.models.promotion import Promotion
from app.services.order import OrderService
from pydantic import BaseModel

router = APIRouter(prefix="/admin", tags=["Admin"])
admin_dep = Depends(require_role("admin"))


# ─── Dashboard ───

@router.get("/dashboard/stats")
async def dashboard_stats(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    today_orders = await db.execute(
        select(func.count()).where(Order.created_at >= today)
    )
    today_revenue = await db.execute(
        select(func.coalesce(func.sum(Order.total), 0)).where(
            Order.created_at >= today,
            Order.status.in_([OrderStatus.delivered, OrderStatus.out_for_delivery, OrderStatus.packed]),
        )
    )
    total_customers = await db.execute(
        select(func.count()).where(User.role == "customer")
    )
    pending = await db.execute(
        select(func.count()).where(Order.status == OrderStatus.pending)
    )

    return {
        "success": True,
        "data": {
            "today_orders": today_orders.scalar(),
            "today_revenue": float(today_revenue.scalar()),
            "total_customers": total_customers.scalar(),
            "pending_orders": pending.scalar(),
        },
    }


# ─── Orders ───

@router.get("/orders")
async def admin_list_orders(
    status: str = None,
    today: bool = False,
    page: int = 1,
    per_page: int = 50,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.address import Address

    query = (
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.user),
            selectinload(Order.address),
        )
        .order_by(Order.created_at.desc())
    )
    if status:
        query = query.where(Order.status == status)
    if today:
        start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.where(Order.created_at >= start)

    total = await db.execute(select(func.count()).select_from(query.subquery()))
    result = await db.execute(query.offset((page - 1) * per_page).limit(per_page))
    orders = result.scalars().all()

    data = []
    for order in orders:
        item_data = []
        for item in order.items:
            item_data.append({
                "id": str(item.id),
                "product_id": str(item.product_id),
                "product_name": item.product_name,
                "weight_kg": item.weight_kg,
                "cut_type": item.cut_type,
                "unit_price": item.unit_price,
                "subtotal": item.subtotal,
                "custom_instructions": item.custom_instructions,
            })
        user = order.user
        addr = order.address
        data.append({
            "id": str(order.id),
            "order_number": order.order_number,
            "status": order.status,
            "subtotal": order.subtotal,
            "delivery_fee": order.delivery_fee,
            "discount": order.discount,
            "total": order.total,
            "payment_method": order.payment_method,
            "payment_status": order.payment_status,
            "delivery_notes": order.delivery_notes,
            "created_at": order.created_at,
            "updated_at": order.updated_at,
            "user_id": str(order.user_id) if order.user_id else None,
            "user": {
                "id": str(user.id) if user else None,
                "name": user.name if user else None,
                "phone": user.phone if user else None,
            } if user else None,
            "address": {
                "id": str(addr.id) if addr else None,
                "full_address": addr.full_address if addr else None,
                "label": addr.label if addr else None,
                "street": addr.street if addr else None,
                "sector": addr.sector if addr else None,
                "landmark": addr.landmark if addr else None,
            } if addr else None,
            "items": item_data,
        })

    return {"success": True, "data": data, "total": total.scalar()}


@router.patch("/orders/{order_id}/status")
async def admin_update_status(
    order_id: str,
    request: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    new_status = request.get("status")
    notes = request.get("notes")
    valid_statuses = [
        OrderStatus.pending, OrderStatus.confirmed, OrderStatus.preparing,
        OrderStatus.cutting, OrderStatus.packed, OrderStatus.rider_assigned,
        OrderStatus.out_for_delivery, OrderStatus.delivered, OrderStatus.cancelled,
    ]
    if new_status not in valid_statuses:
        raise HTTPException(status_code=400, detail="Invalid status")
    service = OrderService(db)
    order = await service.update_status(order_id, new_status, notes, str(current_user.id))
    status = order.status if isinstance(order.status, str) else order.status.value
    return {"success": True, "data": {"id": str(order.id), "status": status}}


@router.post("/orders/{order_id}/assign-rider")
async def assign_rider(
    order_id: str,
    request: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    rider_id = request.get("rider_id")
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    rider_result = await db.execute(
        select(User).where(User.id == rider_id, User.role == "rider")
    )
    if not rider_result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Invalid rider")

    order.rider_id = rider_id
    service = OrderService(db)
    await service.update_status(order_id, OrderStatus.rider_assigned, f"Rider assigned", str(current_user.id))
    return {"success": True}


@router.delete("/orders/{order_id}")
async def admin_delete_order(
    order_id: str,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.order import OrderItem, OrderStatusLog
    from app.models.review import Review

    result = await db.execute(
        select(Order).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    await db.execute(delete(OrderStatusLog).where(OrderStatusLog.order_id == order_id))
    await db.execute(delete(OrderItem).where(OrderItem.order_id == order_id))
    await db.execute(delete(Review).where(Review.order_id == order_id))
    await db.execute(delete(Order).where(Order.id == order_id))
    await db.commit()
    return {"success": True, "message": "Order deleted"}


# ─── Products ───

@router.get("/products")
async def admin_list_products(
    page: int = 1,
    per_page: int = 50,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Product).order_by(Product.created_at.desc())
        .offset((page - 1) * per_page).limit(per_page)
    )
    return {"success": True, "data": result.scalars().all()}


@router.post("/products")
async def admin_create_product(
    data: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    import re as _re
    payload = dict(data)
    name = (payload.get("name") or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Product name is required")

    slug = (payload.get("slug") or "").strip()
    if not slug:
        base = _re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        slug = base or "product"

    existing = (await db.execute(select(Product).where(Product.slug == slug))).scalar_one_or_none()
    if existing:
        suffix = 2
        while True:
            candidate = f"{slug}-{suffix}"
            dup = (await db.execute(select(Product).where(Product.slug == candidate))).scalar_one_or_none()
            if not dup:
                slug = candidate
                break
            suffix += 1
    payload["slug"] = slug

    if not payload.get("images"):
        payload["images"] = "[]"
    if not payload.get("cut_options"):
        payload["cut_options"] = "[]"
    if not payload.get("freshness_status"):
        payload["freshness_status"] = "Fresh"
    if payload.get("stock_kg") is not None and "stock_updated_at" not in payload:
        payload["stock_updated_at"] = datetime.now(timezone.utc)

    product = Product(**payload)
    db.add(product)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Could not create product: duplicate or invalid data")
    return {"success": True, "data": {"id": str(product.id)}}


@router.patch("/products/{product_id}")
async def admin_update_product(
    product_id: str,
    data: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    for key, value in data.items():
        if hasattr(product, key):
            setattr(product, key, value)
    await db.flush()
    return {"success": True}


@router.delete("/products/{product_id}")
async def admin_delete_product(
    product_id: str,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.order import OrderItem

    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    await db.execute(delete(OrderItem).where(OrderItem.product_id == product_id))
    await db.delete(product)
    await db.flush()
    return {"success": True}


@router.patch("/products/{product_id}/stock")
async def admin_update_stock(
    product_id: str,
    data: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    product.stock_kg = data.get("stock_kg", product.stock_kg)
    await db.flush()
    return {"success": True}


# ─── Categories ───

@router.get("/categories")
async def admin_list_categories(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).order_by(Category.sort_order))
    return {"success": True, "data": result.scalars().all()}


@router.post("/categories")
async def admin_create_category(
    data: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    cat = Category(**data)
    db.add(cat)
    await db.flush()
    return {"success": True, "data": {"id": str(cat.id)}}


# ─── Customers ───

@router.get("/customers")
async def admin_list_customers(
    page: int = 1,
    per_page: int = 50,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    order_stats = (
        select(
            Order.user_id,
            func.count(Order.id).label("total_orders"),
            func.max(Order.created_at).label("last_order_at"),
            func.coalesce(func.sum(Order.total), 0).label("total_spent"),
        )
        .group_by(Order.user_id)
        .subquery()
    )

    result = await db.execute(
        select(User, order_stats.c.total_orders, order_stats.c.last_order_at, order_stats.c.total_spent)
        .outerjoin(order_stats, User.id == order_stats.c.user_id)
        .where(User.role == "customer")
        .order_by(User.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    rows = result.all()
    customers = [
        {
            "id": str(u.id),
            "name": u.name or "",
            "phone": u.phone,
            "email": u.email or "",
            "is_active": u.is_active,
            "is_verified": u.is_verified,
            "language_pref": u.language_pref,
            "created_at": u.created_at,
            "total_orders": total_orders or 0,
            "last_order_at": last_order_at,
            "total_spent": float(total_spent or 0),
        }
        for u, total_orders, last_order_at, total_spent in rows
    ]
    return {"success": True, "data": customers}


# ─── Reviews ───

@router.get("/reviews")
async def admin_list_reviews(
    page: int = 1,
    per_page: int = 50,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Review).order_by(Review.created_at.desc())
        .offset((page - 1) * per_page).limit(per_page)
    )
    return {"success": True, "data": result.scalars().all()}


@router.patch("/reviews/{review_id}/approve")
async def admin_approve_review(
    review_id: str,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Review).where(Review.id == review_id))
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    review.is_approved = True
    await db.flush()
    return {"success": True}


# ─── Promotions ───

@router.get("/promotions")
async def admin_list_promotions(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Promotion).order_by(Promotion.created_at.desc()))
    return {"success": True, "data": result.scalars().all()}


@router.post("/promotions")
async def admin_create_promotion(
    data: dict,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    promo = Promotion(**data)
    db.add(promo)
    await db.flush()
    return {"success": True, "data": {"id": str(promo.id)}}


# ─── Analytics ───

@router.get("/analytics/sales")
async def analytics_sales(
    days: int = 30,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    since = datetime.now(timezone.utc) - timedelta(days=days)
    date_col = func.date(Order.created_at)
    result = await db.execute(
        select(
            date_col.label("date"),
            func.count(Order.id).label("orders"),
            func.sum(Order.total).label("revenue"),
        )
        .where(Order.created_at >= since)
        .group_by(date_col)
        .order_by("date")
    )
    rows = result.all()
    return {
        "success": True,
        "data": [
            {"date": str(r.date.date()), "orders": r.orders, "revenue": float(r.revenue or 0)}
            for r in rows
        ],
    }


@router.get("/analytics/top-products")
async def analytics_top_products(
    days: int = 30,
    limit: int = 10,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.order import OrderItem
    since = datetime.now(timezone.utc) - timedelta(days=days)
    result = await db.execute(
        select(
            OrderItem.product_name,
            func.sum(OrderItem.weight_kg).label("total_kg"),
            func.sum(OrderItem.subtotal).label("total_sales"),
            func.count(OrderItem.id).label("order_count"),
        )
        .join(Order, OrderItem.order_id == Order.id)
        .where(Order.created_at >= since)
        .group_by(OrderItem.product_name)
        .order_by(func.sum(OrderItem.subtotal).desc())
        .limit(limit)
    )
    return {"success": True, "data": [dict(r._mapping) for r in result.all()]}


# ─── Translations / Multilingual Content ───


@router.get("/translations/products")
async def admin_list_product_translations(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(
            Product.id,
            Product.name,
            Product.name_ur,
            Product.description,
            Product.description_ur,
            Product.slug,
        ).order_by(Product.created_at.desc())
    )
    rows = result.all()
    return {
        "success": True,
        "data": [
            {
                "id": r.id,
                "name_en": r.name,
                "name_ur": r.name_ur or "",
                "description_en": r.description or "",
                "description_ur": r.description_ur or "",
                "slug": r.slug,
            }
            for r in rows
        ],
    }


class TranslationUpdateRequest(BaseModel):
    name_en: str | None = None
    name_ur: str | None = None
    description_en: str | None = None
    description_ur: str | None = None


@router.patch("/translations/products/{product_id}")
async def admin_update_product_translation(
    product_id: str,
    data: TranslationUpdateRequest,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    if data.name_en is not None:
        product.name = data.name_en
    if data.name_ur is not None:
        product.name_ur = data.name_ur
    if data.description_en is not None:
        product.description = data.description_en
    if data.description_ur is not None:
        product.description_ur = data.description_ur
    await db.flush()
    return {"success": True}


@router.get("/translations/categories")
async def admin_list_category_translations(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).order_by(Category.sort_order))
    cats = result.scalars().all()
    return {
        "success": True,
        "data": [
            {
                "id": c.id,
                "name_en": c.name,
                "name_ur": c.name_ur or "",
                "description_en": c.description or "",
                "description_ur": c.description_ur or "",
                "slug": c.slug,
            }
            for c in cats
        ],
    }


@router.patch("/translations/categories/{category_id}")
async def admin_update_category_translation(
    category_id: str,
    data: TranslationUpdateRequest,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    if data.name_en is not None:
        cat.name = data.name_en
    if data.name_ur is not None:
        cat.name_ur = data.name_ur
    if data.description_en is not None:
        cat.description = data.description_en
    if data.description_ur is not None:
        cat.description_ur = data.description_ur
    await db.flush()
    return {"success": True}


class PromotionTranslationUpdateRequest(BaseModel):
    description_en: str | None = None
    description_ur: str | None = None
    banner_url: str | None = None
    banner_url_ur: str | None = None


@router.get("/translations/promotions")
async def admin_list_promotion_translations(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Promotion).order_by(Promotion.created_at.desc()))
    promos = result.scalars().all()
    return {
        "success": True,
        "data": [
            {
                "id": p.id,
                "code": p.code,
                "description_en": p.description or "",
                "description_ur": p.description_ur or "",
                "banner_url": p.banner_url or "",
                "banner_url_ur": p.banner_url_ur or "",
            }
            for p in promos
        ],
    }


@router.patch("/translations/promotions/{promotion_id}")
async def admin_update_promotion_translation(
    promotion_id: str,
    data: PromotionTranslationUpdateRequest,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Promotion).where(Promotion.id == promotion_id))
    promo = result.scalar_one_or_none()
    if not promo:
        raise HTTPException(status_code=404, detail="Promotion not found")
    if data.description_en is not None:
        promo.description = data.description_en
    if data.description_ur is not None:
        promo.description_ur = data.description_ur
    if data.banner_url is not None:
        promo.banner_url = data.banner_url
    if data.banner_url_ur is not None:
        promo.banner_url_ur = data.banner_url_ur
    await db.flush()
    return {"success": True}


# ─── Riders ───

class RiderCreateRequest(BaseModel):
    name: str
    phone: str
    email: str | None = None


@router.get("/riders")
async def admin_list_riders(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).where(User.role == "rider").order_by(User.created_at.desc())
    )
    riders = result.scalars().all()
    return {"success": True, "data": riders}


@router.post("/riders")
async def admin_create_rider(
    data: RiderCreateRequest,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.core.security import hash_password
    rider = User(
        name=data.name,
        phone=data.phone,
        email=data.email,
        role="rider",
        is_verified=True,
        is_active=True,
        hashed_password=hash_password("Rider123!"),
    )
    db.add(rider)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="A rider with this phone number already exists")
    return {"success": True, "data": {"id": str(rider.id)}}


@router.patch("/riders/{rider_id}/toggle-active")
async def admin_toggle_rider_active(
    rider_id: str,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == rider_id, User.role == "rider"))
    rider = result.scalar_one_or_none()
    if not rider:
        raise HTTPException(status_code=404, detail="Rider not found")
    rider.is_active = not rider.is_active
    await db.flush()
    return {"success": True, "data": {"id": rider_id, "is_active": rider.is_active}}


@router.delete("/riders/{rider_id}")
async def admin_delete_rider(
    rider_id: str,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == rider_id, User.role == "rider"))
    rider = result.scalar_one_or_none()
    if not rider:
        raise HTTPException(status_code=404, detail="Rider not found")
    await db.delete(rider)
    await db.flush()
    return {"success": True}


# ─── Subscriptions ───

@router.get("/subscriptions")
async def admin_list_subscriptions(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.subscription import Subscription
    result = await db.execute(select(Subscription).order_by(Subscription.created_at.desc()))
    subs = result.scalars().all()
    return {"success": True, "data": subs}


# ─── Notifications ───

class AdminNotificationRequest(BaseModel):
    title: str
    title_ur: str | None = None
    body: str
    body_ur: str | None = None
    user_id: str | None = None
    type: str = "admin"


@router.post("/notifications/send")
async def admin_send_notification(
    data: AdminNotificationRequest,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.notification import Notification
    if data.user_id:
        notif = Notification(
            user_id=data.user_id,
            title=data.title,
            title_ur=data.title_ur or data.title,
            body=data.body,
            body_ur=data.body_ur or data.body,
            type=data.type,
        )
        db.add(notif)
    else:
        result = await db.execute(select(User).where(User.role == "customer"))
        users = result.scalars().all()
        for u in users:
            db.add(Notification(
                user_id=u.id,
                title=data.title,
                title_ur=data.title_ur or data.title,
                body=data.body,
                body_ur=data.body_ur or data.body,
                type=data.type,
            ))
    await db.flush()
    return {"success": True, "message": "Notification sent"}


@router.get("/notifications")
async def admin_list_notifications(
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    from app.models.notification import Notification
    result = await db.execute(
        select(Notification).order_by(Notification.sent_at.desc()).limit(100)
    )
    return {"success": True, "data": result.scalars().all()}


@router.patch("/categories/{category_id}")
async def admin_update_category(
    category_id: str,
    data: TranslationUpdateRequest,
    current_user: User = admin_dep,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    if data.name_en is not None:
        cat.name = data.name_en
    if data.name_ur is not None:
        cat.name_ur = data.name_ur
    if data.description_en is not None:
        cat.description = data.description_en
    if data.description_ur is not None:
        cat.description_ur = data.description_ur
    await db.flush()
    return {"success": True}
