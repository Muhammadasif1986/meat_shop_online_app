"""Seed script for initial data"""
import asyncio
import json
from app.core.database import engine, Base, async_session_factory
from app.models.product import Category, Product
from app.models.user import User, UserRole
from app.core.security import hash_password


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_factory() as session:
        # Categories with Urdu translations
        categories = [
            Category(name="Beef", name_ur="گوشت", slug="beef", description="Fresh halal beef", description_ur="تازہ حلال گائے کا گوشت", sort_order=1),
            Category(name="Chicken", name_ur="چکن", slug="chicken", description="Farm-fresh chicken", description_ur="فارم تازہ چکن", sort_order=2),
            Category(name="Mutton", name_ur="بکرا", slug="mutton", description="Tender quality mutton", description_ur="نرم اور معیاری بکرے کا گوشت", sort_order=3),
        ]
        session.add_all(categories)
        await session.flush()

        # Products with Urdu translations
        products = [
            Product(category_id=categories[0].id, name="Premium Beef", name_ur="پریمیم بیف", slug="premium-beef",
                    price_per_kg=1200, stock_kg=100,
                    cut_options=json.dumps(["curry_cut", "bbq_cut", "boneless", "mince"]),
                    description="Premium quality beef, tender and fresh",
                    description_ur="پریمیم کوالٹی گائے کا گوشت، نرم اور تازہ", is_featured=True),
            Product(category_id=categories[0].id, name="Beef Mince", name_ur="قیمہ", slug="beef-mince",
                    price_per_kg=1000, stock_kg=50,
                    cut_options=json.dumps(["mince"]),
                    description="Freshly ground beef mince",
                    description_ur="تازہ پسا ہوا گائے کا قیمہ", is_featured=True),
            Product(category_id=categories[1].id, name="Whole Chicken", name_ur="پورا چکن", slug="whole-chicken",
                    price_per_kg=500, stock_kg=200,
                    cut_options=json.dumps(["curry_cut", "bbq_cut", "boneless"]),
                    description="Farm fresh whole chicken",
                    description_ur="فارم تازہ پورا چکن", is_featured=True),
            Product(category_id=categories[1].id, name="Chicken Breast", name_ur="چکن بریسٹ", slug="chicken-breast",
                    price_per_kg=650, stock_kg=80,
                    cut_options=json.dumps(["boneless", "curry_cut"]),
                    description="Boneless chicken breast",
                    description_ur="بغیر ہڈی کے چکن کا سینہ", is_featured=True),
            Product(category_id=categories[2].id, name="Premium Mutton", name_ur="پریمیم بکرا", slug="premium-mutton",
                    price_per_kg=1600, stock_kg=60,
                    cut_options=json.dumps(["curry_cut", "bbq_cut", "boneless", "mince"]),
                    description="Premium quality mutton",
                    description_ur="پریمیم کوالٹی بکرے کا گوشت", is_featured=True),
        ]
        session.add_all(products)

        # Admin user
        admin = User(
            phone="+923001234567",
            name="Shop Admin",
            email="admin@agms.com",
            hashed_password=hash_password("Admin123!"),
            role=UserRole.admin,
            is_verified=True,
            is_active=True,
            language_pref="en",
        )
        session.add(admin)

        await session.commit()
        print("Seed data created successfully!")


if __name__ == "__main__":
    asyncio.run(seed())
