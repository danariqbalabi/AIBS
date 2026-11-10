from datetime import UTC
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.models.entities import MealPlan, ShoppingItem
from app.repositories.owned import owned
from app.schemas.domain import PlanInput, PlanPatch, ShoppingFromMenu, ShoppingInput, ShoppingPatch
from app.services import planning
from app.services.profiles import require_basic, versioned_update

router = APIRouter(prefix="/api/v1", tags=["planning"])


@router.post("/meal-plans", status_code=201)
def create_plan(payload: PlanInput, user: User = Depends(get_user), db: Session = Depends(get_db)):
    return planning.create_plan(db, user.id, payload)


@router.get("/meal-plans")
def plans(user: User = Depends(get_user), db: Session = Depends(get_db)):
    require_basic(db, user.id)
    rows = db.scalars(
        select(MealPlan).where(MealPlan.owner_id == user.id).order_by(MealPlan.scheduled_at)
    ).all()
    return {"items": [planning.plan_view(row) for row in rows], "next_cursor": None}


@router.patch("/meal-plans/{plan_id}")
def patch_plan(
    plan_id: UUID, payload: PlanPatch, user: User = Depends(get_user), db: Session = Depends(get_db)
):
    require_basic(db, user.id)
    row = owned(db, MealPlan, plan_id, user.id)
    versioned_update(
        db, row, payload.version, {"scheduled_at": payload.scheduled_at.astimezone(UTC)}
    )
    db.commit()
    return planning.plan_view(row)


@router.delete("/meal-plans/{plan_id}", status_code=204)
def delete_plan(
    plan_id: UUID,
    version: int = Query(ge=1),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    require_basic(db, user.id)
    planning.remove(db, user.id, MealPlan, plan_id, version)
    return Response(status_code=204)


@router.get("/shopping-items")
def items(user: User = Depends(get_user), db: Session = Depends(get_db)):
    require_basic(db, user.id)
    rows = db.scalars(
        select(ShoppingItem).where(ShoppingItem.owner_id == user.id).order_by(ShoppingItem.name)
    )
    return {"items": [planning.shopping_view(row) for row in rows], "next_cursor": None}


@router.post("/shopping-items", status_code=201)
def add(payload: ShoppingInput, user: User = Depends(get_user), db: Session = Depends(get_db)):
    require_basic(db, user.id)
    row = planning.add_item(db, user.id, payload)
    db.commit()
    return planning.shopping_view(row)


@router.post("/shopping-items/from-menu", status_code=201)
def from_menu(
    payload: ShoppingFromMenu, user: User = Depends(get_user), db: Session = Depends(get_db)
):
    require_basic(db, user.id)
    return planning.add_from_menu(db, user.id, payload)


@router.patch("/shopping-items/{item_id}")
def patch_item(
    item_id: UUID,
    payload: ShoppingPatch,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    require_basic(db, user.id)
    row = owned(db, ShoppingItem, item_id, user.id)
    versioned_update(
        db, row, payload.version, {"quantity": payload.quantity, "checked": payload.checked}
    )
    db.commit()
    return planning.shopping_view(row)


@router.delete("/shopping-items/{item_id}", status_code=204)
def delete_item(
    item_id: UUID,
    version: int = Query(ge=1),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    require_basic(db, user.id)
    planning.remove(db, user.id, ShoppingItem, item_id, version)
    return Response(status_code=204)
