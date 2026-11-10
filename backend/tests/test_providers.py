import json

import httpx
import pytest
from pydantic import SecretStr

from app.core.errors import ApiError
from app.integrations.gemini import Gemini
from app.integrations.storage import SupabaseStorage


def http_mock(monkeypatch, handler):
    original = httpx.Client
    monkeypatch.setattr(
        httpx, "Client", lambda **kwargs: original(transport=httpx.MockTransport(handler), **kwargs)
    )


def test_gemini_http_contract_and_validated_response(settings, monkeypatch):
    settings = settings.model_copy(
        update={"gemini_api_key": SecretStr("test-only-key"), "gemini_model": "test-model"}
    )
    requests = []

    def handler(request):
        requests.append(request)
        assert request.headers["x-goog-api-key"] == "test-only-key"
        assert "test-only-key" not in str(request.url)
        body = json.loads(request.content)
        assert body["generationConfig"]["responseJsonSchema"]["type"] == "object"
        assert body["generationConfig"]["responseMimeType"] == "application/json"
        return httpx.Response(
            200,
            json={
                "candidates": [
                    {
                        "finishReason": "STOP",
                        "content": {
                            "parts": [{"text": '{"foods": [], "symptoms": [], "questions": []}'}]
                        },
                    }
                ],
                "usageMetadata": {"promptTokenCount": 12, "candidatesTokenCount": 6},
            },
        )

    http_mock(monkeypatch, handler)
    content, usage = Gemini(settings).generate(
        "journal_to_draft", reference_date="2026-11-10", timezone="Asia/Jakarta", text="nggak mual"
    )
    assert content.foods == []
    assert usage == {"input_tokens": 12, "output_tokens": 6}
    assert len(requests) == 1


@pytest.mark.parametrize("status,expected", [(429, 429), (500, 503), (200, 502)])
def test_gemini_failures_do_not_reflect_provider_body(settings, monkeypatch, status, expected):
    settings = settings.model_copy(
        update={"gemini_api_key": SecretStr("test-only-key"), "gemini_model": "test-model"}
    )
    calls = []

    def handler(request):
        calls.append(request)
        return httpx.Response(status, text="private provider body must never be reflected")

    http_mock(monkeypatch, handler)
    with pytest.raises(ApiError) as exc:
        Gemini(settings).generate(
            "journal_to_draft",
            reference_date="2026-11-10",
            timezone="Asia/Jakarta",
            text="private journal",
        )
    assert exc.value.status == expected
    assert "private" not in exc.value.message
    assert len(calls) == 1


def test_storage_requires_private_bucket_and_uses_server_auth(settings, monkeypatch):
    settings = settings.model_copy(update={"supabase_service_role_key": SecretStr("test-only-key")})
    paths = []

    def handler(request):
        paths.append(request.url.path)
        assert request.headers["Authorization"] == "Bearer test-only-key"
        if "/bucket/" in request.url.path:
            return httpx.Response(200, json={"public": False})
        if "/sign/" in request.url.path:
            assert json.loads(request.content)["expiresIn"] == 60
            return httpx.Response(
                200, json={"signedURL": "/object/sign/aibs-food-photos/test.jpg?token=synthetic"}
            )
        return httpx.Response(200, json={})

    http_mock(monkeypatch, handler)
    storage = SupabaseStorage(settings)
    storage.upload("test.jpg", b"synthetic-jpeg-bytes")
    assert "/storage/v1/object/sign/" in storage.sign("test.jpg")
    assert len(paths) == 4


def test_storage_refuses_public_bucket(settings, monkeypatch):
    settings = settings.model_copy(update={"supabase_service_role_key": SecretStr("test-only-key")})
    http_mock(monkeypatch, lambda request: httpx.Response(200, json={"public": True}))
    with pytest.raises(ApiError) as exc:
        SupabaseStorage(settings).upload("test.jpg", b"test")
    assert exc.value.code == "private_bucket_required"
