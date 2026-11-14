from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy.orm import Session
from sqlalchemy.pool import NullPool

from app.core.config import Settings
from app.core.database import make_engine
from app.main import create_app
from app.models.entities import Media
from tests.test_media import MemoryStorage


def test_serverless_lifespan_does_not_start_retention_loop(settings, db_engine, monkeypatch):
    calls = []

    async def unexpected_thread(*args, **kwargs):
        calls.append(args)

    monkeypatch.setattr("app.main.asyncio.to_thread", unexpected_thread)
    settings = settings.model_copy(update={"runtime_mode": "serverless"})
    with TestClient(create_app(settings, engine=db_engine)) as client:
        assert client.get("/health").json() == {"status": "ok"}
        assert client.get("/ready").status_code == 200
        assert calls == []


def test_vercel_entrypoint_exports_asgi_app_without_migrating(settings, monkeypatch):
    import runpy

    monkeypatch.setattr("app.core.config.get_settings", lambda: settings)
    namespace = runpy.run_path("index.py")
    app = namespace["app"]
    try:
        assert app.state.settings.runtime_mode == "serverless"
        assert "/api/v1/analysis/journal" in app.openapi()["paths"]
    finally:
        app.state.engine.dispose()


def test_cron_requires_exact_secret_and_preserves_unexpired_photos(settings, db_engine):
    settings = settings.model_copy(
        update={
            "runtime_mode": "serverless",
            "cron_secret": SecretStr("synthetic-cron-secret"),
        }
    )
    app = create_app(settings, engine=db_engine)
    storage = MemoryStorage()
    app.state.storage = storage
    for label, expires in (
        ("expired", datetime.now(UTC) - timedelta(days=1)),
        ("retained", None),
        ("future", datetime.now(UTC) + timedelta(hours=12)),
    ):
        storage.files[label] = b"synthetic"
        with Session(db_engine) as db, db.begin():
            db.add(
                Media(owner_id=uuid4(), path=label, mime="image/jpeg", size=9, expires_at=expires)
            )
    with TestClient(app) as client:
        assert client.get("/api/internal/retention").status_code == 401
        assert (
            client.get(
                "/api/internal/retention", headers={"Authorization": "Bearer incorrect"}
            ).status_code
            == 401
        )
        assert len(storage.files) == 3
        result = client.get(
            "/api/internal/retention", headers={"Authorization": "Bearer synthetic-cron-secret"}
        )
        assert result.status_code == 200
        assert result.json()["deleted"] == 1
        assert set(storage.files) == {"retained", "future"}
        assert (
            client.get(
                "/api/internal/retention", headers={"Authorization": "Bearer synthetic-cron-secret"}
            ).json()["deleted"]
            == 0
        )


def test_serverless_database_uses_external_pooler_without_instance_pool():
    settings = Settings(
        _env_file=None,
        runtime_mode="serverless",
        database_url="postgresql+psycopg://test:test@localhost/test",
        supabase_url="https://example.supabase.co",
    )
    engine = make_engine(settings)
    try:
        assert isinstance(engine.pool, NullPool)
    finally:
        engine.dispose()


def test_serverless_request_limit_rejects_photo_before_storage(account):
    client, _ = account
    client.app.state.settings.max_photo_bytes = 1024
    storage = MemoryStorage()
    client.app.state.storage = storage
    response = client.post(
        "/api/v1/media", files={"file": ("synthetic.jpg", b"x" * 1025, "image/jpeg")}
    )
    assert response.status_code == 413
    assert not storage.files
