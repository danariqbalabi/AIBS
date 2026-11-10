from concurrent.futures import ThreadPoolExecutor

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.entities import FoodEvent, IdempotencyRequest, RecordBatch, SymptomEvent


def journal_payload():
    time = {"date": "2026-11-10", "period": "midday", "precision": "approximate", "confirmed": True}
    return {
        "intent": "journal",
        "content": {
            "foods": [{"name": "Ayam kecap", "consumed": True, "time": time}],
            "symptoms": [
                {
                    "code": "bloating",
                    "present": True,
                    "time": {**time, "period": "late_afternoon"},
                    "linked_food_index": 0,
                },
                {"code": "nausea", "present": False, "time": {**time, "period": "late_afternoon"}},
            ],
        },
    }


def save(client, draft, key="save-1", version=1):
    return client.post(
        f"/api/v1/drafts/{draft['id']}/commit",
        json={"version": version, "confirmed": True},
        headers={"Idempotency-Key": key},
    )


def test_commit_is_atomic_idempotent_and_preserves_negation(account, db_engine):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    first = save(client, draft)
    assert first.status_code == 200
    assert save(client, draft).json() == first.json()
    assert save(client, draft, version=2).status_code == 409
    assert save(client, draft, key="different-key").status_code == 409
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(FoodEvent)) == 1
        assert db.scalar(select(func.count()).select_from(SymptomEvent)) == 2
        assert db.scalar(select(func.count()).select_from(IdempotencyRequest)) == 1
        assert sum(event.payload["present"] for event in db.scalars(select(SymptomEvent))) == 1


def test_before_meal_and_unconfirmed_time_rollback_entire_batch(account, db_engine):
    client, _ = account
    payload = journal_payload()
    payload["content"]["symptoms"][0]["time"]["confirmed"] = False
    draft = client.post("/api/v1/drafts", json=payload).json()
    assert save(client, draft).status_code == 422
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(RecordBatch)) == 0
        assert db.scalar(select(func.count()).select_from(FoodEvent)) == 0
        assert db.scalar(select(func.count()).select_from(IdempotencyRequest)) == 0
    payload = journal_payload()
    payload["intent"] = "before_meal"
    draft = client.post("/api/v1/drafts", json=payload).json()
    assert save(client, draft).status_code == 422


def test_concurrent_duplicate_save_creates_one_batch(account, db_engine):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    with ThreadPoolExecutor(max_workers=2) as executor:
        responses = list(executor.map(lambda _: save(client, draft), range(2)))
    assert [r.status_code for r in responses] == [200, 200]
    assert responses[0].json() == responses[1].json()
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(RecordBatch)) == 1


def test_profile_change_requires_review_before_commit(account):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    profile = client.get("/api/v1/me/profile").json()
    client.patch("/api/v1/me/profile", json={"version": profile["version"], "display_name": "Baru"})
    assert save(client, draft).status_code == 409
