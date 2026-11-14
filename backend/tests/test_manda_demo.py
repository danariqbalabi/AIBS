from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import event
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.main import create_app
from seeds.catalog import seed_catalog


def test_manda_history_is_complete_isolated_and_seeded_only_once(settings, db_engine):
    with Session(db_engine) as db, db.begin():
        seed_catalog(db)
    app = create_app(settings, engine=db_engine)
    owner = User(uuid4(), anonymous=True)
    app.dependency_overrides[get_user] = lambda: owner
    with TestClient(app) as client:
        selects = []

        def collect(conn, cursor, statement, parameters, context, executemany):
            if statement.lstrip().upper().startswith("SELECT"):
                selects.append(statement)

        event.listen(db_engine, "before_cursor_execute", collect)
        try:
            response = client.post("/api/v1/demo/sessions", json={"template": "manda"})
        finally:
            event.remove(db_engine, "before_cursor_execute", collect)
        assert response.status_code == 200
        # Fourteen days must not trigger repeated profile/catalog queries per food.
        assert len(selects) < 14
        profile = client.get("/api/v1/me/profile").json()
        assert profile["display_name"] == "Manda"
        assert client.get("/api/v1/me/consents").json()["ai"] is False
        report = client.get("/api/v1/summaries?days=30").json()
        assert report["logged_days"] == 14
        assert report["food_count"] == 28
        assert report["symptom_count"] == 14
        assert len(report["evidence"]["links"]) == 14
        assert report["status"] == "descriptive_only"
        week = client.get("/api/v1/summaries?days=7").json()
        assert week["logged_days"] == 7
        assert week["food_count"] == 14
        assert week["status"] == "descriptive_only"
        assert client.get("/api/v1/dashboard").json()["streak"]["current_days"] == 14
        assert client.post("/api/v1/demo/sessions", json={"template": "manda"}).status_code == 200
        assert client.get("/api/v1/summaries?days=30").json()["food_count"] == 28
        # Another owner starts with their own independent records.
        owner = User(uuid4(), anonymous=True)
        assert client.post("/api/v1/demo/sessions", json={"template": "nadia"}).status_code == 200
        assert client.get("/api/v1/summaries?days=30").json()["food_count"] == 0
