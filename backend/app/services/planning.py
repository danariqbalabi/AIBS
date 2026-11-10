from datetime import UTC

from pydantic import ValidationError
from sqlalchemy import delete, select, update
from sqlalchemy.exc import IntegrityError

from app.core.errors import ApiError
from app.models.entities import Ingredient, MealPlan, Menu, ShoppingItem
from app.repositories.owned import owned
from app.schemas.domain import ShoppingInput
from app.services.assessment import access_for
from app.services.catalog import menu_ingredients, menu_view
from app.services.profiles import profile_for, require_basic


def plan_view(row):
    return {
        "id": row.id,
        "version": row.version,
        "menu_id": row.menu_id,
        "scheduled_at": row.scheduled_at.replace(tzinfo=UTC)
        if row.scheduled_at.tzinfo is None
        else row.scheduled_at,
        "snapshot": row.snapshot,
    }


def create_plan(db, owner, payload):
    require_basic(db, owner)
    menu = db.get(Menu, payload.menu_id)
    if menu is None:
        raise ApiError(404, "not_found", "Menu tidak ditemukan.")
    known_ids = {str(value) for value in db.scalars(select(Ingredient.id))}
    snapshot = menu_view(db, profile_for(db, owner), access_for(db, owner), menu, known_ids)
    snapshot = {
        "name": menu.name,
        "evaluation": snapshot["evaluation"],
        "ingredients": [item.model_dump(mode="json") for item in snapshot["ingredients"]],
    }
    row = MealPlan(
        owner_id=owner,
        menu_id=menu.id,
        scheduled_at=payload.scheduled_at.astimezone(UTC),
        snapshot=snapshot,
    )
    db.add(row)
    db.commit()
    return plan_view(row)


def shopping_view(row):
    return {
        "id": row.id,
        "version": row.version,
        "ingredient_id": row.ingredient_id,
        "name": row.name,
        "quantity": str(row.quantity),
        "unit": row.unit,
        "checked": row.checked,
    }


def add_item(db, owner, payload):
    ingredient = db.get(Ingredient, payload.ingredient_id) if payload.ingredient_id else None
    if payload.ingredient_id and ingredient is None:
        raise ApiError(422, "unknown_ingredient", "Pilih bahan katalog yang tersedia.")
    existing = None
    if ingredient:
        existing = db.scalar(
            select(ShoppingItem)
            .where(
                ShoppingItem.owner_id == owner,
                ShoppingItem.ingredient_id == ingredient.id,
                ShoppingItem.unit == payload.unit,
            )
            .with_for_update()
        )
    if existing:
        if existing.quantity + payload.quantity > 10000:
            raise ApiError(422, "quantity_limit", "Jumlah belanja terlalu besar.")
        result = db.execute(
            update(ShoppingItem)
            .where(
                ShoppingItem.id == existing.id,
                ShoppingItem.owner_id == owner,
                ShoppingItem.quantity <= 10000 - payload.quantity,
            )
            .values(
                quantity=ShoppingItem.quantity + payload.quantity,
                checked=False,
                version=ShoppingItem.version + 1,
            ),
            execution_options={"synchronize_session": False},
        )
        if result.rowcount != 1:
            raise ApiError(409, "shopping_conflict", "Jumlah berubah. Muat ulang daftar belanja.")
        db.expire(existing)
        return existing
    row = ShoppingItem(
        owner_id=owner,
        ingredient_id=payload.ingredient_id,
        name=ingredient.name if ingredient else payload.name,
        quantity=payload.quantity,
        unit=payload.unit,
    )
    db.add(row)
    try:
        db.flush()
    except IntegrityError as exc:
        raise ApiError(
            409, "shopping_conflict", "Bahan sedang ditambahkan. Muat ulang daftar.", retryable=True
        ) from exc
    return row


def remove(db, owner, model, object_id, version):
    owned(db, model, object_id, owner)
    result = db.execute(
        delete(model).where(
            model.id == object_id, model.owner_id == owner, model.version == version
        )
    )
    if result.rowcount != 1:
        raise ApiError(409, "version_conflict", "Data berubah. Muat ulang sebelum menghapus.")
    db.commit()


def add_from_menu(db, owner, payload):
    if db.get(Menu, payload.menu_id) is None:
        raise ApiError(404, "not_found", "Menu tidak ditemukan.")
    try:
        inputs = [
            ShoppingInput(
                ingredient_id=item.ingredient_id,
                name=item.display_name,
                quantity=item.quantity * payload.servings,
                unit=item.unit,
            )
            for item in menu_ingredients(db, payload.menu_id)
        ]
    except ValidationError as exc:
        raise ApiError(
            422, "quantity_limit", "Porsi menghasilkan jumlah yang terlalu besar atau rinci."
        ) from exc
    result = [add_item(db, owner, item) for item in inputs]
    db.commit()
    return {"items": [shopping_view(row) for row in result]}
