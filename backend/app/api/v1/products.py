from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.locale import get_locale, localized_field, localized_dict
from app.models.product import Category, Product
from app.schemas.product import CategoryResponse, ProductResponse, ProductListResponse

router = APIRouter(prefix="", tags=["Products"])


@router.get("/categories", response_model=list[CategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Category).where(Category.is_active == True).order_by(Category.sort_order)
    )
    return result.scalars().all()


@router.get("/products", response_model=ProductListResponse)
async def list_products(
    request: Request,
    category: str = Query(None),
    search: str = Query(None),
    min_price: float = Query(None),
    max_price: float = Query(None),
    sort: str = Query("popularity"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    locale = get_locale(request)
    query = select(Product).where(Product.is_active == True)

    if category:
        cat_result = await db.execute(
            select(Category).where(Category.slug == category)
        )
        cat = cat_result.scalar_one_or_none()
        if cat:
            query = query.where(Product.category_id == cat.id)

    if search:
        query = query.where(
            Product.name.ilike(f"%{search}%") |
            (Product.name_ur != None) & (Product.name_ur.ilike(f"%{search}%"))
        )

    if min_price is not None:
        query = query.where(Product.price_per_kg >= min_price)
    if max_price is not None:
        query = query.where(Product.price_per_kg <= max_price)

    if sort == "price_asc":
        query = query.order_by(Product.price_per_kg.asc())
    elif sort == "price_desc":
        query = query.order_by(Product.price_per_kg.desc())
    elif sort == "freshness":
        query = query.order_by(Product.stock_updated_at.desc())
    else:
        query = query.order_by(Product.is_featured.desc(), Product.created_at.desc())

    total_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(total_query)
    total = total_result.scalar()

    offset = (page - 1) * per_page
    query = query.offset(offset).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    return ProductListResponse(
        items=[ProductResponse.model_validate(item) for item in items],
        total=total,
        page=page,
        per_page=per_page,
        total_pages=(total + per_page - 1) // per_page,
    )


@router.get("/products/featured", response_model=list[ProductResponse])
async def featured_products(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Product)
        .where(Product.is_active == True, Product.is_featured == True, Product.stock_kg > 0)
        .limit(10)
    )
    return result.scalars().all()


@router.get("/products/{slug}", response_model=ProductResponse)
async def get_product(slug: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Product).where(Product.slug == slug, Product.is_active == True)
    )
    product = result.scalar_one_or_none()
    if not product:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product
