from uuid import uuid4

from app.core.auth import User
from tests.test_records import journal_payload, save


def test_history_paginates_edits_and_deletes_without_deleting_symptoms(account):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    batch = save(client, draft).json()
    first = client.get("/api/v1/events?limit=2").json()
    second = client.get(
        "/api/v1/events", params={"limit": 2, "cursor": first["next_cursor"]}
    ).json()
    ids = [e["id"] for e in first["items"] + second["items"]]
    assert len(ids) == len(set(ids)) == 3
    event_id = batch["food_event_ids"][0]
    food = client.get(f"/api/v1/events/{event_id}").json()
    payload = food["payload"]
    payload["name"] = "Ayam dikoreksi"
    assert (
        client.patch(
            f"/api/v1/events/{event_id}",
            json={
                "kind": "food",
                "version": 1,
                "payload": payload,
            },
        ).status_code
        == 200
    )
    assert client.delete(f"/api/v1/events/{event_id}?version=1").status_code == 409
    assert client.delete(f"/api/v1/events/{event_id}?version=2").status_code == 204
    remaining = client.get("/api/v1/events").json()["items"]
    assert len(remaining) == 2
    assert all(e["kind"] == "symptom" and e["linked_event_ids"] == [] for e in remaining)


def test_history_is_owned_and_invalid_cursors_are_422(account):
    client, context = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    event_id = save(client, draft).json()["food_event_ids"][0]
    assert client.get("/api/v1/events?cursor=!!!").status_code == 422
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    assert client.get("/api/v1/events").json()["items"] == []
    assert client.get(f"/api/v1/events/{event_id}").status_code == 404
    assert client.delete(f"/api/v1/events/{event_id}?version=1").status_code == 404
