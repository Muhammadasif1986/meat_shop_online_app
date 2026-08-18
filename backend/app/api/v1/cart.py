from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.cart import Cart, CartItem
from app.models.product import Product
from app.schemas.order import CartItemCreate, CartItemUpdate, CartResponse, CartItemResponse

router = APIRouter(prefix="/cart", tags=["Cart"])


async def get_or_create_cart(user_id: str, db: AsyncSession) -> Cart:
    result = await db.execute(select(Cart).where(Cart.user_id == user_id))
    cart = result.scalar_one_or_none()
    if not cart:
        cart = Cart(user_id=user_id)
        db.add(cart)
        await db.flush()
    return cart


@router.get("", response_model=CartResponse)
async def get_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cart = await get_or_create_cart(str(current_user.id), db)
    items_result = await db.execute(
        select(CartItem).where(CartItem.cart_id == cart.id)
    )
    items = items_result.scalars().all()
    subtotal = sum(float(item.subtotal) for item in items)
    delivery_fee = 50 if subtotal < 1000 else 0
    discount = float(cart.discount_amount or 0)

    return CartResponse(
        id=str(cart.id),
        items=[CartItemResponse.model_validate(item) for item in items],
        promo_code=cart.promo_code,
        discount_amount=discount,
        subtotal=subtotal,
        delivery_fee=delivery_fee,
        total=subtotal + delivery_fee - discount,
    )


@router.post("/items", status_code=status.HTTP_201_CREATED)
async def add_to_cart(
    request: CartItemCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cart = await get_or_create_cart(str(current_user.id), db)

    product_result = await db.execute(
        select(Product).where(Product.id == request.product_id, Product.is_active == True)
    )
    product = product_result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    if float(product.stock_kg) < request.weight_kg:
        raise HTTPException(status_code=400, detail="Insufficient stock")

    unit_price = float(product.price_per_kg)
    subtotal = round(unit_price * request.weight_kg, 2)

    cart_item = CartItem(
        cart_id=cart.id,
        product_id=request.product_id,
        weight_kg=request.weight_kg,
        cut_type=request.cut_type,
        custom_instructions=request.custom_instructions,
        unit_price=unit_price,
        subtotal=subtotal,
    )
    db.add(cart_item)
    await db.flush()

    return {"success": True, "data": CartItemResponse.model_validate(cart_item)}


@router.patch("/items/{item_id}")
async def update_cart_item(
    item_id: str,
    request: CartItemUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    item_result = await db.execute(select(CartItem).where(CartItem.id == item_id))
    item = item_result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    if request.weight_kg is not None:
        item.weight_kg = request.weight_kg
        item.subtotal = round(float(item.unit_price) * request.weight_kg, 2)
    if request.cut_type is not None:
        item.cut_type = request.cut_type
    if request.custom_instructions is not None:
        item.custom_instructions = request.custom_instructions

    await db.flush()
    return {"success": True, "data": CartItemResponse.model_validate(item)}


@router.delete("/items/{item_id}")
async def remove_cart_item(
    item_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(CartItem).where(CartItem.id == item_id))
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")
    await db.delete(item)
    await db.flush()
    return {"success": True, "message": "Item removed"}


@router.delete("")
async def clear_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cart = await get_or_create_cart(str(current_user.id), db)
    items_result = await db.execute(
        select(CartItem).where(CartItem.cart_id == cart.id)
    )
    for item in items_result.scalars().all():
        await db.delete(item)
    cart.promo_code = None
    cart.discount_amount = 0
    await db.flush()
    return {"success": True, "message": "Cart cleared"}
