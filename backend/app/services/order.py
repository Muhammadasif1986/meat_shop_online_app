from datetime import datetime, timezone
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.order import Order, OrderItem, OrderStatusLog, OrderStatus
from app.models.cart import Cart
from app.models.product import Product
from app.models.address import Address
from app.core.utils import generate_order_number


class OrderService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_from_cart(self, user_id: str, data: dict) -> Order:
        inline_items = data.get("items") or []
        if inline_items:
            return await self._create_order(user_id, data, inline_items)

        cart_result = await self.db.execute(
            select(Cart).where(Cart.user_id == user_id)
        )
        cart = cart_result.scalar_one_or_none()
        if not cart or not cart.items:
            raise ValueError("Cart is empty")

        return await self._create_order(user_id, data, cart.items)

    @staticmethod
    def _item_attr(item, name):
        if isinstance(item, dict):
            return item.get(name)
        return getattr(item, name, None)

    async def _create_order(self, user_id: str, data: dict, source_items) -> Order:
        address_id = await self._resolve_address(user_id, data)

        order_items = []
        subtotal = 0.0
        for cart_item in source_items:
            product_id = self._item_attr(cart_item, "product_id")
            weight = float(self._item_attr(cart_item, "weight_kg") or 0)
            cut_type = self._item_attr(cart_item, "cut_type") or "curry_cut"

            product_result = await self.db.execute(
                select(Product).where(Product.id == product_id)
            )
            product = product_result.scalar_one_or_none()
            if not product:
                raise ValueError("Product not found")

            unit_price = float(product.price_per_kg)
            line_subtotal = round(unit_price * weight, 2)
            subtotal += line_subtotal

            order_items.append(
                OrderItem(
                    product_id=product_id,
                    product_name=product.name,
                    weight_kg=weight,
                    cut_type=cut_type,
                    unit_price=unit_price,
                    subtotal=line_subtotal,
                    custom_instructions=self._item_attr(cart_item, "custom_instructions"),
                )
            )
            await self._deduct_stock(product_id, weight)

        delivery_fee = 50 if subtotal < 1000 else 0
        discount = 0.0
        total = subtotal + delivery_fee - discount

        order = Order(
            order_number=generate_order_number(),
            user_id=user_id,
            address_id=address_id,
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            discount=discount,
            total=total,
            payment_method=data.get("payment_method", "cod"),
            delivery_notes=data.get("delivery_notes"),
            is_asap=data.get("is_asap", True),
            scheduled_date=data.get("scheduled_date"),
            scheduled_slot=data.get("scheduled_slot"),
        )
        self.db.add(order)
        await self.db.flush()

        for item in order_items:
            item.order_id = order.id
            self.db.add(item)

        log = OrderStatusLog(order_id=order.id, to_status=OrderStatus.pending)
        self.db.add(log)

        # Clear server-side cart if it was used
        if not (data.get("items") or []):
            cart_result = await self.db.execute(
                select(Cart).where(Cart.user_id == user_id)
            )
            cart = cart_result.scalar_one_or_none()
            if cart:
                await self.db.delete(cart)

        await self.db.flush()
        return order

    async def _resolve_address(self, user_id: str, data: dict) -> str:
        if data.get("address_id"):
            return data["address_id"]

        delivery_address = (data.get("delivery_address") or "").strip()
        if delivery_address:
            address = Address(
                user_id=user_id,
                label="Home",
                full_address=delivery_address,
                is_default=True,
            )
            self.db.add(address)
            await self.db.flush()
            return str(address.id)

        result = await self.db.execute(
            select(Address)
            .where(Address.user_id == user_id)
            .order_by(Address.is_default.desc())
        )
        address = result.scalars().first()
        if not address:
            raise ValueError("No delivery address provided")
        return str(address.id)

    async def _deduct_stock(self, product_id: str, weight: float):
        result = await self.db.execute(
            select(Product).where(Product.id == product_id)
        )
        product = result.scalar_one_or_none()
        if product:
            product.stock_kg = float(product.stock_kg) - weight

    async def update_status(self, order_id: str, new_status: OrderStatus, notes: str = None, changed_by: str = None):
        result = await self.db.execute(select(Order).where(Order.id == order_id))
        order = result.scalar_one_or_none()
        if not order:
            raise ValueError("Order not found")

        old_status = order.status if order.status else None
        order.status = new_status

        if new_status == OrderStatus.delivered:
            order.delivered_at = datetime.now(timezone.utc)

        log = OrderStatusLog(
            order_id=order_id,
            from_status=old_status,
            to_status=new_status,
            changed_by=changed_by,
            notes=notes,
        )
        self.db.add(log)
        await self.db.flush()
        return order
