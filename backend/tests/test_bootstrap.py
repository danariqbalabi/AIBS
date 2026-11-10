from uuid import UUID

import pytest
from pydantic import ValidationError

from app.core.config import Settings


def test_health_and_request_id(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
    assert UUID(response.headers["X-Request-ID"])
    assert "database_url" not in response.text


def test_settings_fail_when_required_configuration_missing(monkeypatch):
    for name in ("DATABASE_URL", "SUPABASE_URL"):
        monkeypatch.delenv(name, raising=False)
    with pytest.raises(ValidationError) as exc:
        Settings(_env_file=None)
    assert {error["loc"][0] for error in exc.value.errors()} >= {"database_url", "supabase_url"}


def test_settings_hide_database_credentials(settings):
    assert settings.database_url.get_secret_value() not in repr(settings)


def test_cors_does_not_allow_arbitrary_origins(client):
    response = client.options(
        "/health",
        headers={"Origin": "https://untrusted.example", "Access-Control-Request-Method": "GET"},
    )
    assert "Access-Control-Allow-Origin" not in response.headers
