import os
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4

import pytest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.auth import User
from app.core.config import Settings
from app.core.errors import ApiError
from app.models.entities import FoodEvent, IdempotencyRequest, RecordBatch, SymptomEvent
from seeds.catalog import seed_catalog, stable_id
from tests.test_analysis import FakeGemini
from tests.test_media import MemoryStorage, image_bytes
from tests.test_records import journal_payload, save


def test_failure_after_event_inserts_rolls_back_entire_transaction(account, db_engine, monkeypatch):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()

    def fail(*args, **kwargs):
        raise ApiError(503, "synthetic_write_failure", "Coba lagi.")

    monkeypatch.setattr("app.services.records.versioned_update", fail)
    assert save(client, draft).status_code == 503
    with Session(db_engine) as db:
        for model in (FoodEvent, SymptomEvent, RecordBatch, IdempotencyRequest):
            assert db.scalar(select(func.count()).select_from(model)) == 0
    assert client.get(f"/api/v1/drafts/{draft['id']}").json()["persistence_status"] == "draft"


def test_different_keys_concurrently_cannot_commit_same_draft_twice(account, db_engine):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda key: save(client, draft, key=key), ["first", "second"]))
    assert sorted(r.status_code for r in responses) == [200, 409]
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(RecordBatch)) == 1


def test_quota_and_no_extra_model_calls_during_review(account):
    client, _ = account
    provider = FakeGemini()
    client.app.state.gemini = provider
    client.app.state.settings = client.app.state.settings.model_copy(update={"ai_daily_limit": 1})
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    payload = {
        "request_id": str(uuid4()),
        "text": "sore kembung, nggak mual",
        "reference_date": "2026-11-10",
    }
    draft = client.post("/api/v1/analysis/journal", json=payload).json()["draft"]
    client.get(f"/api/v1/drafts/{draft['id']}")
    client.patch(
        f"/api/v1/drafts/{draft['id']}",
        json={"version": 1, "intent": "journal", "content": draft["content"]},
    )
    assert (
        client.post(
            "/api/v1/analysis/journal", json={**payload, "request_id": str(uuid4())}
        ).status_code
        == 429
    )
    assert provider.calls == 1


@pytest.mark.skipif(not os.environ.get("TEST_DATABASE_URL"), reason="Requires PostgreSQL row locks")
def test_concurrent_ai_requests_are_deduplicated_under_postgres_profile_lock(account):
    client, _ = account
    provider = FakeGemini()
    client.app.state.gemini = provider
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    payload = {"request_id": str(uuid4()), "text": "nggak mual", "reference_date": "2026-11-10"}
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(
            pool.map(lambda _: client.post("/api/v1/analysis/journal", json=payload), range(2))
        )
    assert all(response.status_code == 200 for response in responses)
    assert provider.calls == 1


def test_cross_owner_mutations_are_denied_across_all_private_resources(account, db_engine):
    client, context = account
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    batch = save(client, draft).json()
    another_draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    food_id = batch["food_event_ids"][0]
    food = client.get(f"/api/v1/events/{food_id}").json()
    plan = client.post(
        "/api/v1/meal-plans",
        json={
            "menu_id": str(stable_id("chicken-rice")),
            "scheduled_at": "2026-11-10T19:00:00+07:00",
        },
    ).json()
    item = client.post(
        "/api/v1/shopping-items", json={"name": "Custom", "quantity": 1, "unit": "buah"}
    ).json()
    storage = MemoryStorage()
    client.app.state.storage = storage
    media = client.post(
        "/api/v1/media", files={"file": ("test.png", image_bytes(), "image/png")}
    ).json()
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    cases = [
        ("patch", f"/drafts/{another_draft['id']}", {"version": 1, **journal_payload()}),
        ("patch", f"/events/{food_id}", {"kind": "food", "version": 1, "payload": food["payload"]}),
        (
            "patch",
            f"/meal-plans/{plan['id']}",
            {"version": 1, "scheduled_at": "2026-11-11T19:00:00+07:00"},
        ),
        ("patch", f"/shopping-items/{item['id']}", {"version": 1, "quantity": 1, "checked": True}),
    ]
    for method, path, payload in cases:
        assert getattr(client, method)("/api/v1" + path, json=payload).status_code == 404
    for path in (
        f"/drafts/{another_draft['id']}?version=1",
        f"/events/{food_id}?version=1",
        f"/meal-plans/{plan['id']}?version=1",
        f"/shopping-items/{item['id']}?version=1",
        f"/media/{media['id']}",
    ):
        assert client.delete("/api/v1" + path).status_code == 404
    assert client.get(f"/api/v1/media/{media['id']}/access").status_code == 404
    assert client.get("/api/v1/dashboard?date=2026-11-10").json()["events"] == []


def test_optional_provider_config_can_be_blank_but_production_cannot_use_sqlite():
    settings = Settings(
        _env_file=None,
        database_url="sqlite+pysqlite:///:memory:",
        supabase_url="https://example.supabase.co",
        gemini_model="",
        gemini_api_key="",
        supabase_service_role_key="",
    )
    assert settings.gemini_model is None and settings.gemini_api_key is None
    with pytest.raises(ValueError):
        Settings(
            _env_file=None,
            app_env="production",
            database_url="sqlite+pysqlite:///:memory:",
            supabase_url="https://example.supabase.co",
        )
