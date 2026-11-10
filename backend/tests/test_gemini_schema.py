import json

import httpx
import pytest
from pydantic import SecretStr

from app.core.errors import ApiError
from app.integrations.gemini import Gemini
from app.integrations.gemini_schema import draft_generation_schema
from app.schemas.domain import DraftContent
from tests.test_providers import http_mock


def test_generation_schema_handles_nested_foods_without_provider_rejected_hints():
    schema = draft_generation_schema()
    properties = schema["properties"]
    assert {"story", "foods", "symptoms", "questions"} <= properties.keys()
    food = properties["foods"]["items"]
    assert food["type"] == "object"
    assert "name" in food["required"]
    time = next(item for item in food["properties"]["time"]["anyOf"] if item["type"] == "object")
    assert time["properties"]["date"]["format"] == "date"
    assert schema["additionalProperties"] is False
    serialized = json.dumps(schema)
    for rejected_hint in ("$defs", "$ref", "default", "maxItems", "minLength", "exclusiveMinimum"):
        assert '"' + rejected_hint + '"' not in serialized
    assert '"uuid"' not in serialized
    # The public API contract retains full limits; only provider generation hints change.
    original = DraftContent.model_json_schema()
    assert original["properties"]["foods"]["maxItems"] == 20


def test_adapter_sends_compatible_schema_but_rejects_invalid_quantity(settings, monkeypatch):
    settings = settings.model_copy(
        update={
            "gemini_api_key": SecretStr("test-only-key"),
            "gemini_model": "test-model",
        }
    )

    def handler(request):
        schema = json.loads(request.content)["generationConfig"]["responseJsonSchema"]
        assert "$defs" not in schema
        assert schema["properties"]["foods"]["items"]["type"] == "object"
        invalid = {
            "foods": [
                {
                    "name": "Ayam",
                    "ingredients": [
                        {"display_name": "Ayam", "quantity": 0, "unit": "g"},
                    ],
                }
            ]
        }
        return httpx.Response(
            200,
            json={
                "candidates": [
                    {
                        "finishReason": "STOP",
                        "content": {"parts": [{"text": json.dumps(invalid)}]},
                    }
                ]
            },
        )

    http_mock(monkeypatch, handler)
    with pytest.raises(ApiError) as exc:
        Gemini(settings).generate(
            "journal_to_draft",
            reference_date="2026-11-10",
            timezone="Asia/Jakarta",
            text="ayam",
        )
    assert exc.value.code == "ai_invalid_output"
