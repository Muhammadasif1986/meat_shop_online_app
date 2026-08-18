from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.address import Address

router = APIRouter(prefix="/addresses", tags=["Addresses"])


class AddressCreate(BaseModel):
    label: str = "Home"
    full_address: str
    street: Optional[str] = None
    sector: Optional[str] = None
    house_no: Optional[str] = None
    landmark: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_default: bool = False


class AddressUpdate(BaseModel):
    label: Optional[str] = None
    full_address: Optional[str] = None
    street: Optional[str] = None
    sector: Optional[str] = None
    house_no: Optional[str] = None
    landmark: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_default: Optional[bool] = None


@router.get("")
async def list_addresses(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Address)
        .where(Address.user_id == current_user.id)
        .order_by(Address.is_default.desc(), Address.created_at.desc())
    )
    return {"success": True, "data": result.scalars().all()}


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_address(
    request: AddressCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if request.is_default:
        result = await db.execute(
            select(Address).where(Address.user_id == current_user.id, Address.is_default == True)  # noqa: E712
        )
        for addr in result.scalars().all():
            addr.is_default = False

    addr = Address(user_id=current_user.id, **request.model_dump())
    db.add(addr)
    await db.flush()

    if request.is_default or not await _has_default(db, current_user.id):
        if not request.is_default:
            addr.is_default = True
            await db.flush()

    return {"success": True, "data": {"id": str(addr.id)}}


@router.patch("/{address_id}")
async def update_address(
    address_id: str,
    request: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == current_user.id)
    )
    addr = result.scalar_one_or_none()
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")

    data = request.model_dump(exclude_unset=True)

    if data.get("is_default"):
        result = await db.execute(
            select(Address).where(Address.user_id == current_user.id, Address.is_default == True)  # noqa: E712
        )
        for other in result.scalars().all():
            if other.id != address_id:
                other.is_default = False

    for key, value in data.items():
        setattr(addr, key, value)

    await db.flush()
    return {"success": True, "data": {"id": str(addr.id)}}


@router.delete("/{address_id}")
async def delete_address(
    address_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == current_user.id)
    )
    addr = result.scalar_one_or_none()
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")

    from sqlalchemy import text

    in_use = await db.execute(
        text("SELECT COUNT(*) FROM orders WHERE address_id = :addr_id"),
        {"addr_id": address_id},
    )
    count = in_use.scalar() or 0
    if count > 0:
        raise HTTPException(
            status_code=400,
            detail="This address is linked to your orders and cannot be deleted.",
        )

    was_default = addr.is_default
    await db.delete(addr)
    await db.flush()

    if was_default:
        remaining = await db.execute(
            select(Address).where(Address.user_id == current_user.id).order_by(Address.created_at.desc())
        )
        others = remaining.scalars().all()
        if others:
            others[0].is_default = True
            await db.flush()

    return {"success": True, "message": "Address deleted"}


async def _has_default(db: AsyncSession, user_id: str) -> bool:
    result = await db.execute(
        select(Address.id)
        .where(Address.user_id == user_id, Address.is_default == True)  # noqa: E712
        .limit(1)
    )
    return result.scalar() is not None
