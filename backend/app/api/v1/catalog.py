from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.core.errors import ApiError
from app.models.entities import Ingredient, Menu
from app.schemas.domain import FoodCheckInput
from app.services import catalog
from app.services.assessment import access_for
from app.services.profiles import profile_for, require_basic

router = APIRouter(prefix="/api/v1", tags=["catalog"])


@router.get("/ingredients")
def ingredients(
    q: str | None = Query(None, max_length=100),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    require_basic(db, user.id)
    rows = db.scalars(select(Ingredient).order_by(Ingredient.name)).all()
    matches = [
        row
        for row in rows
        if not q
        or q.casefold() in row.name.casefold()
        or any(q.casefold() in alias.casefold() for alias in row.aliases)
    ]
    return {
        "items": [
            {"id": row.id, "name": row.name, "aliases": row.aliases} for row in matches[:100]
        ],
        "next_cursor": None,
    }


@router.get("/menus")
def menus(
    q: str | None = Query(None, max_length=100),
    kind: Literal["buy", "cook"] | None = None,
    max_price: int | None = Query(None, gt=0),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return catalog.list_menus(db, user.id, query=q, kind=kind, max_price=max_price)


@router.get("/recommendations")
def recommendations(user: User = Depends(get_user), db: Session = Depends(get_db)):
    return catalog.list_menus(db, user.id, recommendations=True)


@router.get("/menus/{menu_id}")
def menu_detail(menu_id: UUID, user: User = Depends(get_user), db: Session = Depends(get_db)):
    require_basic(db, user.id)
    menu = db.get(Menu, menu_id)
    if menu is None:
        raise ApiError(404, "not_found", "Menu tidak ditemukan.")
    known = {str(value) for value in db.scalars(select(Ingredient.id))}
    return catalog.menu_view(db, profile_for(db, user.id), access_for(db, user.id), menu, known)


@router.post("/food-checks")
def food_check(
    payload: FoodCheckInput, user: User = Depends(get_user), db: Session = Depends(get_db)
):
    return catalog.check_food(db, user.id, payload)
