from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import FoodEvent
from tests.test_records import journal_payload, save


def test_only_saved_foods_qualify_and_retries_do_not_increment(account):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    assert client.get("/api/v1/dashboard").json()["streak"]["current_days"] == 0
    result = save(client, draft)
    assert result.status_code == 200
    save(client, draft)
    streak = client.get("/api/v1/dashboard").json()["streak"]
    assert streak["current_days"] == streak["best_days"] == 1
    assert streak["completed_today"] is True
    client.delete(f"/api/v1/events/{result.json()['food_event_ids'][0]}?version=1")
    # Symptoms and negated observations remain, but cannot sustain a meal streak.
    assert client.get("/api/v1/dashboard").json()["streak"]["current_days"] == 0


def test_consecutive_days_grace_until_tomorrow_and_timezone(account, db_engine):
    client, _ = account
    for index, stamp in enumerate(
        [
            datetime(2026, 11, 8, 18, 30, tzinfo=UTC),  # Nov 9 in Jakarta
            datetime(2026, 11, 9, 18, 30, tzinfo=UTC),  # Nov 10
            datetime(2026, 11, 10, 18, 30, tzinfo=UTC),  # Nov 11
        ]
    ):
        payload = journal_payload()
        payload["content"]["foods"][0]["name"] = f"Meal {index}"
        draft = client.post("/api/v1/drafts", json=payload).json()
        result = save(client, draft, key=f"day-{index}").json()
        with Session(db_engine) as db:
            row = db.scalar(
                select(FoodEvent).where(FoodEvent.id == UUID(result["food_event_ids"][0]))
            )
            row.created_at = stamp
            db.commit()
    streak = client.get("/api/v1/dashboard?date=2026-11-11").json()["streak"]
    assert streak["current_days"] == streak["best_days"] == 3
    assert streak["completed_today"] is True
    waiting = client.get("/api/v1/dashboard?date=2026-11-12").json()["streak"]
    assert waiting["current_days"] == 3
    assert waiting["completed_today"] is False
    missed = client.get("/api/v1/dashboard?date=2026-11-13").json()["streak"]
    assert missed["current_days"] == 0
    assert missed["best_days"] == 3
