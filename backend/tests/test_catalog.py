from sqlalchemy.orm import Session

from app.models.entities import Menu
from seeds.catalog import seed_catalog, stable_id
from tests.test_assessment import ANSWERS


def configure(client, allergy="shrimp", avoid="garlic", budget=25000):
    profile = client.get("/api/v1/me/profile").json()
    client.patch(
        "/api/v1/me/profile",
        json={
            "version": profile["version"],
            "age_band": "18_29",
            "diagnosis_reported": "yes",
            "clinician_guidance": "yes",
            "diet": {
                "directive": "low_fodmap",
                "allergies": [str(stable_id(allergy))],
                "avoided_ingredients": [str(stable_id(avoid))],
                "budget_rupiah": budget,
            },
        },
    )
    assessment = client.get("/api/v1/me/assessment").json()
    client.patch(
        "/api/v1/me/assessment", json={"version": assessment["version"], "answers": ANSWERS}
    )


def test_two_profiles_have_distinct_recommendations_and_conflicts(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    configure(client)
    a = client.get("/api/v1/recommendations").json()["items"]
    assert all(
        not any(i["ingredient_id"] == str(stable_id("shrimp")) for i in m["ingredients"]) for m in a
    )
    configure(client, allergy="peanut", avoid="coconut", budget=35000)
    b = client.get("/api/v1/recommendations").json()["items"]
    assert {m["id"] for m in a} != {m["id"] for m in b}
    assert all(m["evaluation"]["status"] in ("ok", "warn") for m in b)


def test_unknown_sauce_does_not_hide_known_allergy_conflict(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    configure(client)
    version = client.get("/api/v1/me/profile").json()["version"]
    response = client.post(
        "/api/v1/food-checks",
        json={
            "profile_version": version,
            "ingredients_complete": False,
            "ingredients": [
                {
                    "ingredient_id": str(stable_id("shrimp")),
                    "display_name": "Udang",
                    "certainty": "confirmed",
                    "quantity": 1,
                    "unit": "porsi",
                },
                {"display_name": "Saus", "certainty": "unknown"},
            ],
        },
    )
    assert response.status_code == 200
    assert response.json()["status"] == "bad"
    assert response.json()["missing_information"]
    assert any(r["code"] == "allergy_conflict" for r in response.json()["reasons"])
    assert (
        client.post(
            "/api/v1/food-checks",
            json={
                "profile_version": 1,
                "ingredients": [],
            },
        ).status_code
        == 409
    )


def test_incomplete_profile_cannot_request_diet_recommendations(account):
    client, _ = account
    assert client.get("/api/v1/recommendations").status_code == 403


def test_display_preferences_and_spice_affect_ranking_after_constraints(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
        for key, tags in (
            ("chicken-rice", ["halal", "spicy_none"]),
            ("tofu-carrot", ["vegetarian", "quick", "spicy_hot"]),
        ):
            menu = db.get(Menu, stable_id(key))
            menu.price_rupiah = 22000
            menu.tags = tags
    configure(client)
    profile = client.get("/api/v1/me/profile").json()
    diet = {**profile["diet"], "preferences": ["Vegetarian", "Masak ≤ 15 menit"], "spicy": None}
    updated = client.patch(
        "/api/v1/me/profile", json={"version": profile["version"], "diet": diet}
    ).json()
    assert updated["diet"]["preferences"] == ["vegetarian", "quick"]
    assert client.get("/api/v1/recommendations").json()["items"][0]["id"] == str(
        stable_id("tofu-carrot")
    )
    client.patch(
        "/api/v1/me/profile",
        json={"version": updated["version"], "diet": {**diet, "spicy": "none"}},
    )
    assert client.get("/api/v1/recommendations").json()["items"][0]["id"] == str(
        stable_id("chicken-rice")
    )


def test_portion_recheck_sums_duplicate_ingredients_and_requires_compatible_unit(
    account, db_engine
):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    configure(client)
    profile = client.get("/api/v1/me/profile").json()
    diet = profile["diet"]
    diet["portion_limits"] = [
        {"ingredient_id": str(stable_id("rice")), "quantity": 1, "unit": "porsi"}
    ]
    changed = client.patch(
        "/api/v1/me/profile", json={"version": profile["version"], "diet": diet}
    ).json()
    ingredient = {
        "ingredient_id": str(stable_id("rice")),
        "display_name": "Nasi",
        "certainty": "confirmed",
        "quantity": 0.75,
        "unit": "porsi",
    }
    payload = {
        "profile_version": changed["version"],
        "ingredients_complete": True,
        "ingredients": [ingredient, ingredient],
    }
    response = client.post("/api/v1/food-checks", json=payload)
    assert response.json()["status"] == "warn"
    assert response.json()["reasons"][0]["code"] == "portion_limit"
    payload["ingredients"] = [{**ingredient, "unit": "g"}]
    assert client.post("/api/v1/food-checks", json=payload).json()["status"] == "unknown"
