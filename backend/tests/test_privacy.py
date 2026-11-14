import io
import json
from datetime import UTC, datetime, timedelta
from uuid import uuid4
from zipfile import ZipFile

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import User
from app.core.errors import ApiError
from app.models.entities import Media
from app.services.privacy import cleanup_expired
from tests.test_media import MemoryStorage, image_bytes


def test_export_and_delete_only_current_owner(account):
    client, context = account
    storage = MemoryStorage()
    client.app.state.storage = storage
    owner = context["user"]
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    media = client.post(
        "/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")}
    ).json()
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    other = context["user"]
    context["user"] = owner
    response = client.get("/api/v1/me/data/export")
    assert response.status_code == 200
    assert response.headers["cache-control"] == "no-store"
    with ZipFile(io.BytesIO(response.content)) as archive:
        data = json.loads(archive.read("data.json"))
        assert f"photos/{media['id']}.jpg" in archive.namelist()
        for rows in data["tables"].values():
            assert all(row["owner_id"] == str(owner.id) for row in rows)
    assert client.delete("/api/v1/me/data").status_code == 422
    assert client.delete("/api/v1/me/data?confirm=true").status_code == 204
    assert client.get("/api/v1/me/profile").status_code == 404
    assert not storage.files
    assert client.delete("/api/v1/me/data?confirm=true").status_code == 204
    context["user"] = other
    assert client.get("/api/v1/me/profile").status_code == 200


def test_retention_expiry_and_preference_removal(account, db_engine):
    client, _ = account
    storage = MemoryStorage()
    client.app.state.storage = storage
    assert (
        client.post(
            "/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")}
        ).status_code
        == 403
    )
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    media = client.post(
        "/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")}
    ).json()
    with Session(db_engine) as db, db.begin():
        row = db.scalar(select(Media))
        assert row.expires_at is not None
        row.expires_at = datetime.now(UTC) - timedelta(seconds=1)
    assert client.get(f"/api/v1/media/{media['id']}/access").status_code == 410
    cleanup_expired(db_engine, storage)
    assert not storage.files
    profile = client.get("/api/v1/me/profile").json()
    profile = client.patch(
        "/api/v1/me/profile", json={"version": profile["version"], "save_photos": True}
    ).json()
    client.post("/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")})
    with Session(db_engine) as db:
        assert db.scalar(select(Media)).expires_at is None
    assert (
        client.patch(
            "/api/v1/me/profile", json={"version": profile["version"], "save_photos": False}
        ).status_code
        == 200
    )
    assert not storage.files


def test_storage_failure_does_not_claim_delete_succeeded(account):
    client, _ = account
    storage = MemoryStorage()
    client.app.state.storage = storage
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    client.post("/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")})

    def fail(_):
        raise ApiError(503, "storage_unavailable", "Coba lagi.")

    storage.delete = fail
    assert client.delete("/api/v1/me/data?confirm=true").status_code == 503
    assert client.get("/api/v1/me/profile").status_code == 200
