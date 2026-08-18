#!/usr/bin/env python3
"""Demo data seeder for AGMS — generates realistic customers, addresses, orders, and reviews."""

import asyncio
import random
import sys
import uuid
from datetime import datetime, timezone, timedelta

sys.path.insert(0, '.')
from app.core.database import async_session_factory, engine, Base
from app.models.user import User
from app.models.address import Address
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.review import Review
from app.models.promotion import Promotion
from app.models.notification import Notification
from app.core.security import hash_password
from sqlalchemy import select, func

NAMES = [
    "Ahmed Khan", "Fatima Ali", "Mohammad Hussain", "Ayesha Siddiqui", "Bilal Ahmad",
    "Sana Tariq", "Usman Malik", "Zainab Iqbal", "Omar Farooq", "Hira Butt",
    "Ali Raza", "Madiha Shah", "Hassan Abbas", "Nida Khalid", "Imran Hashmi",
    "Sadia Pervez", "Kamran Lodhi", "Rabia Nawaz", "Tariq Mehmood", "Saima Riaz",
]

ADDRESSES = [
    ("House 12, Block A, Naval Colony", "Block A", "12", "Near Masjid"),
    ("Flat 3B, Sector 4, Naval Colony", "Sector 4", "3B", ""),
    ("Shop 5, Market Road, Naval Colony", "Market Road", "5", "Opposite Park"),
    ("House 45, Street 7, Naval Colony", "Street 7", "45", ""),
    ("Apartment 8C, Phase 2, Naval Colony", "Phase 2", "8C", "Near Water Tank"),
    ("Villa 2, Waterfront, Naval Colony", "Waterfront", "2", ""),
    ("House 89, Block C, Naval Colony", "Block C", "89", "Corner House"),
    ("Flat 12, Tower 3, Naval Colony", "Tower 3", "12", ""),
    ("House 23, Main Boulevard, Naval Colony", "Main Boulevard", "23", "Near School"),
    ("Plot 67, Industrial Area, Naval Colony", "Industrial Area", "67", ""),
]

PHONE_PREFIX = "+92300"

STATUSES = ["pending", "confirmed", "preparing", "cutting", "packed", "out_for_delivery", "rider_assigned", "delivered", "cancelled"]
CUT_TYPES = ["curry_cut", "bbq_cut", "boneless", "mince", "steak", "chunks"]
PAYMENT_METHODS = ["cod", "jazzcash", "easypaisa"]
REVIEW_COMMENTS = [
    ("Excellent quality meat!", "بہترین معیار کا گوشت"),
    ("Very fresh and tender", "بہت تازہ اور نرم"),
    ("Great service and delivery", "بہترین سروس اور ڈیلیوری"),
    ("Will order again", "دوبارہ آرڈر کروں گا"),
    ("Best meat shop in town", "شہر کی بہترین گوشت کی دکان"),
    ("Good packaging", "اچھی پیکنگ"),
    ("Fresh halal meat", "تازہ حلال گوشت"),
    ("Reasonable prices", "مناسب قیمتیں"),
]

def rand_phone():
    return f"{PHONE_PREFIX}{random.randint(1000000, 9999999)}"

def order_number():
    return f"AGMS-{random.randint(10000, 99999)}"

