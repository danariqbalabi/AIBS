from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.entities import FoodEvent
from seeds.catalog import seed_catalog, stable_id


def test_edited_menu_plan_and_shopping_preserve_overrides_without_consumption(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    ingredients = [
        {
            "ingredient_id": str(stable_id("rice")),
            "display_name": "Nasi putih",
            "quantity": 0.5,
            "unit": "porsi",
            "certainty": "confirmed",
        }
    ]
    plan = client.post(
        "/api/v1/meal-plans",
        json={
            "menu_id": str(stable_id("chicken-rice")),
            "scheduled_at": "2026-11-14T19:00:00+07:00",
            "ingredients": ingredients,
            "ingredients_complete": False,
        },
    )
    assert plan.status_code == 201
    assert plan.json()["snapshot"]["ingredients"][0]["quantity"] == "0.5"
    assert plan.json()["snapshot"]["ingredients_complete"] is False
    shop = client.post(
        "/api/v1/shopping-items/from-menu",
        json={"menu_id": str(stable_id("chicken-rice")), "ingredients": ingredients},
    )
    assert shop.status_code == 201
    assert len(shop.json()["items"]) == 1
    assert float(shop.json()["items"][0]["quantity"]) == 0.5
    assert client.get("/api/v1/events").json()["items"] == []
    ingredients[0]["quantity"] = None
    assert (
        client.post(
            "/api/v1/shopping-items/from-menu",
            json={"menu_id": str(stable_id("chicken-rice")), "ingredients": ingredients},
        ).status_code
        == 422
    )


def test_schedule_and_shop_do_not_create_consumption(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    response = client.post(
        "/api/v1/meal-plans",
        json={
            "menu_id": str(stable_id("chicken-rice")),
            "scheduled_at": "2026-11-10T19:00:00+07:00",
        },
    )
    assert response.status_code == 201
    plan = response.json()
    assert (
        client.patch(
            f"/api/v1/meal-plans/{plan['id']}",
            json={
                "version": 1,
                "scheduled_at": "2026-11-11T19:00:00+07:00",
            },
        ).status_code
        == 200
    )
    assert (
        client.post(
            "/api/v1/shopping-items/from-menu",
            json={
                "menu_id": str(stable_id("chicken-rice")),
                "servings": 1,
            },
        ).status_code
        == 201
    )
    item = client.get("/api/v1/shopping-items").json()["items"][0]
    assert (
        client.patch(
            f"/api/v1/shopping-items/{item['id']}",
            json={
                "version": item["version"],
                "quantity": item["quantity"],
                "checked": True,
            },
        ).status_code
        == 200
    )
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(FoodEvent)) == 0


def test_shopping_only_merges_same_ingredient_and_unit(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    payload = {
        "ingredient_id": str(stable_id("rice")),
        "name": "Nasi",
        "quantity": 1,
        "unit": "porsi",
    }
    first = client.post("/api/v1/shopping-items", json=payload).json()
    second = client.post("/api/v1/shopping-items", json=payload).json()
    assert first["id"] == second["id"]
    assert float(second["quantity"]) == 2
    third = client.post("/api/v1/shopping-items", json={**payload, "unit": "g"}).json()
    assert third["id"] != first["id"]
