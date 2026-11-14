from pathlib import Path
from uuid import uuid4

from app.core.errors import ApiError
from app.schemas.domain import DraftContent
from tests.test_media import MemoryStorage, image_bytes


class FakeGemini:
    def __init__(self, fixture="journal-v1.json", fail=False):
        self.fixture, self.fail, self.calls = fixture, fail, 0

    def generate(self, feature, **kwargs):
        self.calls += 1
        if self.fail:
            raise ApiError(503, "ai_unavailable", "Isi manual dulu.")
        path = Path(__file__).resolve().parents[2] / "docs/fixtures/backend" / self.fixture
        return DraftContent.model_validate_json(path.read_text(encoding="utf-8")), {
            "input_tokens": 10,
            "output_tokens": 20,
        }


def test_consent_revocation_blocks_ai_and_retry_does_not_call_model_twice(account):
    client, _ = account
    provider = FakeGemini()
    client.app.state.gemini = provider
    payload = {
        "request_id": str(uuid4()),
        "text": "siang ayam, sore kembung, nggak mual",
        "reference_date": "2026-11-10",
    }
    assert client.post("/api/v1/analysis/journal", json=payload).status_code == 403
    assert provider.calls == 0
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    response = client.post("/api/v1/analysis/journal", json=payload)
    assert response.status_code == 200
    assert client.post("/api/v1/analysis/journal", json=payload).json() == response.json()
    assert provider.calls == 1
    symptoms = response.json()["draft"]["content"]["symptoms"]
    assert any(s["present"] is False for s in symptoms)
    assert all(s["time"]["confirmed"] is False for s in symptoms)
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    assert (
        client.post(
            "/api/v1/analysis/journal", json={**payload, "request_id": str(uuid4())}
        ).status_code
        == 403
    )
    assert provider.calls == 1


def test_failure_leaves_manual_path_available_and_no_automatic_retry(account):
    client, _ = account
    provider = FakeGemini(fail=True)
    client.app.state.gemini = provider
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    payload = {"request_id": str(uuid4()), "text": "sore kembung", "reference_date": "2026-11-10"}
    assert client.post("/api/v1/analysis/journal", json=payload).status_code == 503
    assert client.post("/api/v1/analysis/journal", json=payload).status_code == 409
    assert provider.calls == 1
    assert (
        client.post(
            "/api/v1/drafts", json={"intent": "journal", "content": {"story": payload["text"]}}
        ).status_code
        == 201
    )


def test_photo_uses_owned_media_and_keeps_sauce_unknown(account):
    client, _ = account
    storage = MemoryStorage()
    client.app.state.storage = storage
    client.app.state.gemini = FakeGemini("photo-v1.json")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    media_id = client.post(
        "/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")}
    ).json()["id"]
    response = client.post(
        "/api/v1/analysis/photo",
        json={
            "request_id": str(uuid4()),
            "media_id": media_id,
            "intent": "before_meal",
            "reference_date": "2026-11-10",
        },
    )
    assert response.status_code == 200
    content = response.json()["draft"]["content"]
    assert any(i["certainty"] == "unknown" for i in content["foods"][0]["ingredients"])
    assert content["foods"][0]["consumed"] is False
    assert content["foods"][0]["time"] is None
    assert storage.files == {}
    assert client.get(f"/api/v1/media/{media_id}/access").status_code == 404
    assert response.json()["draft"]["media_id"] is None


def test_opted_in_photo_is_kept_and_failed_temporary_analysis_discards_photo(account):
    client, _ = account
    storage = MemoryStorage()
    client.app.state.storage = storage
    client.app.state.gemini = FakeGemini("photo-v1.json")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    profile = client.get("/api/v1/me/profile").json()
    client.patch("/api/v1/me/profile", json={"version": profile["version"], "save_photos": True})
    media = client.post(
        "/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")}
    ).json()
    body = {
        "request_id": str(uuid4()),
        "media_id": media["id"],
        "intent": "before_meal",
        "reference_date": "2026-11-14",
    }
    first = client.post("/api/v1/analysis/photo", json=body)
    assert first.status_code == 200
    assert first.json()["draft"]["media_id"] == media["id"]
    assert len(storage.files) == 1
    assert client.post("/api/v1/analysis/photo", json=body).json() == first.json()
    profile = client.get("/api/v1/me/profile").json()
    client.patch("/api/v1/me/profile", json={"version": profile["version"], "save_photos": False})
    client.app.state.gemini = FakeGemini(fail=True)
    media = client.post(
        "/api/v1/media", files={"file": ("food.png", image_bytes(), "image/png")}
    ).json()
    body.update(request_id=str(uuid4()), media_id=media["id"])
    assert client.post("/api/v1/analysis/photo", json=body).status_code == 503
    assert storage.files == {}
