from uuid import uuid4

from app.core.auth import User
from tests.test_records import journal_payload, save


def test_symptom_edit_can_unlink_without_deleting_food(account):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    saved = save(client, draft).json()
    symptom_id = saved["symptom_event_ids"][0]
    row = client.get(f"/api/v1/events/{symptom_id}").json()
    card = row["payload"]
    card["linked_food_index"] = None
    card["linked_food_event_id"] = None
    edited = client.patch(
        f"/api/v1/events/{symptom_id}",
        json={"kind": "symptom", "version": row["version"], "payload": card},
    )
    assert edited.status_code == 200
    assert edited.json()["linked_event_ids"] == []
    assert client.get(f"/api/v1/events/{saved['food_event_ids'][0]}").status_code == 200
    assert client.delete(f"/api/v1/events/{symptom_id}?version=1").status_code == 409
    assert (
        client.delete(f"/api/v1/events/{symptom_id}?version={edited.json()['version']}").status_code
        == 204
    )


def test_edit_cannot_link_another_owners_food(account):
    client, context = account
    saved = save(client, client.post("/api/v1/drafts", json=journal_payload()).json()).json()
    other_food = saved["food_event_ids"][0]
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    own = save(
        client, client.post("/api/v1/drafts", json=journal_payload()).json(), key="other-save"
    ).json()
    event = client.get(f"/api/v1/events/{own['symptom_event_ids'][0]}").json()
    card = event["payload"]
    card["linked_food_index"] = None
    card["linked_food_event_id"] = other_food
    assert (
        client.patch(
            f"/api/v1/events/{event['id']}",
            json={"kind": "symptom", "version": event["version"], "payload": card},
        ).status_code
        == 404
    )
    assert client.get(f"/api/v1/events/{event['id']}").json()["version"] == event["version"]


def test_other_symptom_keeps_label_and_absent_severity(account):
    client, _ = account
    payload = journal_payload()
    payload["content"]["symptoms"] = [
        {
            "code": "other",
            "label": "Keluhan lain dicatat pengguna",
            "present": True,
            "time": {
                "date": "2026-11-10",
                "period": "evening",
                "precision": "approximate",
                "confirmed": True,
            },
        }
    ]
    result = save(client, client.post("/api/v1/drafts", json=payload).json()).json()
    row = client.get(f"/api/v1/events/{result['symptom_event_ids'][0]}").json()
    assert row["payload"]["severity"] is None
    assert row["payload"]["label"] == "Keluhan lain dicatat pengguna"
