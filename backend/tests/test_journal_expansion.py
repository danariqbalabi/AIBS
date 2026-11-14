from sqlalchemy.orm import Session

from seeds.catalog import seed_catalog, stable_id
from tests.test_catalog import configure
from tests.test_records import journal_payload, save


def test_new_symptoms_round_trip_and_summary(account):
    client, _ = account
    content = journal_payload()
    content["content"]["foods"] = []
    content["content"]["symptoms"] = [
        {
            "code": code,
            "present": True,
            "severity": 3,
            "time": {
                "date": "2026-11-10",
                "precision": "approximate",
                "period": "midday",
                "confirmed": True,
            },
        }
        for code in ["gas", "urgency"]
    ]
    draft = client.post("/api/v1/drafts", json=content)
    assert draft.status_code == 201
    assert save(client, draft.json()).status_code == 200
    report = client.get("/api/v1/summaries?days=7&end=2026-11-10").json()
    assert report["symptom_types"] == {"gas": 1, "urgency": 1}


def test_swaps_check_entire_composition_and_allergies(account, db_engine):
    client, _ = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    configure(client)

    def row(key, name):
        return {
            "ingredient_id": str(stable_id(key)),
            "display_name": name,
            "certainty": "confirmed",
            "quantity": "1",
            "unit": "g",
        }

    card = {
        "name": "Masakan",
        "ingredients_complete": True,
        "ingredients": [row("garlic", "Bawang putih")],
    }
    response = client.post("/api/v1/food-swaps", json=card)
    assert response.status_code == 200
    assert response.json()["items"][0]["to"] == "Jahe"
    assert response.json()["items"][0]["evaluation"]["status"] == "ok"
    # Swapping garlic cannot hide the other allergen in the complete dish.
    card["ingredients"].append(row("shrimp", "Udang"))
    assert client.post("/api/v1/food-swaps", json=card).json()["items"] == []
    # No unsupported claims when composition is unknown.
    card["ingredients"] = [row("garlic", "Bawang putih")]
    card["ingredients_complete"] = False
    assert client.post("/api/v1/food-swaps", json=card).json()["items"] == []
