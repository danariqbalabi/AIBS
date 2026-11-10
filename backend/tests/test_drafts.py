from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.main import create_app
from app.models.entities import FoodEvent


def manual_payload(intent="before_meal"):
    return {
        "intent": intent,
        "content": {
            "foods": [
                {
                    "name": "Nasi ayam",
                    "consumed": False,
                    "ingredients": [
                        {"display_name": "Saus", "certainty": "unknown"},
                    ],
                }
            ],
        },
    }


def test_draft_review_and_save_draft_do_not_create_food_events(account, db_engine):
    client, _ = account
    response = client.post("/api/v1/drafts", json=manual_payload())
    assert response.status_code == 201
    draft = response.json()
    patched = client.patch(
        f"/api/v1/drafts/{draft['id']}",
        json={
            **manual_payload(),
            "version": draft["version"],
        },
    )
    assert patched.status_code == 200
    assert patched.json()["persistence_status"] == "draft"
    assert (
        client.patch(
            f"/api/v1/drafts/{draft['id']}",
            json={
                **manual_payload(),
                "version": draft["version"],
            },
        ).status_code
        == 409
    )
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(FoodEvent)) == 0


def test_draft_survives_app_reopen_and_is_owned(account, db_engine, settings):
    client, context = account
    draft = client.post("/api/v1/drafts", json=manual_payload()).json()
    app = create_app(settings, engine=db_engine)
    owner = context["user"]
    app.dependency_overrides[get_user] = lambda: owner
    with TestClient(app) as reopened:
        assert reopened.get(f"/api/v1/drafts/{draft['id']}").json()["content"] == draft["content"]
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    assert client.get(f"/api/v1/drafts/{draft['id']}").status_code == 404
    assert client.delete(f"/api/v1/drafts/{draft['id']}?version=1").status_code == 404


def test_discarded_draft_is_not_listed(account):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=manual_payload()).json()
    assert client.delete(f"/api/v1/drafts/{draft['id']}?version=1").status_code == 204
    assert client.get("/api/v1/drafts").json()["items"] == []
