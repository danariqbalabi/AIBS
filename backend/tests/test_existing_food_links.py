from uuid import uuid4

from app.core.auth import User


def food_payload():
    return {
        "intent": "consumed",
        "content": {
            "foods": [
                {
                    "name": "Nasi demo",
                    "consumed": True,
                    "time": {
                        "date": "2026-11-14",
                        "occurred_at": "2026-11-14T12:00:00+07:00",
                        "precision": "exact",
                        "confirmed": True,
                    },
                }
            ]
        },
    }


def symptom_payload(food_id, hour="15"):
    return {
        "intent": "journal",
        "content": {
            "symptoms": [
                {
                    "code": "bloating",
                    "present": True,
                    "severity": 2,
                    "linked_food_event_id": food_id,
                    "time": {
                        "date": "2026-11-14",
                        "occurred_at": f"2026-11-14T{hour}:00:00+07:00",
                        "precision": "exact",
                        "confirmed": True,
                    },
                }
            ]
        },
    }


def commit(client, payload, key):
    draft = client.post("/api/v1/drafts", json=payload).json()
    return client.post(
        f"/api/v1/drafts/{draft['id']}/commit",
        json={"version": draft["version"], "confirmed": True},
        headers={"Idempotency-Key": key},
    )


def test_existing_food_link_does_not_duplicate_consumption(account):
    client, _ = account
    food_id = commit(client, food_payload(), "food-one").json()["food_event_ids"][0]
    assert commit(client, symptom_payload(food_id), "symptom-one").status_code == 200
    events = client.get("/api/v1/events").json()["items"]
    assert len(events) == 2
    assert next(e for e in events if e["kind"] == "symptom")["linked_event_ids"] == [food_id]


def test_cross_owner_food_link_and_future_link_are_rejected_atomically(account):
    client, context = account
    food_id = commit(client, food_payload(), "food-two").json()["food_event_ids"][0]
    assert commit(client, symptom_payload(food_id, "11"), "future-link").status_code == 422
    assert len(client.get("/api/v1/events").json()["items"]) == 1
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    assert commit(client, symptom_payload(food_id), "cross-owner").status_code == 404
    assert client.get("/api/v1/events").json()["items"] == []
