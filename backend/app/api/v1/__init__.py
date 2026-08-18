from fastapi import APIRouter

router = APIRouter(prefix="/api/v1")


from app.api.v1 import auth, products, cart, orders, reviews, subscriptions, notifications, admin, rider, addresses, telegram

router.include_router(auth.router)
router.include_router(products.router)
router.include_router(cart.router)
router.include_router(orders.router)
router.include_router(reviews.router)
router.include_router(subscriptions.router)
router.include_router(notifications.router)
router.include_router(admin.router)
router.include_router(rider.router)
router.include_router(addresses.router)
router.include_router(telegram.router)
