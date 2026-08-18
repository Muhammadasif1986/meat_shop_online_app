import json
from pydantic import BaseModel, field_validator
from typing import List, Optional
from datetime import datetime


class CategoryResponse(BaseModel):
    id: str
    name: str
    name_ur: Optional[str] = None
    slug: str
    description: Optional[str] = None
    description_ur: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: int

    class Config:
        from_attributes = True


class ProductResponse(BaseModel):
    id: str
    category_id: str
    name: str
    name_ur: Optional[str] = None
    slug: str
    description: Optional[str] = None
    description_ur: Optional[str] = None
    price_per_kg: float
    compare_price: Optional[float] = None
    stock_kg: float
    min_order_kg: float
    max_order_kg: float
    images: List[str]
    freshness_status: str
    is_featured: bool
    cut_options: List[str]
    stock_updated_at: datetime

    class Config:
        from_attributes = True

    @field_validator("images", "cut_options", mode="before")
    @classmethod
    def parse_json_list(cls, v):
        if isinstance(v, str):
            try:
                parsed = json.loads(v)
            except json.JSONDecodeError:
                return [v]
            while isinstance(parsed, str):
                try:
                    parsed = json.loads(parsed)
                except json.JSONDecodeError:
                    break
            if isinstance(parsed, list):
                return parsed
            return [parsed] if parsed is not None else []
        return v or []


class ProductListResponse(BaseModel):
    items: List[ProductResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
