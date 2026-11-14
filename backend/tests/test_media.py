import io
from uuid import uuid4

from PIL import Image

from app.core.auth import User


class MemoryStorage:
    def __init__(self):
        self.files = {}

    def upload(self, path, data):
        self.files[path] = data

    def download(self, path):
        return self.files[path]

    def sign(self, path):
        assert path in self.files
        return "https://private.example/signed-test-url"

    def delete(self, path):
        self.files.pop(path, None)


def image_bytes():
    data = io.BytesIO()
    Image.new("RGB", (12, 12), "white").save(data, format="PNG")
    return data.getvalue()


def test_photo_is_private_owned_and_can_be_deleted(account):
    client, context = account
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    storage = MemoryStorage()
    client.app.state.storage = storage
    response = client.post(
        "/api/v1/media", files={"file": ("photo.png", image_bytes(), "image/png")}
    )
    assert response.status_code == 201
    media_id = response.json()["id"]
    assert response.json()["private"] is True
    assert client.get(f"/api/v1/media/{media_id}/access").json()["expires_in"] == 60
    original = context["user"]
    context["user"] = User(uuid4())
    client.post("/api/v1/me/profile")
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    assert client.get(f"/api/v1/media/{media_id}/access").status_code == 404
    assert client.delete(f"/api/v1/media/{media_id}").status_code == 404
    context["user"] = original
    assert client.delete(f"/api/v1/media/{media_id}").status_code == 204
    assert not storage.files


def test_invalid_image_and_size_are_rejected_before_storage(account):
    client, _ = account
    client.put("/api/v1/me/consents", json={"basic": True, "ai": True})
    storage = MemoryStorage()
    client.app.state.storage = storage
    assert (
        client.post(
            "/api/v1/media", files={"file": ("fake.jpg", b"not an image", "image/jpeg")}
        ).status_code
        == 422
    )
    assert (
        client.post(
            "/api/v1/media",
            files={"file": ("huge.jpg", b"x" * (5 * 1024 * 1024 + 1), "image/jpeg")},
        ).status_code
        == 413
    )
    assert not storage.files