async def seed():
    print("Creating tables if needed...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_factory() as db:
        count = await db.scalar(select(func.count(Order.id)))
        if count and count > 10:
            print(f"Demo data already exists ({count} orders). Skipping.")
            return

        result = await db.execute(select(User).where(User.role == "admin"))
        admin = result.scalar_one_or_none()
        if not admin:
            print("No admin found. Run seed first.")
            return

        result = await db.execute(select(Product))
        products = result.scalars().all()
        if not products:
            print("No products found. Run seed first.")
            return

        # Create customers + addresses
        print(f"Creating {len(NAMES)} customers with addresses...")
        customers = []
        customer_users = []
        for name in NAMES:
            phone = rand_phone()
            while any(c.phone == phone for c in customer_users):
                phone = rand_phone()
            cust = User(
                name=name,
                phone=phone,
                email=f"{name.lower().replace(' ', '.')}@email.com",
                role="customer",
                is_verified=True,
                is_active=True,
                hashed_password=hash_password("Customer123!"),
            )
            db.add(cust)
            await db.flush()

            addr_text, sector, house, landmark = random.choice(ADDRESSES)
            addr = Address(
                user_id=cust.id,
                label=random.choice(["Home", "Office", "Other"]),
                full_address=addr_text,
                street=sector,
                sector=sector,
                house_no=house,
                landmark=landmark,
                latitude=24.8607 + random.uniform(-0.01, 0.01),
                longitude=67.0011 + random.uniform(-0.01, 0.01),
                is_default=True,
            )
            db.add(addr)
            await db.flush()
            customers.append((cust, addr))
            customer_users.append(cust)
        print(f"  Created {len(customers)} customers with addresses")

        # Create orders
        ORDER_COUNT = 100
        print(f"Creating {ORDER_COUNT} orders...")
        orders_created = 0
        for i in range(ORDER_COUNT):
            customer, addr = random.choice(customers)
            days_ago = random.randint(0, 60)
            order_date = datetime.now(timezone.utc) - timedelta(days=days_ago, hours=random.randint(0, 23))
            status = random.choice(STATUSES)

            onum = order_number()
            while True:
                r = await db.execute(select(Order).where(Order.order_number == onum))
                if not r.scalar_one_or_none():
                    break
                onum = order_number()

            order = Order(
                order_number=onum,
                user_id=customer.id,
                address_id=addr.id,
                status=status,
                subtotal=0,
                delivery_fee=random.choice([0, 50, 100, 150]),
                discount=0,
                total=0,
                payment_method=random.choice(PAYMENT_METHODS),
                payment_status="paid" if status in ["delivered", "out_for_delivery", "rider_assigned"] else "pending",
                delivery_notes=random.choice(["", "Leave at gate", "Call before delivery", "Ring bell twice"]),
                is_asap=True,
                created_at=order_date,
            )
            db.add(order)
            await db.flush()

            items_count = random.randint(1, 5)
            item_total = 0
            for _ in range(items_count):
                product = random.choice(products)
                qty = round(random.uniform(0.5, 3.0), 1)
                price = product.price_per_kg
                subtotal = round(qty * price, 2)
                item_total += subtotal
                item = OrderItem(
                    order_id=order.id,
                    product_id=product.id,
                    product_name=product.name,
                    weight_kg=qty,
                    cut_type=random.choice(CUT_TYPES),
                    unit_price=price,
                    subtotal=subtotal,
                )
                db.add(item)

            order.subtotal = item_total
            order.total = item_total + order.delivery_fee
            orders_created += 1

            if orders_created % 20 == 0:
                await db.flush()
                print(f"  ... {orders_created} orders")

        await db.flush()
        print(f"  Created {orders_created} orders")

        # Create reviews
        REVIEW_COUNT = 50
        print(f"Creating {REVIEW_COUNT} reviews...")
        all_orders = (await db.execute(select(Order))).scalars().all()
        for i in range(min(REVIEW_COUNT, len(all_orders))):
            order_obj = all_orders[i]
            customer_id = order_obj.user_id
            comment, _ = random.choice(REVIEW_COMMENTS)
            review = Review(
                user_id=customer_id,
                order_id=order_obj.id,
                product_id=random.choice(products).id,
                rating=random.randint(3, 5),
                comment=comment,
                is_approved=random.choice([True, True, True, False]),
                created_at=order_obj.created_at + timedelta(hours=random.randint(1, 24)),
            )
            db.add(review)

        await db.flush()
        print(f"  Created {REVIEW_COUNT} reviews")

        # Create promotions
        promos = [
            {"code": "WELCOME10", "desc": "10% off for new customers", "type": "percentage", "value": 10, "max": 200},
            {"code": "FIRST50", "desc": "Rs. 50 off first order", "type": "fixed", "value": 50, "max": 50},
            {"code": "FREEDEL", "desc": "Free delivery on orders above Rs. 1000", "type": "free_delivery", "value": 0, "max": 0},
            {"code": "FLAT100", "desc": "Rs. 100 off on orders above Rs. 1500", "type": "fixed", "value": 100, "min_order": 1500, "max": 100},
            {"code": "EID20", "desc": "20% off Eid special", "type": "percentage", "value": 20, "max": 500},
        ]
        for p in promos:
            promo = Promotion(
                code=p["code"],
                description=p["desc"],
                description_ur=p["desc"],
                discount_type=p["type"],
                discount_value=p["value"],
                min_order_amount=p.get("min_order", 0),
                max_discount=p.get("max"),
                max_uses=1000,
                current_uses=random.randint(10, 500),
                is_active=True,
            )
            db.add(promo)
        await db.flush()
        print(f"  Created {len(promos)} promotions")

        # Send notifications
        print("Sending notifications...")
        for customer in random.sample(customer_users, 15):
            notif = Notification(
                user_id=customer.id,
                title="Special Offer!",
                title_ur="خصوصی پیشکش!",
                body="Check out our new mutton cuts with 10% off!",
                body_ur="ہمارے نئے بکرے کے گوشت پر 10% چھوٹ دیکھیں!",
                type="promotion",
            )
            db.add(notif)
        await db.flush()
        print(f"  Created 15 notifications")

        await db.commit()
        print()
        print("=== SEED COMPLETE ===")
        print(f"  Customers + Addresses: {len(customers)}")
        print(f"  Orders: {orders_created}")
        print(f"  Reviews: {REVIEW_COUNT}")
        print(f"  Promotions: {len(promos)}")
        print(f"  Notifications: 15")

if __name__ == "__main__":
    asyncio.run(seed())
