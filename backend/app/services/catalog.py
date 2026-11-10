from sqlalchemy import select

from app.core.errors import ApiError
from app.models.entities import Ingredient, Menu, MenuIngredient
from app.rules.food import check
from app.schemas.domain import DietProfile, IngredientInput
from app.services.assessment import access_for
from app.services.profiles import profile_for, require_basic


def check_food(db, owner, payload):
    require_basic(db, owner)
    profile = profile_for(db, owner)
    if profile.version != payload.profile_version:
        raise ApiError(409, "profile_changed", "Profil berubah. Muat ulang dan cek kembali.")
    known_ids = {str(value) for value in db.scalars(select(Ingredient.id))}
    return check(
        profile, payload.ingredients, payload.ingredients_complete, access_for(db, owner), known_ids
    )


def menu_ingredients(db, menu_id):
    rows = db.execute(
        select(MenuIngredient, Ingredient)
        .join(
            Ingredient,
            Ingredient.id == MenuIngredient.ingredient_id,
        )
        .where(MenuIngredient.menu_id == menu_id)
        .order_by(Ingredient.name)
    ).all()
    return [
        IngredientInput(
            ingredient_id=ingredient.id,
            display_name=ingredient.name,
            quantity=link.quantity,
            unit=link.unit,
            certainty="confirmed",
        )
        for link, ingredient in rows
    ]


def menu_view(db, profile, access, menu, known_ids):
    ingredients = menu_ingredients(db, menu.id)
    diet = DietProfile.model_validate(profile.diet)
    evaluation = check(
        profile,
        ingredients,
        menu.ingredients_complete,
        access,
        known_ids,
        directive_supported=diet.directive in menu.directives,
    )
    if diet.directive not in menu.directives:
        evaluation["missing_information"].append(
            "Komposisi demo ini belum mendukung arahan dietmu."
        )
        if evaluation["status"] != "bad":
            evaluation["status"] = "unknown"
    return {
        "id": menu.id,
        "name": menu.name,
        "kind": menu.kind,
        "price_rupiah": menu.price_rupiah,
        "ingredients": ingredients,
        "ingredients_complete": menu.ingredients_complete,
        "instructions": menu.instructions,
        "tags": menu.tags,
        "source": menu.source,
        "evaluation": evaluation,
        "within_budget": diet.budget_rupiah is None or menu.price_rupiah <= diet.budget_rupiah,
    }


def list_menus(db, owner, *, query=None, kind=None, max_price=None, recommendations=False):
    require_basic(db, owner)
    profile, access = profile_for(db, owner), access_for(db, owner)
    if recommendations and access["route"] != "diet_support":
        raise ApiError(403, "diet_access_required", "Lengkapi profil dan arahan dietmu.")
    statement = select(Menu)
    if query:
        statement = statement.where(Menu.name.icontains(query, autoescape=True))
    if kind:
        statement = statement.where(Menu.kind == kind)
    if max_price is not None:
        statement = statement.where(Menu.price_rupiah <= max_price)
    known_ids = {str(value) for value in db.scalars(select(Ingredient.id))}
    items = [menu_view(db, profile, access, menu, known_ids) for menu in db.scalars(statement)]
    if recommendations:
        items = [item for item in items if item["evaluation"]["status"] in ("ok", "warn")]
    preferences = set(DietProfile.model_validate(profile.diet).preferences)
    rank = {"ok": 0, "warn": 1, "unknown": 2, "bad": 3}
    items.sort(
        key=lambda item: (
            rank[item["evaluation"]["status"]],
            not item["within_budget"],
            -len(preferences.intersection(item["tags"])),
            item["price_rupiah"],
            str(item["id"]),
        )
    )
    return {"items": items, "next_cursor": None, "profile_version": profile.version}
